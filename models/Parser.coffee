{createModel} = require './modelHelpers'

module.exports = createModel 'Parser',
    id: String
    name: String
    validUrls: [String]
    selector: String
    preflight: String
    isEnabled: Boolean

module.exports.model.ensureIndex 'name'
module.exports.model.ensureIndex 'isEnabled'

