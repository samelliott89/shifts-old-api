cors             = require 'cors'
morgan           = require 'morgan'
express          = require 'express'
bodyParser       = require 'body-parser'
cookieParser     = require 'cookie-parser'
responseTime     = require 'response-time'
expressValidator = require 'express-validator'

config           = require './config'
routes           = require './routes'
sessions         = require './sessions'
customValidators = require './validators'

app = express()

app.use (req, res, next) ->
    console.log 'Incomming request:', req.path
    next()

app.use responseTime()
app.use cors()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json()
app.use expressValidator {customValidators}

# Hide all session-creation/auth logic within here.
# If redis isnt avail, will fall back to memory-based sessions
sessions app

# Guard against invalid JSON errors
app.use (err, req, res, next) ->
    if err instanceof SyntaxError
        return res.status(400).json {error: 'Invalid JSON'}
    else
        next()

# No routes or middlewares to be defined before or after this
routes app

port = Number config.PORT
app.listen port, ->
    console.log "\n###\n## Running on port #{port}\n###\n"