thinky = require './thinky'

User = require './User'

Capture = thinky.createModel 'Capture',
    id: String
    ownerID: String
    ucImageID: String
    processedBy: String
    tzOffset: Number
    processed: Boolean
    created: Date
    updated: Date

Capture.belongsTo User.model, 'owner', 'ownerID', 'id'
Capture.belongsTo User.model, 'processedByUser', 'processedBy', 'id'

exports.model = Capture
exports.helpers = {}