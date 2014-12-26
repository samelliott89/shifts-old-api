bluebird = Promise = require 'bluebird'

thinky = require './thinky'
User = require './User'

# See http://stackoverflow.com/a/2911606/2592 for an explanation of what's going on.
# In short, when user1 requests friends with user2, a record is created:
#   {user: 'user1', 'friend': 'user2'}
# The absense of an inverse record indicates the friendship hasnt been accepted.
# If user2 rehects the request, delete the first record.
# When user2 accepts user1's request, another record is created:
#   {user: 'user2', 'friend': 'user1'}
# Once accepted, if either user ends the friendship, delete both records.

# So, a full and successful friendship is represented by two complimentary records:
#   {user: 'user1', 'friend': 'user2'}
#   {user: 'user2', 'friend': 'user1'}

Friendship = thinky.createModel 'Friendship',
    userID:   String
    friendID: String

Friendship.ensureIndex 'UserToFriend', (doc) ->
    doc('userID').add(doc('friendID'))

Friendship.ensureIndex 'FriendToUser', (doc) ->
    doc('friendID').add(doc('userID'))

# I don't thinky we actually need joins/relationships here
# Friendship.belongsTo User.model, 'user', 'userID', 'id'
# Friendship.belongsTo User.model, 'friend', 'friendID', 'id'

exports.model = Friendship

FRIENDSHIP_MUTUAL = 1
FRIENDSHIP_NONE = 0
FRIENDSHIP_USER2_TO_ACCEPT = -1
FRIENDSHIP_USER1_TO_ACCEPT = -2

_evaluateFriendship = ([[rel1], [rel2]]) ->
    new Promise (resolve) ->
        if rel1 and rel2
            resolve FRIENDSHIP_MUTUAL
        else if rel1 and not rel2
            resolve FRIENDSHIP_USER2_TO_ACCEPT
        else if not rel1 and rel2
            resolve FRIENDSHIP_USER1_TO_ACCEPT
        else
            resolve FRIENDSHIP_NONE

getFriendshipStatus = (user1, user2) ->
    promises = [
        Friendship.getAll(user1 + user2, {index: 'UserToFriend'}).run()
        Friendship.getAll(user2 + user1, {index: 'UserToFriend'}).run()
    ]

    bluebird.all promises
        .then _evaluateFriendship

exports.helpers = {
    getFriendshipStatus
    FRIENDSHIP_MUTUAL
    FRIENDSHIP_NONE
    FRIENDSHIP_USER2_TO_ACCEPT
    FRIENDSHIP_USER1_TO_ACCEPT
}