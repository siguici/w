module w

import rand
import toml { Any }
import db.pg
import crypto.aes
import crypto.cipher
import net.urllib
import encoding.base64
import json
import time

interface SessionRepository {
	get(key string, default Any)
	set(key string, value Any)
	has(key string) bool
	exists(key string) bool
	push(key string, value Any)
	pull(key string, default Any) Any
	all() map[string]any
	forget(keys ...string)
	flush()
	invalidate()
	flash(key string, value Any)
	reflash()
	keep(keys ...string)
}

@[table: 'sessions']
pub struct Session {
	user_id    ?string @[sql_type: 'char(26)']
	ip_address ?string @[sql_type: 'char(45)']
	user_agent ?string @[sql_type: 'varchar(255)']
mut:
	id            string @[primary; sql_type: 'varchar(40)']
	payload       string @[sql_type: 'longtext']
	last_activity int
	data          map[string]Any @[skip]
	flashed       map[string]Any @[skip]
	old_flashes   map[string]Any @[skip]
}

struct SessionCookie {
	iv    string
	value string
	mac   string
	tag   string
}

pub struct SessionManager {
mut:
	db      pg.DB
	ttl     int = 120
	storage map[string]Session
}

pub fn new_session_manager(db pg.DB, ttl int) SessionManager {
	return SessionManager{
		db:      db
		ttl:     ttl
		storage: map[string]Session{}
	}
}

pub fn (mut s Session) get(key string, default Any) Any {
	return s.data[key] or { default }
}

pub fn (mut s Session) set(key string, value Any) {
	s.data[key] = value
	s.touch()
}

pub fn (s Session) has(key string) bool {
	// TODO: Check if key exists and is not empty
	/*
	val := s.data[key] or { return false }
	match val {
		string { return val.len > 0 }
		map[string]any, []any { return true }
		else { return val != none }
	}
	*/
	return if _ := s.data[key] { true } else { false }
}

pub fn (s Session) exists(key string) bool {
	return key in s.data
}

pub fn (mut s Session) push(key string, value Any) {
	mut existing := s.data[key] or { Any{} }
	mut arr := []Any{}
	match existing {
		[]Any {
			arr = [existing]
		}
		else {
			arr = []Any{cap: 1}
			arr << existing
		}
	}
	arr << value
	s.data[key] = arr
	s.touch()
}

pub fn (mut s Session) pull(key string, default Any) Any {
	val := s.data[key] or { default }
	s.forget(key)
	return val
}

pub fn (mut s Session) forget(keys ...string) {
	for key in keys {
		s.data.delete(key)
	}
	s.touch()
}

pub fn (mut s Session) flush() {
	s.data.clear()
	s.flashed.clear()
	s.old_flashes.clear()
	s.touch()
}

pub fn (s Session) all() map[string]Any {
	return s.data.clone()
}

pub fn (mut s Session) flash(key string, value Any) {
	s.flashed[key] = value
	s.set('_flash.new', any_from_strings(s.flashed.keys()))
}

pub fn (mut s Session) reflash() {
	s.keep(...s.old_flashes.keys())
}

pub fn (mut s Session) keep(keys ...string) {
	for key in keys {
		if old := s.old_flashes[key] {
			s.flashed[key] = old
		}
	}
	s.set('_flash.new', any_from_strings(keys))
}

pub fn (mut s Session) invalidate() {
	s.flush()
	s.last_activity = 0
}

fn (mut s Session) touch() {
	s.last_activity = int(time.now().unix())
}

pub fn (mut sm SessionManager) from_cookie(cookie string, app_key string) !Session {
	session := get_session_from_cookie(sm.db, cookie, app_key)!
	if sm.is_valid(session) {
		sm.storage[session.id] = session
		return session
	}
	return error('Session expired or invalid')
}

pub fn (sm SessionManager) is_valid(session Session) bool {
	return time.now().unix() - session.last_activity < sm.ttl * 60
}

pub fn (sm SessionManager) user(session Session) ?string {
	return session.user_id
}

pub fn (mut sm SessionManager) regenerate(session &Session) !string {
	new_id := rand.string(40)
	mut new_session := *session
	new_session.id = new_id
	new_session.last_activity = int(time.now().unix())
	sm.store(new_session)
	return new_id
}

pub fn get_session_from_cookie(db pg.DB, cookie string, app_key string) !Session {
	session_info := decrypt_laravel_cookie(app_key, cookie) or {
		return error('Error on decrypt cookie: ${err}')
	}
	session_id := session_info.split('|')[1]

	result := sql db {
		select from Session where id == session_id limit 1
	}!

	return result.first()
}

pub fn (mut sm SessionManager) store(session Session) {
	sm.storage[session.id] = session
}

pub fn (sm SessionManager) get(session_id string) !Session {
	session := sm.storage[session_id] or { return error('Session not found in memory') }
	if !sm.is_valid(session) {
		return error('Session expired')
	}
	return session
}

pub fn decrypt_laravel_cookie(app_key string, cookie string) !string {
	raw := base64.decode_str(urllib.query_unescape(cookie)!)
	key := base64.decode(app_key.replace('base64:', ''))
	data := json.decode(SessionCookie, raw)!
	iv := base64.decode(data.iv)
	value := base64.decode(data.value)

	block := aes.new_cipher(key)
	mut cbc := cipher.new_cbc(block, iv)
	mut dst := []u8{len: value.len}
	cbc.decrypt_blocks(mut dst, value)

	return dst.bytestr().trim_space().trim_right('\x0F')
}

fn any_from_strings(strings []string) []Any {
	mut arr := []Any{}
	for s in strings {
		arr << s
	}
	return arr
}
