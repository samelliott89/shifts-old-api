cors             = require 'cors'
morgan           = require 'morgan'
express          = require 'express'
bugsnag          = require 'bugsnag'
expressJwt       = require 'express-jwt'
bodyParser       = require 'body-parser'
cookieParser     = require 'cookie-parser'
responseTime     = require 'response-time'
expressValidator = require 'express-validator'

config           = require './config'
routes           = require './routes'
middlewares      = require './middlewares'
customValidators = require './validators'

# bugsnag.register 'f443a1d6e5c1382943e7a87859659a4a'

app = express()

# app.use bugsnag.requestHandler
app.use responseTime()
app.use cors()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json()
app.use expressValidator {customValidators}

# Setup auth
app.use expressJwt
    secret: config.SECRET
    credentialsRequired: false
app.use middlewares.isAuthed

routes app

app.use middlewares.errorHandler

# TODO: evaluate how we use bugsnag properly
# app.use bugsnag.errorHandler

port = Number config.PORT
app.listen port, ->
    console.log "\n### Started ShiftsAPI on port #{port}"
