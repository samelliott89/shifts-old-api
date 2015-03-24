{createModel} = require './modelHelpers'

module.exports = createModel 'Link',
    id: String
    href: String
    text: String
    type: String
    icon: Array
    iconSize: String

module.exports.model.ensureIndex 'type'