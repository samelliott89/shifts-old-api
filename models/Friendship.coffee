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






status = FRIENDSHIP_STATUS = {
    NONE: 0
    MUTUAL: 1
    USER2_TO_ACCEPT: -1
    USER1_TO_ACCEPT: -2
}

statusMap = FRIENDSHIP_STATUS_MAP = _.invert status

_evaluateFriendship = (rel1, rel2) ->
    if rel1 and rel2
        return status.MUTUAL
    else if rel1 and not rel2
        return status.USER2_TO_ACCEPT
    else if not rel1 and rel2
        return status.USER1_TO_ACCEPT
    else
        return status.NONE

_evaluateFriendshipPromise = ([[rel1], [rel2]]) ->
    new Promise (resolve) ->
        resolve _evaluateFriendship(rel1, rel2)

mapFriendStatus = (status) ->
    _.invert(FRIENDSHIP_STATUS)[status]

getFriendshipStatus = (user1, user2) ->
    promises = [
        Friendship.getAll(user1 + user2, {index: 'UserToFriend'}).run()
        Friendship.getAll(user2 + user1, {index: 'UserToFriend'}).run()
    ]

    bluebird.all promises
        .then _evaluateFriendshipPromise

getMultipleFriendshipStatus = (user1, otherUsers, opts = {}) ->
    opts.friendly ?= false

    allIndexes = []

    _.each otherUsers, (user2) ->
        allIndexes.push user1 + user2
        allIndexes.push user2 + user1

    # Package emails for rethink
    r.expr(allIndexes)

        # And join them to the User table by using the 'email' inde
        .eqJoin(((email) -> email), r.table('Friendship'), {index: 'UserToFriend'})

        # Remove any duplicates
        .distinct()

        # And get only the users and execute
        .map (row) -> row('right')
        .run()

        .then (allFriendships) ->
            # Map the friendship data to something we can check easily 'query' pairs for
            rels = {}
            for ship in allFriendships
                rels[ship.userID + ship.friendID] = true

            # Store the relationships data results
            results = {}
            for user2 in otherUsers
                # Figure out which way the relationships exists
                rel1 = rels[user1 + user2]
                rel2 = rels[user2 + user1]

                # Figure out if its mutual or not
                shipStatus = _evaluateFriendship rel1, rel2

                if opts.friendly
                    shipStatus = statusMap[shipStatus]

                # Add it to our return obj
                results[user2] = shipStatus

            return results


requireFriendship = (user1, user2) ->
    getFriendshipStatus user1, user2
        .then (friendship) ->
            unless friendship is status.MUTUAL or user1 is user2
                return Promise.reject new _errs.InvalidPermissions()
            return

getFriends = (userID, joinToUsers = true) ->
    userAsFriend = r.table('Friendship')
        .getAll userID, {index: 'friendID'}
        .map (row) -> row 'userID'
        .coerceTo 'array'

    query = Friendship
        # First, create a list one direction of relationships
        .getAll userID, {index: 'userID'}
        .map (row) -> row 'friendID'
        .coerceTo 'array'

        # Then create a list the other way around and find the intersection of both
        # This intersection is all the friends userID has
        .setIntersection userAsFriend

    # Optionally 'join' to the User tables and execute
    if joinToUsers
        query = query.map (friendID) -> r.table('User').get friendID

    query.execute()

        # And then process the returned promise
        .then (cursor) ->
            cursor.toArray()
        .then (friends) ->
            if joinToUsers
                return _.map friends, userHelpers.cleanUser
            else
                return friends

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
    getMultipleFriendshipStatus
    mapFriendStatus
    requireFriendship
    FRIENDSHIP_STATUS
}