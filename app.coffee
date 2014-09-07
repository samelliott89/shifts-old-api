morgan       = require 'morgan'
express      = require 'express'
session      = require 'express-session'
bodyParser   = require 'body-parser'
cookieParser = require 'cookie-parser'
responseTime = require 'response-time'
validator    = require 'express-validator'

routes = require './routes'
auth   = require './auth'

app = express()
app.use responseTime()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json()
app.use validator()
app.use session
    secret: process.env.API_SECRET or 'insecure secret'
    saveUninitialized: true
    resave: true

app.use auth.passport.initialize()
app.use auth.passport.session()

# No routes or middlewares to be defined before this
routes app

port = Number process.env.API_PORT or 5012
console.log "Going to run on port #{port}"
app.listen port, -> console.log "Listening on port #{port}"