_ = require 'underscore'
jwt = require 'jsonwebtoken'
bcrypt = require 'bcrypt'

models = require '../models'
config = require '../config'
_errs = require '../errors'

vaidJwtFields = ['id', 'traits']

module.exports =
    hashPassword: (password) ->
        salt = bcrypt.genSaltSync 10
        bcrypt.hashSync password, salt

    checkPassword: (user, passwordToTest) ->
        bcrypt.compareSync passwordToTest, user.password

    authRequired: (req, res, next) ->
        unless req.isAuthenticated
            return next new _errs.AuthRequired()

        next()

    currentUserRequired: (req, res, next) ->
        unless req.isAuthenticated
            return next new _errs.AuthRequired()

        if req.param('userID') is req.user.id
            next()
        else
            return next new _errs.InvalidPermissions()

    createToken: (user) ->
        user = _.pick user, vaidJwtFields
        token = jwt.sign user, config.SECRET, { expiresInMinutes: config.SESSION_DURATION }
