models = require '../models'
_errs = require '../errors'

exports.getFriends = (req, res, next) ->
    userID = req.param 'userID'
    models.getFriends userID
        .then (friends) ->
            res.json {friends}
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
                when models.FRIENDSHIP_STATUS.MUTUAL, models.FRIENDSHIP_STATUS.USER1_TO_ACCEPT
                    statusToReturn = 'MUTUAL'

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
            res.status(204).end()
        .catch (err) ->
            _errs.handleRethinkErrors err, next