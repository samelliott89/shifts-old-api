models = require '../models'
_errs = require '../errors'

exports.getFriends = (req, res, next) ->
    userID = req.param 'userID'
    models.getFriends userID
        .then (friends) ->
            res.json {friends}
        .catch (err) -> _errs.handleRethinkErrors err, next

exports.addFriend = (req, res, next) ->
    req.checkBody('friend', 'Friend must be valid user ID').isUUID()
    _errs.handleValidationErrors {req}

    requesterUserID = req.param 'userID'
    futureFriendID = req.body.friend
    previousStatus = models.FRIENDSHIP_NONE

    models.getFriendshipStatus requesterUserID, futureFriendID
        .then (friendStatus) ->
            previousStatus = friendStatus

            switch friendStatus
                when models.FRIENDSHIP_MUTUAL, models.FRIENDSHIP_USER2_TO_ACCEPT then return true

            newFriendship = new models.Friendship {
                userID: requesterUserID
                friendID: futureFriendID
            }
            newFriendship.save()

        .then (result) ->
            switch previousStatus
                when models.FRIENDSHIP_NONE, models.FRIENDSHIP_USER2_TO_ACCEPT
                    statusToReturn = 'FRIENDSHIP_USER2_TO_ACCEPT'
                when models.FRIENDSHIP_MUTUAL, models.FRIENDSHIP_USER1_TO_ACCEPT
                    statusToReturn = 'FRIENDSHIP_MUTUAL'

            res.json {status: statusToReturn}

        .catch (err) ->
            _errs.handleRethinkErrors err, next