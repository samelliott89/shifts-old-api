_ = require 'underscore'
Promise = require 'bluebird'

models = require '../../models'
_errs = require '../../errors'


exports.checkContacts = (req, res, next) ->
    req.checkBody('emails', 'Array of emails must be supplied').isArray()
    _errs.handleValidationErrors {req}

    foundUsers = null

    models.getAllUsersByEmails req.body.emails
        .then (_foundUsers) ->
            foundUsers = _foundUsers
            foundUsersIDs = _.map foundUsers, (user) -> user.id
            models.getMultipleFriendshipStatus req.user.id, foundUsersIDs, {friendly: true}
        .then (friendshipData) ->
            for user in foundUsers
                user.friendshipStatus = friendshipData[user.id]

            res.json {users: foundUsers}
        .catch next