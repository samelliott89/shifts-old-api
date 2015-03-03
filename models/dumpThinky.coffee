config = require '../config'
thinky = require 'thinky'

db = thinky
    host: config.RETHINKDB_DUMP_HOST
    port: config.RETHINKDB_DUMP_PORT
    db:   config.RETHINKDB_DUMP_DB

module.exports = db