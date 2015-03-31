thinky = require './thinky'

User = require './User'

Capture = thinky.createModel 'Capture',
    id: String
    ownerID: String
    ucImageID: String
    processedByID: String
    claimedByID: String
    tzOffset: Number
    processed: Boolean
    created: Date
    updated: Date

Capture.belongsTo User.model, 'owner', 'ownerID', 'id'
Capture.belongsTo User.model, 'processedBy', 'processedByID', 'id'
Capture.belongsTo User.model, 'claimedBy', 'claimedByID', 'id'

exports.model = Capture
exports.helpers = {}