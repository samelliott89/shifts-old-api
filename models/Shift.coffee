thinky = require('thinky')()

User = require './User'

Shift = thinky.createModel 'Shift',
    id: String
    title: String
    start: Date
    end: Date
    ownerId: String

Shift.belongsTo User, 'owner', 'ownerID', 'id'

module.exports = Shift