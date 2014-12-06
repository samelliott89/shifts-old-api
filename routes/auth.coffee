_ = require 'underscore'
jwt = require 'jsonwebtoken'

auth = require '../auth'
_errs = require '../errors'
models = require '../models'
config = require '../config'

validRegistrationFields = ['email', 'password', 'displayName', 'profilePhoto']

exports.register = (req, res, next) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)
    _errs.handleValidationErrors {req}

    # Only include whitelisted fields
    userFields = _.pick req.body, validRegistrationFields
    userFields.password = auth.hashPassword userFields.password

    models.getUser userFields.email, {includePassword: true}
        .then ->
            next new _errs.ValidationFailed {email:msg: 'The supplied email address is already taken'}

        .catch (err) ->
            unless models.helpers.notFound err
                _errs.handleRethinkErrors err, next

            newUser = new models.User userFields
            newUser.traits = { protoUser: true }

            newUser.saveAll()
                .then (user) ->
                    token = auth.createToken user
                    res.json {user, token}
                .catch _errs.handleRethinkErrors err

exports.login = (req, res, next) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)
    _errs.handleValidationErrors {req}

    models.getUser req.body.email, {includePassword: true}
        .then (user) ->
            if auth.checkPassword user, req.body.password
                token = auth.createToken user
                res.json {user, token}
            else
                next new _errs.AuthFailed {password:msg: {'Password is incorrect'}}

        .catch (err) ->
            if models.helpers.notFound err
                next new _errs.AuthFailed {email:msg: {'Email is incorrect'}}
            else
                _errs.handleRethinkErrors err

    # auth.passport.authenticate('local', authCallback)(req, res, next)

exports.logout = (req, res) ->
    req.logout()
    res.clearCookie 'userInfo'
    res.json {'message': 'Successully logged out'}
