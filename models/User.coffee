# Shitty way to get around circular requires
module.exports = {helpers: {}}

crypto = require 'crypto'
bluebird = Promise = require 'bluebird'
_ = require 'underscore'

auth = require '../auth'

friendshipHelpers = require('./Friendship').helpers
thinky = require './thinky'
_errs = require '../errors'
r = thinky.r

# TO DO: Move 'phone' into a new list that can only be viewed by mutual connections
safeUserFields = ['bio', 'displayName', 'id', 'profilePhoto', 'defaultPhoto', 'phone']
safeOwnUserFields = safeUserFields.concat ['email', 'traits', 'created', 'defaultDisplayNameSet', 'phone']
adminUserFeilds = safeOwnUserFields.concat ['pwResetToken']

cleanUser = (user, req, opts = {}) ->
    if (req?.user?.traits?.admin)
        fields = adminUserFeilds
    else if (req?.user?.id is user.id) or (opts.includeOwnUserFields)
        fields = safeOwnUserFields
    else
        fields = safeUserFields

    unless user.profilePhoto
        photoHash = crypto.createHash('md5').update(user.id).digest('hex')
        user.defaultPhoto = "https://www.gravatar.com/avatar/#{photoHash}?default=retro"

    _.pick user, fields

User = thinky.createModel 'User',
    id:           String
    bio:          String
    displayName:  String
    email:        String
    phone:        String
    password:     String
    traits:       Object
    created:      Date
    pwResetToken: String
    profilePhoto: {
        type:     String
        id:       String
        href:     String
    }

User.ensureIndex 'email'
User.define 'clean', (req, opts = {}) -> cleanUser this, req, opts

User.define 'setPassword', (newPassword) ->
    @password = auth.hashPassword newPassword

module.exports.model = User

# Getting a user via this helper is recommended because it will strip
# sensitive data, like passwords, by default
getUser = (key, opts={}) -> new Promise (resolve, reject) ->
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
                return reject new _errs.NotFound()

            if opts.clean and opts.req
                user = user.clean opts.req

            unless typeof friendshipStatus is undefined
                user.isFriend = friendshipStatus is friendshipHelpers.FRIENDSHIP_STATUS.MUTUAL
                user.friendshipStatus = friendshipHelpers.mapFriendStatus friendshipStatus

            resolve user
        .catch reject

getAllUsersByEmails = (emails) -> new Promise (resolve, reject) ->

    # Package emails for rethink
    r.expr(emails)

        # And join them to the User table by using the 'email' inde
        .eqJoin(((email) -> email), r.table('User'), {index: 'email'})

        # Remove any duplicates
        .distinct()

        # And get only the users and execute
        .map (row) -> row('right')
        .run()

        # Clean users up and then return
        .then (foundUsers) ->
            cleanedUsers = _.map foundUsers, (user) -> cleanUser user
            resolve cleanedUsers
        .catch reject

extendAuthedUser = (req, res, next) ->
    User.get req.user.id
        .run()
        .then (user) ->
            _.extend req.user, user
            next()
        .catch next

# Shitty way to get around circular requires
_.extend module.exports.helpers, {
    extendAuthedUser,
    cleanUser,
    getUser,
    getAllUsersByEmails
}
