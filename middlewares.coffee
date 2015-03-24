_ = require 'underscore'
jwt     = require 'jsonwebtoken'
bugsnag = require 'bugsnag'

_errs  = require './errors'
config  = require './config'
thinky = require './models/thinky'
rethinkDBErrors = thinky.Errors

exports.isAuthed = (req, res, next) ->
    req.isAuthenticated = !!req.user
    next()

exports.robbyTools = (req, res, next) ->
    # Require 'x-robby-tools' header for using admin permissions
    if req.user?.traits?.admin and not req.headers['x-robby-tools']
        delete req.user.traits.admin

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
        _errs.sendError(originalError, _.extend({severity: 'info'}, bugsnagOptions))

    else if originalError instanceof jwt.TokenExpiredError
        error = new _errs.AuthFailed 'Auth token has expired'
        _errs.sendError originalError, bugsnagOptions

    else if originalError instanceof jwt.JsonWebTokenError or originalError.code is 'MISSING_HEADER'
        error = new _errs.ServerError 'Error verifying auth token'
        _errs.sendError originalError, bugsnagOptions

    else
        console.log 'UNEXPECTED ERROR:'
        console.log originalError.stack or originalError
        _errs.sendError(originalError, _.extend({severity: 'error'}, bugsnagOptions))
        error = new _errs.ServerError()

    res.status(error.status).json {
        error: error.name
        message: error.message
        details: error.details
    }