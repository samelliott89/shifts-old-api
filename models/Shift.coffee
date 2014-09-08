_ = require 'underscore'
Promise = require 'bluebird'
thinky = require('thinky')()

User = require './User'

Shift = thinky.createModel 'Shift',
    id: String
    title: String
    start: Date
    end: Date
    ownerID: String

Shift.belongsTo User.model, 'owner', 'ownerID', 'id'

exports.model = Shift

exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()

    getShiftsForUser: (ownerID) -> new Promise (resolve, reject) ->
        Shift.filter({ownerID}).getJoin().run()
            .then (results) ->
                _.each results, (shift) ->
                    User.helpers.prepareUser shift.owner
                    delete shift.ownerID

                resolve results
            .catch reject