thinky = require './thinky'

User = require './User'

Calendar = thinky.createModel 'Calendar',
    id: String
    ownerID: String

Calendar.ensureIndex 'ownerID'
Calendar.belongsTo User.model, 'owner', 'ownerID', 'id'

exports.model = Calendar
exports.helpers = {}