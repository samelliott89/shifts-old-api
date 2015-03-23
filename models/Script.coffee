{createModel} = require './modelHelpers'

module.exports = createModel 'Script', {
    name: String
    javascript: String
    coffeescript: String
    isEnabled: Boolean
}, {pk: 'name'}
