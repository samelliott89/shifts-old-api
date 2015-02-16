thinky = require './thinky'

User = require './User'

Parse = thinky.createModel 'Parse',
    id: String
    ownerID: String
    shifts: Array
    parseKey: String
    parserName: String

Parse.belongsTo User.model, 'owner', 'ownerID', 'id'

exports.model = Parse
exports.helpers = {}