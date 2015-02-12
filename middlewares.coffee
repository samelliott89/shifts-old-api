_ = require 'underscore'
jwt     = require 'jsonwebtoken'
bugsnag = require 'bugsnag'

_errs  = require './errors'
config  = require './config'
thinky = require './models/thinky'
rethinkDBErrors = thinky.Errors

releaseStage = config.NODE_ENV or 'dev'
if releaseStage.toLowerCase() is 'prod'
    releaseStage = 'Production'

console.log 'releaseStage is ' + releaseStage
bugsnag.register 'bb98dd9f26cdc21068ca92133cde0ee1', {releaseStage}

sendError = ->
    unless releaseStage is 'dev'
        bugsnag.notify arguments...

exports.isAuthed = (req, res, next) ->
    req.isAuthenticated = !!req.user
    next()

exports.errorHandler = (originalError, req, res, next) ->
    bugsnagOptions = {
        userId: req.user?.id or req.ip
        metaData: {
            url: req.originalUrl
        }
    }

    if originalError.status and originalError.name
        error = originalError

    else if originalError instanceof rethinkDBErrors.DocumentNotFound
        error = new _errs.NotFound()
        sendError(originalError, _.extend({severity: 'info'}, bugsnagOptions))

    else if originalError instanceof jwt.TokenExpiredError
        error = new _errs.AuthFailed 'Auth token has expired'
        sendError originalError, bugsnagOptions

    else if originalError instanceof jwt.JsonWebTokenError or originalError.code is 'MISSING_HEADER'
        error = new _errs.ServerError 'Error verifying auth token'
        sendError originalError, bugsnagOptions

    else
        console.log 'UNEXPECTED ERROR:'
        console.log originalError.stack or originalError
        sendError(originalError, _.extend({severity: 'error'}, bugsnagOptions))
        error = new _errs.ServerError()

    res.status(error.status).json {
        error: error.name
        message: error.message
        details: error.details
    }