_ = require 'underscore'

models  = require '../models'

exports.getUser = (req, res, next) ->
    console.log 'req.user:'
    console.log req.user

    userID = req.param 'userID'
    models.getUser userID
        .then (user) -> res.json {user}
        .catch next

exports.editUser = (req, res, next) ->
    req.checkBody('email', 'Valid email required').isEmail() if req.body.email
    req.checkBody('password', 'Password of minimum 8 characters required').isLength(8) if req.body.password

    errors = req.validationErrors(true)
    return res.status(400).json {errors}  if errors

    userID = req.param 'userID'

    allowedFields = ['email', 'displayName']

    models.getUser userID
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
    console.log 'req.user:'
    console.log req.user

    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated()
        user: req.user