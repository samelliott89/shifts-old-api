thinky = require('thinky')()
User = require './User'

Shift = thinky.createModel 'Shift',
    id: String
    title: String
    start: Date
    end: Date
    ownerId: String

Shift.belongsTo User.model, 'owner', 'ownerID', 'id'

exports.models = Shift

exports.helpers =
    getShift: (shiftID) -> Shift.get(shiftID).getJoin().run()