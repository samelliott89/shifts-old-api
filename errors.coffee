_ = require 'underscore'

class HttpError extends Error
    constructor: (arg1, arg2) ->

        if _.isObject arg1
            # Assume first argument is details object
            @details = arg1
        else
            # else, assume it's [message, details]
            @message = arg1 if arg1
            @details = arg2 if arg2

class ValidationFailed extends HttpError
    name: 'ValidationFailed'
    message: 'The data supplied failed validation'
    status: 400

class AuthFailed extends HttpError
    name: 'AuthFailed'
    message: 'Failed to authenticate with supplied credentials'
    status: 400

class AuthRequired extends HttpError
    name: 'AuthRequired'
    message: 'Authentication header is requried to access this resource'
    status: 401

class InvalidPermissions extends HttpError
    name: 'InvalidPermissions'
    message: 'Authentication provided invalid permissions to access this resource'
    status: 403

class NotFound extends HttpError
    name: 'NotFound'
    message: 'The requested resource does not exist'
    status: 404

class ServerError extends HttpError
    name: 'ServerError'
    message: 'Unexpected server error occured while processing the request'
    status: 500

exports.ValidationFailed = ValidationFailed
exports.AuthFailed = AuthFailed
exports.AuthRequired = AuthRequired
exports.InvalidPermissions = InvalidPermissions
exports.NotFound = NotFound
exports.ServerError = ServerError

exports.handleValidationErrors = ({req, next}) ->
    errors = req.validationErrors true

    if errors
        err = new ValidationFailed errors
        if next
            next err
        else
            throw err

    return false

exports.handleRethinkErrors = (err, next) ->
    # todo: flesh this out and handle more common errors
    console.log 'RethinkDB threw error:'
    # console.log err
    # console.log err.stack

    # newError = new ServerError()
    if next
        next err
    else
        throw err
