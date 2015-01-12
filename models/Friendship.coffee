# Shitty way to get around circular requires
module.exports = {helpers: {}}

bluebird = Promise = require 'bluebird'
_ = require 'underscore'

_errs = require '../errors'
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

module.exports.model = Friendship

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

requireFriendship = (user1, user2) ->
    getFriendshipStatus user1, user2
        .then (friendship) ->
            unless friendship is status.MUTUAL or user1 is user2
                return Promise.reject new _errs.InvalidPermissions()
            return

getFriends = (userID) ->
    userAsFriend = r.table('Friendship')
        .getAll userID, {index: 'friendID'}
        .map (row) -> row 'userID'
        .coerceTo 'array'

    Friendship
        # First, create a list one direction of relationships
        .getAll userID, {index: 'userID'}
        .map (row) -> row 'friendID'
        .coerceTo 'array'

        # Then create a list the other way around and find the intersection of both
        # This intersection is all the friends userID has
        .setIntersection userAsFriend

        # 'Join' to the User tables and execute
        .map (friendID) -> r.table('User').get friendID
        .execute()

        # And then process the returned promise
        .then (cursor) ->
            cursor.toArray()
        .then (friends) ->
            _.map friends, userHelpers.cleanUser

# Returns a list of pending friend requests, ready for user userID to accept
getPendingFriendships = (userID) ->
    userAsUser = r.table 'Friendship'
        .getAll userID, {index: 'userID'}
        .map (row) -> row 'friendID'
        .coerceTo 'array'

    Friendship
        # First create a list of users who have a friendship of our user
        .getAll userID, {index: 'friendID'}
        .map (row) -> row 'userID'

        # Then create a list the other way around and remove the interseection of both
        # The difference will be all the pending friendship for user userID
        .difference userAsUser

        # 'Join' to the User table, and execute
        .map (friendID) -> r.table('User').get friendID
        .execute()

        # And then process the returned promise
        .then (cursor) ->
            cursor.toArray()
        .then (friends) ->
            _.map friends, userHelpers.cleanUser

deleteFriendship = (user1, user2) ->
    # Delete friendships both ways - it's OK if one (or both) don't exist.
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
    getPendingFriendships
    mapFriendStatus
    requireFriendship
    FRIENDSHIP_STATUS
}