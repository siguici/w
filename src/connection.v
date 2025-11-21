module w

import db.pg
import siguici.envig

pub fn create_connection(config envig.Envig) !pg.DB {
	host := config.get('database.host')
	port := config.get('database.port')
	user := config.get('database.username')
	pass := config.get('database.password')
	name := config.get('database.name')

	mut db := pg.connect(host: host, port: port.int(), user: user, password: pass, dbname: name)!

	return db
}
