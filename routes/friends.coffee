models = require '../models'

exports.addFriend = (req, res, next) ->
    requesterUserID = req.user.id
    futureFriendID = req.param 'userID'

