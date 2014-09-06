morgan       = require 'morgan'
express      = require 'express'
session      = require 'express-session'
bodyParser   = require 'body-parser'
cookieParser = require 'cookie-parser'
responseTime = require 'response-time'

routes       = require './routes'
passport     = require './auth'

app = express()
app.use responseTime()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json()
app.use session
    secret: process.env.API_SECRET or 'insecure secret'
    saveUninitialized: true
    resave: true

app.use passport.initialize()
app.use passport.session()

# No routes or middlewares to be defined before this
routes app

port = Number process.env.API_PORT or 5012
console.log "Going to run on port #{port}"
app.listen port, -> console.log "Listening on port #{port}"