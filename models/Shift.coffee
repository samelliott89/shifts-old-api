_ = require 'underscore'
bluebird = Promise = require 'bluebird'
thinky = require './thinky'
r = thinky.r

_errs = require '../errors'
userModelDef = require './User'
User = userModelDef.model
userHelpers = userModelDef.helpers
friendshipHelpers = require('./Friendship').helpers

Shift = thinky.createModel 'Shift',
    id: String
    title: String
    start: Date
    end: Date
    created: Date
    updated: Date
    ownerID: String

Shift.ensureIndex 'start'
Shift.ensureIndex 'ownerID'

Shift.belongsTo User, 'owner', 'ownerID', 'id'

exports.model = Shift

_getUsersAndCorworkersShifts = ({userID, shiftsSince}) ->
    unless userID
        throw new Error 'Param userID is required. This must be the user ID of the currently logged in user.'

    unless shiftsSince
        shiftsSince = new Date()
        shiftsSince.setDate(shiftsSince.getDate() - 1)

    r.expr(
        # Get list of friends IDs
        r.table 'Friendship'
            .getAll userID, {index: 'friendID'}
            # Make sure the owner of the shifts doesnt show up in coworkers
            .filter (row) -> row('userID').ne(userID)
            .map (row) -> row('userID')
            .coerceTo('array')
            .setIntersection(
                r.table 'Friendship'
                    .getAll userID, {index: 'userID'}
                    .map (row) -> row('friendID')
                    .coerceTo('array')
            )
            .add [userID]
            .eqJoin(
                (doc) -> doc,
                r.table('User')
            )
            .without({left: 'id'}).zip()

    ).do (users) ->
        shifts = users.eqJoin(
            'id'
            r.table('Shift'),
            {index: 'ownerID'}
        )
        .map (row) -> row('right').merge({owner: row('left')})
        .orderBy 'start'

        r.expr {shifts, users}


_getShiftsWithCoworkers = ({shiftOwnerID, currentUserID, shiftsSince}) ->
    unless currentUserID
        throw new Error 'Param currentUserID is required. This must be the user ID of the currently logged in user.'

    shiftsSince ?= new Date()

    r.expr(
        # Get list of friends IDs
        r.table 'Friendship'
            .getAll currentUserID, {index: 'friendID'}
            # Make sure the owner of the shifts doesnt show up in coworkers
            .filter (row) -> row('userID').ne(shiftOwnerID)
            .map (row) -> row('userID')
            .coerceTo('array')
            .setIntersection(
                r.table 'Friendship'
                    .getAll currentUserID, {index: 'userID'}
                    .map (row) -> row('friendID')
                    .coerceTo('array')
            )
    ).do (friendIDs) ->
        r.table 'Shift'
            # Get all shifts for the current user since a specified date
            .getAll shiftOwnerID, {index: 'ownerID'}
            .filter (shift) -> shift('start').gt shiftsSince

            # Join the owner onto the shifts
            .eqJoin 'ownerID', r.table('User')

            # Now, for each shift...
            .map (_shift) ->
                shift = _shift('left')

                # Find all shifts my friends are working on the same day I'm working
                coworkerShifts = friendIDs.eqJoin(
                        (doc) -> doc,
                        r.table('Shift'),
                        {index: 'ownerID'}
                    )
                    # remove the {left, right} artefact of using eqJoin()
                    .without({left: 'id'}).zip()
                    .filter (coShift) ->
                        # Ensure the coworkers shift is on the same day as the user's shift
                        coShift('start').during(
                            shift('start').date(),
                            shift('end').date(),
                            {leftBound: "open", rightBound: "open"}
                        )
                    # Join the owner onto each coworker shift
                    .eqJoin 'ownerID', r.table('User')
                    .map (row) ->
                        row('left').merge({owner: row('right')})
                # Finally merge them onto the shift (and unpack the {left, right} from the original owner merge)
                shift.merge {owner: _shift('right'), coworkers: coworkerShifts}


exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

    getShiftsForUserAndCoworkers: (userID) -> _getUsersAndCorworkersShifts({userID}).run()

    getShiftsForUser: (ownerID, opts = {}) ->
        oneDay = 1000 * 60 * 60 * 24
        shiftsFrom = new Date()
        shiftsFrom.setTime shiftsFrom.getTime() - oneDay

        promises = [
            _getShiftsWithCoworkers({
                    shiftOwnerID: ownerID
                    currentUserID: opts.req.user.id
                    shiftsSince: shiftsFrom
                }).run()
        ]

        # TODO: Use models.requireFriendship() here instead to reject if they're not friends
        if opts.req?.user?.id
            promises.push friendshipHelpers.getFriendshipStatus opts.req.user.id, ownerID

        bluebird.all promises
            .then ([shifts, friendshipStatus]) ->
                # If we've checked for friendship status (if opts.req was passed in),
                # throw error if they're not mutual friends
                if typeof friendshipStatus isnt undefined and
                   friendshipStatus isnt friendshipHelpers.FRIENDSHIP_STATUS.MUTUAL and
                   opts.req?.user?.id isnt ownerID
                    throw new _errs.InvalidPermissions()

                # Clean shifts and the owner object on them
                shifts = _.chain shifts
                    # Reject shifts when the start date is more than 24 hours ago
                    .reject (shift) ->
                        shift.start < shiftsFrom
                    .each((shift) ->
                        shift.owner = userHelpers.cleanUser shift.owner, opts.req # opts.req might be undefined, but that's OK
                        _.each shift.coworkers, (coShift) ->
                            coShift.owner = userHelpers.cleanUser coShift.owner, opts.req

                    ).value()

                shifts.sort (a, b) -> new Date(a.start) - new Date(b.start)
                return shifts

    deleteShift: (shiftID) -> Shift.get(shiftID).delete().run()
