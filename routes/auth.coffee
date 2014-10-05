_ = require 'underscore'

models = require '../models'
auth = require '../auth'
helpers = require './helpers'

exports.register = (req, res) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)

    errors = req.validationErrors(true)
    return res.status(400).json {errors}  if errors

    # Only include whitelisted fields
    onlyFields = ['email', 'password', 'displayName', 'profilePhoto']
    userFields = _.pick req.body, onlyFields
    userFields.password = auth.hashPassword userFields.password

    models.getUser userFields.email, {includePassword: true}
        .then ->
            # Email already exists, so return an error
            res.status(400).json {errors: {email: {msg: 'Email already exists'}}}
        .catch (err) ->
            return res.status(500).json {error: 'Unknown error occured'} unless models.helpers.notFound err

            newUser = new models.User userFields

            newUser.saveAll()
                .then (user) -> res.json user
                .catch (err) -> res.status(500).json {error: 'Error creating user', message: err.message}

exports.login = (req, res, next) ->

    console.log '## Received login request...'

    error = (error, status=500) ->
        res.status(status).json {errors: error}

    authCallback = (err, user, info) ->
        if err
            console.log ' ** if err'
            return error err
        unless user
            console.log ' ** unless user'
            console.log info
            return error info, 400

        req.logIn user, (err) ->
            return error err    if err
            userInfo = models.prepareUser req.user
            res.cookie 'userInfo', JSON.stringify userInfo, {maxAge: 30*24*60*60}
            res.json {user: userInfo}

    auth.passport.authenticate('local', authCallback)(req, res, next)

exports.logout = (req, res) ->
    req.logout()
    res.clearCookie 'userInfo'
    res.json {'message': 'Successully logged out'}