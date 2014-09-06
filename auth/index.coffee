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

module.exports = passport