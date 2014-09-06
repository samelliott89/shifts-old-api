passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

models = require '../models'

passport.use new LocalStrategy (email, password, done) ->
    models.getUser email
        .then (user) ->
            if models.validatePassword user, password
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

module.exports = passport