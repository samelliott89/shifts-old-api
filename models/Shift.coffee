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
    ownerID: String

Shift.ensureIndex 'start'
Shift.ensureIndex 'ownerID'

Shift.belongsTo User, 'owner', 'ownerID', 'id'

exports.model = Shift

_getShiftsWithCoworkers = ({shiftOwnerID, currentUserID, shiftsSince}) ->
    unless currentUserID
        throw new Error 'Param currentUserID is required. This must be the user ID of the currently logged in user.'

    shiftsSince ?= new Date()

    r.expr(
        r.table 'Friendship'
            .getAll currentUserID, {index: 'friendID'}
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
            .getAll shiftOwnerID, {index: 'ownerID'}
            .filter (shift) -> shift('start').gt shiftsSince
            .eqJoin 'ownerID', r.table('User')
            .map (_shift) ->
                shift = _shift('left')
                coworkerShifts = friendIDs.eqJoin(
                        (doc) -> doc,
                        r.table('Shift'),
                        {index: 'ownerID'}
                    )
                    .without({left: 'id'}).zip()
                    .filter (coShift) ->
                        coShift('start').during(
                            shift('start').date(),
                            shift('end').date(),
                            {leftBound: "open", rightBound: "open"}
                        )
                    .eqJoin 'ownerID', r.table('User')
                    .map (row) ->
                        row('left').merge({owner: row('right')})
                shift.merge {owner: _shift('right'), coworkers: coworkerShifts}


exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

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

                console.log 'Got shifts back:'
                console.log shifts

                # Clean shifts and the owner object on them
                shifts = _.chain shifts
                    # Reject shifts when the start date is more than 24 hours ago
                    .reject (shift) ->
                        console.log shift
                        shift.start < shiftsFrom
                    .each((shift) ->
                        shift.owner = userHelpers.cleanUser shift.owner, opts.req # opts.req might be undefined, but that's OK
                        _.each shift.coworkers, (coShift) ->
                            coShift.owner = userHelpers.cleanUser coShift.owner, opts.req

                    ).value()

                shifts.sort (a, b) -> new Date(a.start) - new Date(b.start)
                return shifts

    deleteShift: (shiftID) -> Shift.get(shiftID).delete().run()
