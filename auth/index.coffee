_ = require 'underscore'
bcrypt = require 'bcrypt'
jwt = require 'jsonwebtoken'

models = require '../models'
config = require '../config'

vaidJwtFields = ['id', 'traits']

module.exports =
    hashPassword: (password) ->
        salt = bcrypt.genSaltSync 10
        bcrypt.hashSync password, salt

    checkPassword: (user, passwordToTest) ->
        bcrypt.compareSync passwordToTest, user.password

    authRequired: (req, res, next) ->
        currentUserID = req.user?.id

        unless currentUserID
            return res.status(401).json {error: 'Authentication required'}

        next()

    currentUserRequired: (req, res, next) ->
        idealUserID = req.param 'userID'
        currentUserID = req.user?.id

        unless currentUserID
            return res.status(401).json {error: 'Authentication required'}

        if idealUserID is currentUserID
            next()
        else
            res.status(403).json {error: 'Forbidden from accessing this resource'}

    createToken: (user) ->
        user = _.pick user, vaidJwtFields
        token = jwt.sign user, config.SECRET, { expiresInMinutes: config.SESSION_DURATION }
