class InvalidPermissions extends Error
    name: 'InvalidPermissions'
    constructor: (@message) ->

exports.InvalidPermissions = InvalidPermissions