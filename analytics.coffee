Analytics = require 'analytics-node'
config  = require './config'
analytics = new Analytics config.SEGMENT_IO_KEY

exports.segment = analytics
exports.track = (req, eventName, eventProperies = {}) ->
    ev = {
        event: eventName
        properties: eventProperies
    }

    if req?.user?.id
        ev.userId = req.user.id
    else
        ev.anonymousId = 'anon-user'

    analytics.track ev

exports.identify = (user) ->
    cleanedUser = user.clean null, {includeExtra: true}
    cleanedUser['$email'] = cleanedUser.email
    cleanedUser['$name'] = cleanedUser.displayName
    traits = []

    for traitName, traitEnabled of (user.traits or {}) when traitEnabled
        cleanedUser["hasTrait_#{traitName}"] = true
        traits.push traitName

    user.traits = traits.join ','

    if cleanedUser.profilePhoto?.href
        cleanedUser.profilePhoto = cleanedUser.profilePhoto.href

    cleanedUser.counts = undefined  if cleanedUser.counts
    cleanedUser.defaultPhoto = undefined  if cleanedUser.defaultPhoto

    analytics.identify {
        userId: cleanedUser.id
        traits: cleanedUser
    }
