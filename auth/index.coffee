bcrypt = require 'bcrypt'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

models = require '../models'

localConfig =
    usernameField: 'email'

passport.use new LocalStrategy localConfig, (email, password, done) ->
    models.getUser email, {includePassword: true}
        .then (user) ->
            if exports.checkPassword user, password
                return done null, user
            else
                return done null, false, {message: 'Incorrect password'}
        .catch (err) ->
            if helpers.notFound err
                return done null, false, {message: 'Incorrect email'}
            else
                return done err

passport.serializeUser (user, done) ->
    done null, user.id

passport.deserializeUser (userId, done) ->
    models.getUser userId
        .then (user) -> done null, user
        .catch done # If there's an error, done will be called with err as the first arg

exports.passport = passport

exports.hashPassword = (password) ->
    salt = bcrypt.genSaltSync 10
    bcrypt.hashSync password, salt

exports.checkPassword = (user, passwordToTest) ->
    bcrypt.compareSync passwordToTest, user.password