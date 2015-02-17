thinky = require './thinky'

User = require './User'

Parse = thinky.createModel 'Parse',
    id: String
    ownerID: String
    shifts: Array
    parseKey: String
    parserName: String

Parse.belongsTo User.model, 'owner', 'ownerID', 'id'

# Create a compound index that looks like 'ownerIDparseKey' (rather than [userID, friendID])
Parse.ensureIndex 'ownerParseKey', (doc) ->
    doc('ownerID').add(doc('parseKey'))

exports.model = Parse
exports.helpers = {}