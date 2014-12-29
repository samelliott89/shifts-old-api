_ = require 'underscore'
bluebird = Promise = require 'bluebird'
thinky = require './thinky'
r = thinky.r

_errs = require '../errors'
User = require('./User').model
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

exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

    getShiftsForUser: (ownerID, opts = {}) ->
        promises = [
            Shift.filter({ownerID}).getJoin().run()
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

                oneDay = 1000 * 60 * 60 * 24
                shiftsFrom = new Date()
                shiftsFrom.setTime shiftsFrom.getTime() - oneDay

                # Clean shifts and the owner object on them
                shifts = _.chain shifts
                    # Reject shifts when the start date is more than 24 hours ago
                    .reject (shift) ->
                        shift.start < shiftsFrom
                    .each((shift) ->
                        shift.owner = shift.owner.clean opts.req # opts.req might be undefined, but that's OK
                    ).value()

                shifts.sort (a, b) -> new Date(a.start) - new Date(b.start)
                return shifts

    deleteShift: (shiftID) -> Shift.get(shiftID).delete().run()
