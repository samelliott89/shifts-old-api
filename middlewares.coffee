_errs  = require './errors'

exports.isAuthed = (req, res, next) ->
    req.isAuthenticated = !!req.user
    console.log 'req.isAuthenticated:', req.isAuthenticated
    next()

exports.errorHandler = (originalError, req, res, next) ->
    if originalError.status and originalError.name
        error = originalError
    else
        # todo: log error better!
        console.log 'Unexpected error:', originalError.toString()
        console.log originalError.stack
        error = new _errs.ServerError()

    res.status(error.status).json {
        error: error.name
        message: error.message
        details: error.details
    }