cors             = require 'cors'
morgan           = require 'morgan'
express          = require 'express'
expressJwt       = require 'express-jwt'
bodyParser       = require 'body-parser'
cookieParser     = require 'cookie-parser'
responseTime     = require 'response-time'
expressValidator = require 'express-validator'
expHandlebars    = require 'express-handlebars'

config           = require './config'
routes           = require './routes'
middlewares      = require './middlewares'
customValidators = require './validators'

app = express()

app.engine 'hbs', expHandlebars({defaultLayout: 'main'})
app.set 'view engine', 'hbs'

# app.use bugsnag.requestHandler
app.use responseTime()
app.use cors()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json({limit: '8mb'})
app.use expressValidator {customValidators}

# Setup auth
app.use expressJwt
    secret: config.SECRET
    credentialsRequired: false
app.use middlewares.isAuthed

routes app

app.use middlewares.errorHandler

port = Number config.PORT
server = app.listen port, ->
    {address, port} = server.address()
    console.log "\n### Shifts API listening at http://#{address}:#{port}"