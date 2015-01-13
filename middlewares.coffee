jwt  = require 'jsonwebtoken'

_errs  = require './errors'
thinky = require './models/thinky'
rethinkDBErrors = thinky.Errors


exports.isAuthed = (req, res, next) ->
    req.isAuthenticated = !!req.user
    next()

exports.errorHandler = (originalError, req, res, next) ->
    if originalError.status and originalError.name
        error = originalError
    else if originalError instanceof rethinkDBErrors.DocumentNotFound
        error = new _errs.NotFound()
    else if originalError instanceof jwt.TokenExpiredError
        error = new _errs.AuthFailed 'Auth token has expired'
    else if originalError instanceof jwt.JsonWebTokenError or originalError.code is 'MISSING_HEADER'
        error = new _errs.ServerError 'Error verifying auth token'
    else
        console.log 'UNEXPECTED ERROR:'
        console.log originalError.stack or originalError
        error = new _errs.ServerError()

    res.status(error.status).json {
        error: error.name
        message: error.message
        details: error.details
    }