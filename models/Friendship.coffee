# Shitty way to get around circular requires
module.exports = {helpers: {}}

bluebird = Promise = require 'bluebird'
_ = require 'underscore'

thinky = require './thinky'
r = thinky.r
userHelpers = require('./User').helpers

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

Friendship.ensureIndex 'userID'
Friendship.ensureIndex 'friendID'

# Create a compound index that looks like 'userIDfriendID' (rather than [userID, friendID])
Friendship.ensureIndex 'UserToFriend', (doc) ->
    doc('userID').add(doc('friendID'))

exports.model = Friendship

NONE = 0
MUTUAL = 1
USER2_TO_ACCEPT = -1
USER1_TO_ACCEPT = -2

status = FRIENDSHIP_STATUS = {
    NONE
    MUTUAL
    USER2_TO_ACCEPT
    USER1_TO_ACCEPT
}

_evaluateFriendship = ([[rel1], [rel2]]) ->
    new Promise (resolve) ->
        if rel1 and rel2
            resolve status.MUTUAL
        else if rel1 and not rel2
            resolve status.USER2_TO_ACCEPT
        else if not rel1 and rel2
            resolve status.USER1_TO_ACCEPT
        else
            resolve status.NONE

mapFriendStatus = (status) ->
    _.invert(FRIENDSHIP_STATUS)[status]

getFriendshipStatus = (user1, user2) ->
    promises = [
        Friendship.getAll(user1 + user2, {index: 'UserToFriend'}).run()
        Friendship.getAll(user2 + user1, {index: 'UserToFriend'}).run()
    ]

    bluebird.all promises
        .then _evaluateFriendship

getFriends = (userID) ->
    userAsFriend = r.table('Friendship')
        .filter {friendID: userID}
        .map (row) -> row 'userID'
        .coerceTo 'array'

    promise = Friendship
        # First, create a list one direction of relationships
        .filter {userID: userID}
        .map (row) -> row 'friendID'
        .coerceTo 'array'

        # Then create a list the other way around and find the intersection of both
        # This intersection is all the friends userID has
        .setIntersection userAsFriend

        # 'Join' to the User tables and execute
        .map (friendID) -> r.table('User').get friendID
        .execute()

    # Resolve with an array of friends, with cleaned data
    new Promise (resolve, reject) ->
        promise.then (cursor) ->
            cursor.toArray (err, friends) ->
                return reject err  if err
                resolve _.map friends, userHelpers.cleanUser

        promise.catch reject

deleteFriendship = (user1, user2) ->
    promises = [
        Friendship.getAll(user1 + user2, {index: 'UserToFriend'}).delete().run()
        Friendship.getAll(user2 + user1, {index: 'UserToFriend'}).delete().run()
    ]

    bluebird.all promises

# Shitty way to get around circular requires
_.extend module.exports.helpers, {
    getFriendshipStatus
    getFriends
    deleteFriendship
    mapFriendStatus
    FRIENDSHIP_STATUS
}