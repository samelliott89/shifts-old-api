morgan           = require 'morgan'
express          = require 'express'
session          = require 'express-session'
bodyParser       = require 'body-parser'
cookieParser     = require 'cookie-parser'
responseTime     = require 'response-time'
expressValidator = require 'express-validator'

auth   = require './auth'
routes = require './routes'
customValidators = require './validators'

app = express()
app.use responseTime()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json()
app.use expressValidator {customValidators}
app.use session
    secret: process.env.API_SECRET or 'insecure secret'
    saveUninitialized: true
    resave: true

# Guard against invalid JSON errors
app.use (err, req, res, next) ->
    if err instanceof SyntaxError
        return res.status(400).json {error: 'Invalid JSON'}
    else
        next()

app.use auth.passport.initialize()
app.use auth.passport.session()

# No routes or middlewares to be defined before this
routes app

port = Number process.env.API_PORT or 5012
console.log "Going to run on port #{port}"
app.listen port, -> console.log "Listening on port #{port}"