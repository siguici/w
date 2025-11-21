module w

import os
import veb { RunParams }
import siguici.vite
import siguici.envig

pub const vite = vite.new()
pub const config = envig.new()

@[params]
pub struct AppParams {
pub mut:
	secret_key string
}

pub struct App {
	veb.StaticHandler
pub:
	secret_key string
}

pub fn new_app(params AppParams) &App {
	mut app := &App{
		secret_key: params.secret_key
	}
	return app
}

@[inline]
pub fn make_app[A]() A {
	mut params := AppParams{}
	mut app := A{
		secret_key: params.secret_key
	}

	return app
}

@[inline]
fn handle_app[A](mut app A) ! {
	if os.exists('public') {
		if os.exists('public/static') {
			app.handle_static('public/static', true)!
		} else {
			app.handle_static('public', true)!
		}
	}

	if os.exists('static') {
		app.handle_static('static', true)!
	}
}

pub fn run[A, X](port int) ! {
	mut app := make_app[A]()

	run_app[A, X](mut app, port)!
}

pub fn run_at[A, X](params RunParams) ! {
	mut app := make_app[A]()

	run_app_at[A, X](mut app, params)!
}

pub fn run_app[A, X](mut app A, port int) ! {
	handle_app[A](mut app)!

	veb.run[A, X](mut app, port)
}

pub fn run_app_at[A, X](mut app A, params RunParams) ! {
	handle_app[A](mut app)!

	veb.run_at[A, X](mut app, params)
}
