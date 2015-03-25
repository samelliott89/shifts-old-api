Analytics = require 'analytics-node'
config  = require './config'

SEND_ANALYTICS = config.SEGMENT_IO_KEY.length > 1
if SEND_ANALYTICS
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

    if not SEND_ANALYTICS
        console.log 'Suppressing analytics.track:', ev
        return

    analytics.track ev

exports.identify = (user) ->
    cleanedUser = user.clean null, {includeOwnUserFields: true}
    cleanedUser['$email'] = cleanedUser.email
    cleanedUser['$name'] = cleanedUser.displayName
    traits = []

    for traitName, traitEnabled of (user.traits or {}) when traitEnabled
        cleanedUser["hasTrait_#{traitName}"] = true
        traits.push traitName

    cleanedUser.traits = traits.join ','

    if cleanedUser.profilePhoto?.href
        cleanedUser.profilePhoto = cleanedUser.profilePhoto.href

    delete cleanedUser.counts
    delete cleanedUser.defaultPhoto

    ev = {
        userId: cleanedUser.id
        traits: cleanedUser
    }

    if not SEND_ANALYTICS
        console.log 'Suppressing analytics.identify:', ev
        return

    analytics.identify ev
