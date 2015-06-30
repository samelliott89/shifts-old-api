models = require '../../models'
_ = require 'underscore'
_errs = require '../../errors'
Promise = require 'bluebird'


exports.checkContacts = (req, res, next) ->
    req.checkBody('emails', 'Array of emails must be supplied').isArray()
    _errs.handleValidationErrors {req}

    emails = req.body.emails
    getUsersPromise = models.getAllUsersByEmails emails
    getFriendsPromise = models.getFriends req.user.id, false

    Promise.all [getUsersPromise, getFriendsPromise]
        .then ([users, friendIDs]) ->

            for user in users
                if user.id in friendIDs
                    user.friendshipStatus = 'MUTUAL'
                else
                    user.friendshipStatus = 'NONE'

            res.json {users}
        .catch next