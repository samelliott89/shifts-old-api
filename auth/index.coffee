module.exports = {}

_ = require 'underscore'
jwt = require 'jsonwebtoken'
bcrypt = require 'bcrypt-nodejs'

models = require '../models'
config = require '../config'
_errs = require '../errors'

vaidJwtFields = ['id', 'traits']

module.exports.hashPassword = (password) ->
    salt = bcrypt.genSaltSync 10
    bcrypt.hashSync password, salt

module.exports.checkPassword = (user, passwordToTest) ->
    bcrypt.compareSync passwordToTest, user.password

module.exports.authRequired = (req, res, next) ->
    unless req.isAuthenticated
        return next new _errs.AuthRequired()

    next()

module.exports.currentUserRequired = (req, res, next) ->
    unless req.isAuthenticated
        return next new _errs.AuthRequired()

    if req.param('userID') is req.user.id
        next()
    else
        return next new _errs.InvalidPermissions()

module.exports.hasTrait = ->
    permissions = null

    _testUserForPermissions = (user, permissions) ->
        for perm in permissions
            if user.traits?[perm]
                return true

        return false

    _middleware = (req, res, next) ->
        unless req.isAuthenticated
            return next new _errs.AuthRequired()

        if _testUserForPermissions req.user, permissions
            return next()

        return next new _errs.InvalidPermissions()

    ##
    # Logic
    ##
    if typeof arguments[0] is 'string'
        # This is being used as a middleware
        permissions = arguments
        return _middleware

    else if typeof arguments[0] is 'object'
        # This is being used as a standalone function,
        # with a user and permissions being passed in
        [user, permissions...] = arguments
        return _testUserForPermissions user, permissions

    throw new Error 'Invalid parameters passed'

module.exports.createToken = (user) ->
    user = _.pick user, vaidJwtFields
    jwt.sign user, config.SECRET, { expiresInMinutes: config.SESSION_DURATION }
