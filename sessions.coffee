redis            = require 'redis'
session          = require 'express-session'
RedisStore       = require('connect-redis')(session)

config = require './config'
auth   = require './auth'

module.exports = (app) ->

    # Attempt to use redis for sessions. If not, fall back to in-memory sessions
    try
        throw 'Redis not configured' unless config.REDIS_PORT and config.REDIS_HOST
        redisClient = redis.createClient config.REDIS_PORT, config.REDIS_HOST
        sessionStore = new RedisStore {client: redisClient}
        console.log 'Connected to redis, using it for sessions'
    catch e
        console.log 'Error connecting to redis:', e
        console.log 'Using memory-based sessions'
        sessionStore = undefined

    app.use session
        store: sessionStore
        secret: config.SECRET
        saveUninitialized: true
        rolling: true
        resave: true
        cookie: {maxAge: 1000 * 60 * 60 * 24 * 30}

    app.use auth.passport.initialize()
    app.use auth.passport.session()