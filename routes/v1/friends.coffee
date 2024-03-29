bluebird = Promise = require 'bluebird'

models = require '../../models'
_errs = require '../../errors'
analytics = require '../../analytics'

# Operations on friends must always happen on your own user object - you never
# access the friends resource of another user.
# Assuming in this example you (the current user) are UserB and the other user
# is UserB
#
# To create a friend request to UserB,
#   POST /api/users/UserA/friends
#        {friend: 'UserB'}
# Which will return the status {status: 'USER2_TO_ACCEPT'} indicating that
# we're waiting for user2 (UserB) to accept the request
#
# If UserB queries the friendship, then they will see the status is
# {status: 'USER1_TO_ACCEPT'}, indicating the current user is able to accept
# the request
#
# For UserB to accept the friendship, they'll create a friendship the other way
# around
#   POST /api/users/UserB/friends
#        {friend: 'UserA'}
# Which will then return the status {status: 'MUTUAL'}, indicating the request
# has been completed and the two users are friends
#
# At any stage, the user can accept or reject the friendship with a DELETE:
#   DELETE /api/users/UserA/friends
#       {friend: 'UserB'}
# This will either reject any pending friendship requests, or if they're
# already friends, end the friendship

exports.getFriends = (req, res, next) ->
    userID = req.param 'userID'

    # models.requireFriendship will reject the promise if they're not mutual friends
    promises = [
        models.getFriends userID
        models.requireFriendship req.user.id, userID
    ]

    bluebird.all promises
        .then ([friends, friendshipStatus]) ->
            res.json {users: friends}
        .catch (err) -> _errs.handleRethinkErrors err, next

exports.createFriendship = (req, res, next) ->
    req.checkBody('friend', 'Friend must be valid user ID').isUUID()
    _errs.handleValidationErrors {req}

    # userID is the current user, who we're creating the relationship on behalf of
    # friendID is the other user
    userID = req.param 'userID'
    friendID = req.body.friend
    previousStatus = models.FRIENDSHIP_STATUS.NONE

    models.getFriendshipStatus userID, friendID
        .then (friendStatus) ->
            previousStatus = friendStatus

            switch friendStatus
                when models.FRIENDSHIP_STATUS.MUTUAL, models.FRIENDSHIP_STATUS.USER2_TO_ACCEPT then return true

            newFriendship = new models.Friendship {
                userID: userID
                friendID: friendID
            }
            newFriendship.save()

        .then (result) ->
            switch previousStatus
                when models.FRIENDSHIP_STATUS.NONE, models.FRIENDSHIP_STATUS.USER2_TO_ACCEPT
                    statusToReturn = 'USER2_TO_ACCEPT'
                    analytics.track req, 'Connection Request', {userID: userID, friendID: friendID}
                when models.FRIENDSHIP_STATUS.MUTUAL, models.FRIENDSHIP_STATUS.USER1_TO_ACCEPT
                    statusToReturn = 'MUTUAL'
                    analytics.track req, 'Connection Establish', {userID: userID, friendID: friendID}

            res.json {status: statusToReturn}

        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.deleteFriendship = (req, res, next) ->
    req.checkQuery('friend', 'Friend must be valid user ID').isUUID()

    # userID is the current user, who we're creating the relationship on behalf of
    # friendID is the other user
    userID = req.param 'userID'
    friendID = req.query.friend

    models.deleteFriendship userID, friendID
        .then ([result1, result2]) ->
            analytics.track req, 'Delete Connection', {userID: userID, friendID: friendID}
            res.json({success: true}).end()
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.getPendingFriendships = (req, res, next) ->
    userID = req.param 'userID'

    models.getPendingFriendships userID
        .then (pendingFriends) ->
            res.json {users: pendingFriends}
        .catch (err) ->
            _errs.handleRethinkErrors err, next