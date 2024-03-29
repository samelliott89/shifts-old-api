_ = require 'underscore'
bluebird = Promise = require 'bluebird'
thinky = require './thinky'
r = thinky.r

_errs = require '../errors'
userModelDef = require './User'
CalendarModelDef = require './Calendar'
User = userModelDef.model
userHelpers = userModelDef.helpers
Calendar = CalendarModelDef.model
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
        .filter (row) -> row('right')('end').gt shiftsSince
        .map (row) -> row('right').merge({owner: row('left')})
        .orderBy 'start'

        r.expr {shifts, users}


_getShiftsWithCoworkers = ({shiftOwnerID, shiftsSince}) ->
    shiftsSince ?= new Date()

    r.table 'Shift'
        # Get all shifts for the current user since a specified date
        .getAll shiftOwnerID, {index: 'ownerID'}
        .filter (shift) -> shift('start').gt shiftsSince

        # Join the owner onto the shifts
        .eqJoin 'ownerID', r.table('User')

        # Now, for each shift...
        .map (_shift) ->
            shift = _shift('left')
            shift.merge {owner: _shift('right')}


exports.helpers =
    SHIFT_SOURCE_BOOKMARKLET: 'bookmarklet'
    SHIFT_SOURCE_CAPTURE: 'capture'

    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

    getShiftsForUserAndCoworkers: (userID) ->
        _getUsersAndCorworkersShifts({userID}).run()
            .then ({shifts, users}) ->
                output = {}
                output.shifts = _.map shifts, (shift) ->
                    shift.owner = userHelpers.cleanUser shift.owner
                    return shift

                output.users = _.map users, (user) ->
                    userHelpers.cleanUser user

                return output

    getShiftsViaCalendar: (calendarID, daysBack = 7) ->
        shiftsSince = new Date()
        shiftsSince.setDate shiftsSince.getDate() - daysBack

        Calendar.getAll calendarID
            .eqJoin 'ownerID', r.table('Shift'), {index: 'ownerID'}
            .pluck 'right'
            .map (row) -> row 'right'
            .filter (shift) -> shift('start').gt shiftsSince
            .run()

    getShiftsForUser: (ownerID, opts = {}) ->

        unless opts.shiftsSince
            opts.shiftsSince = new Date()
            opts.shiftsSince.setDate opts.shiftsSince.getDate() - 1

        opts.throwOnInvalidPermission ?= true

        promises = [
            _getShiftsWithCoworkers({
                    shiftOwnerID: ownerID
                    shiftsSince: opts.shiftsSince
                }).run()
        ]

        # TODO: Use models.requireFriendship() here instead to reject if they're not friends
        if opts.req?.user?.id
            promises.push friendshipHelpers.getFriendshipStatus opts.req.user.id, ownerID

        bluebird.all promises
            .then ([shifts, friendshipStatus]) ->
                # If we've checked for friendship status (if opts.req was passed in),
                # throw error if they're not mutual friends

                friendshipIsntMutual = friendshipStatus isnt friendshipHelpers.FRIENDSHIP_STATUS.MUTUAL
                isntOwnUser = opts.req?.user?.id isnt ownerID
                notAdmin = opts.req?.user?.traits?.admin isnt true

                if (typeof friendshipStatus isnt undefined) and friendshipIsntMutual and isntOwnUser and notAdmin

                    if opts.throwOnInvalidPermission
                        throw new _errs.InvalidPermissions()
                    else
                        return []

                # Clean shifts and the owner object on them
                shifts = _.chain shifts
                    # Reject shifts when the start date is more than 24 hours ago
                    .reject (shift) ->
                        shift.start < opts.shiftsSince
                    .each((shift) ->
                        shift.owner = userHelpers.cleanUser shift.owner, opts.req # opts.req might be undefined, but that's OK
                        _.each shift.coworkers, (coShift) ->
                            coShift.owner = userHelpers.cleanUser coShift.owner, opts.req

                    ).value()

                shifts.sort (a, b) -> new Date(a.start) - new Date(b.start)
                return shifts

    deleteShift: (shiftID) -> Shift.get(shiftID).delete().run()
