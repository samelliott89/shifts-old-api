_                = require 'underscore'
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
analytics = require './analytics'

app = express()

hbs = expHandlebars.create {
    helpers:
        'equal': (lvalue, rvalue, options) ->
            if arguments.length < 3
                throw new Error 'Handlebars Helper equal needs 2 parameters'

            if lvalue != rvalue
                return options.inverse this
            else
                options.fn this
}

app.engine 'hbs', hbs.engine
app.set 'view engine', 'hbs'

app.set 'trust proxy', true
app.use responseTime()
app.use cors()
app.use morgan 'dev'
app.use cookieParser()
app.use bodyParser.json({limit: '8mb'})
app.use expressValidator {customValidators}

# Attach config into locals, so it can be used by templates
_.extend app.locals, config

# Setup auth
app.use expressJwt
    secret: config.SECRET
    credentialsRequired: false
app.use middlewares.isAuthed
app.use middlewares.robbyTools

routes app

app.use middlewares.errorHandler

port = Number config.PORT
server = app.listen port, ->
    {address, port} = server.address()
    console.log "\n### Shifts API listening at http://#{address}:#{port}"
    analytics.track null, 'API Startup'

