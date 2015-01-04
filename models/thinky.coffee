config = require '../config'
thinky = require 'thinky'

db = thinky
    host: config.RETHINKDB_HOST
    port: config.RETHINKDB_PORT
    db:   config.RETHINKDB_DB

module.exports = db