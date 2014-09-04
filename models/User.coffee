thinky = require('thinky')()

module.exports = thinky.createModel 'User',
    id: String
    displayName: String
    profilePhoto: String
