_ = require 'underscore'
Promise = require 'bluebird'
thinky = require './thinky'
r = thinky.r

User = require './User'

Shift = thinky.createModel 'Shift',
    id: String
    title: String
    start: Date
    end: Date
    ownerID: String

Shift.ensureIndex 'start'
Shift.ensureIndex 'ownerID'

Shift.belongsTo User.model, 'owner', 'ownerID', 'id'

exports.model = Shift

oneDay = 1000 * 60 * 60 * 24
shiftsFrom = new Date()
shiftsFrom.setTime shiftsFrom.getTime() - oneDay

exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

    getShiftsForUser: (ownerID) -> new Promise (resolve, reject) ->
        Shift.filter({ownerID}).getJoin().run()
            .then (results) ->
                shifts = _.chain results
                    # Reject shifts when the start date is more than 24 hours ago
                    .reject (shift) ->
                        shift.start < shiftsFrom
                    .each((shift) ->
                        # TODO: use cleanUser instead
                        shift.owner = shift.owner.clean()
                        delete shift.ownerID
                    )
                    .value()

                shifts.sort (a, b) -> new Date(a.start) - new Date(b.start)

                resolve shifts
            .catch reject

    deleteShift: (shiftID) -> Shift.get(shiftID).delete().run()
