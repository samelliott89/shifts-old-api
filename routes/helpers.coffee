errors = require '../errors'
modelHelpers = require '../models/helpers'

NOT_FOUND    = {error: 'Resource not found'}
INVALID_JSON = {error: 'Invalid JSON'}
SERVER_ERROR = {error: 'Unexpected server error'}
INVALID_PERMISSIONS = {error: 'Invalid permissions'}


# the bad variable names are to ensure this can be registered as an error handler
exports.errorHandler = (_arg1, _arg2, _arg3, _arg4) ->
    [req, res] = [null, null]

    _handler = (err) ->
        if err instanceof SyntaxError
            res.status(400).json INVALID_JSON
        if err instanceof errors.InvalidPermissions
            res.status(403).json INVALID_PERMISSIONS
        else if modelHelpers.notFound err
            res.status(404).json NOT_FOUND
        else
            console.error err.stack
            res.status(500).json SERVER_ERROR

    if arguments.length is 2
        [err, req, res] = arguments
        return _handler
    else
        # assume this is a middleware
        [err, req, res] = arguments
        _handler err