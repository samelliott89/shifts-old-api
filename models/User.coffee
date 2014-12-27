bluebird = Promise = require 'bluebird'
_ = require 'underscore'

friendshipHelpers = require('./Friendship').helpers
thinky = require './thinky'
helpers = require './helpers'

safeUserFields = ['bio', 'displayName', 'id', 'photo']
safeOwnUserFields = safeUserFields.concat ['email']

cleanUser = (user, req) ->
    if req?.user?.id is user.id
        fields = safeOwnUserFields
    else
        fields = safeUserFields

    _.pick user, fields

User = thinky.createModel 'User',
    id:           String
    bio:          String
    displayName:  String
    email:        String
    password:     String
    photo:        String
    traits:       Object

User.ensureIndex 'email'
User.define 'clean', (req) -> cleanUser this, req

exports.model = User

exports.helpers =
    cleanUser: cleanUser

    # Getting a user via this helper is recommended because it will strip
    # sensitive data, like passwords, by default
    getUser: (key, opts={}) -> new Promise (resolve, reject) ->
        promises = []

        if '@' in key
            promises.push User.getAll(key, {index: 'email'}).run()
        else
            promises.push User.get(key).run()

            # Only geting friend status if using ID
            if opts.req?.isAuthenticated
                promises.push(friendshipHelpers.getFriendshipStatus opts.req.user.id, key)

        bluebird.all promises
            .then ([user, friendshipStatus]) ->
                if _.isArray user
                    user = user[0]

                unless user
                    return reject helpers.ERROR_NOT_FOUND

                if opts.clean and opts.req
                    user = user.clean opts.req

                unless typeof friendshipStatus is undefined
                    user.isFriend = friendshipStatus is friendshipHelpers.FRIENDSHIP_STATUS.MUTUAL
                    user.friendshipStatus = friendshipHelpers.mapFriendStatus friendshipStatus

                resolve user
            .catch reject
