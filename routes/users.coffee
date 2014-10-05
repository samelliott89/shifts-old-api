_ = require 'underscore'

models  = require '../models'
helpers = require './helpers'

exports.getUser = (req, res) ->
    userID = req.param 'userID'
    models.getUser userID
        .then (user) -> res.json {user}
        .catch helpers.errorHandler req, res

exports.editUser = (req, res) ->
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
            console.log '\n\nFunctions:'
            console.log Object.keys user
            user.save()
        .then (user) ->
            console.log 'Cool, user saved!', user
            req.json {user}
        .catch (err) ->
            console.log 'Lol, error!'
            console.log err
            res.status(500).json {error: err}

    res.json {page: 'editUser'}

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated()
        user: req.user