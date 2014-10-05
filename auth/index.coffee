bcrypt = require 'bcrypt'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

models = require '../models'

localConfig =
    usernameField: 'email'

passport.use new LocalStrategy localConfig, (email, password, done) ->

    models.getUser email, {includePassword: true}
        .then (user) ->
            if module.exports.checkPassword user, password
                return done null, user
            else
                return done null, false, {password: {msg: 'Incorrect password'}}
        .catch (err) ->
            if models.helpers.notFound err
                return done null, false, {email: {msg: 'Incorrect email'}}
            else
                return done err

passport.serializeUser (user, done) ->
    done null, user.id

passport.deserializeUser (userId, done) ->
    models.getUser userId
        .then (user) -> done null, user
        .catch done # If there's an error, done will be called with err as the first arg

module.exports =
    passport: passport

    hashPassword: (password) ->
        salt = bcrypt.genSaltSync 10
        bcrypt.hashSync password, salt

    checkPassword: (user, passwordToTest) ->
        bcrypt.compareSync passwordToTest, user.password

    currentUserRequired: (req, res, next) ->
        idealUserID = req.param 'userID'
        currentUserID = req.user?.id

        unless currentUserID
            return res.status(401).json {error: 'Authentication required'}

        if idealUserID is currentUserID
            next()
        else
            res.status(403).json {error: 'Forbidden from accessing this resource'}
