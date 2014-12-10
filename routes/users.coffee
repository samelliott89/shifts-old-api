_ = require 'underscore'

models  = require '../models'
_errs = require '../errors'

exports.getUser = (req, res, next) ->
    models.getUser req.param('userID')
        .then (user) ->
            user = user.clean req
            res.json {user}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.editUser = (req, res, next) ->
    req.checkBody('email', 'Valid email required').isEmail() if req.body.email
    req.checkBody('password', 'Password of minimum 8 characters required').isLength(8) if req.body.password
    _errs.handleValidationErrors {req}

    allowedFields = ['email', 'displayName', 'bio']

    models.getUser req.param('userID')
        .then (user) ->
            # Get only the whitelisted fields and set them on the user object
            newUserFields = _.pick req.body, allowedFields
            _.extend user, newUserFields
            user.save()
        .then (user) ->
            req.json {user}
        .catch next

    res.json {page: 'editUser'}

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated
        user: req.user
