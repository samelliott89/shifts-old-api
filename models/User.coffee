thinky = require('thinky')()

User = thinky.createModel 'User',
    id: String
    displayName: String
    profilePhoto: String

exports.model = User

exports.helpers =
    getUser: (userID) -> User.get(userID).getJoin().run()