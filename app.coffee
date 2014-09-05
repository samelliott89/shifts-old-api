express = require 'express'
bodyParser = require 'body-parser'

routes = require './routes'

app = express()
app.use bodyParser.json()

# No routes or middlewares to be defined before this
routes app

port = Number process.env.API_PORT or 5012
console.log "Going to run on port #{port}"
app.listen port, -> console.log "Listening on port #{port}"