Analytics = require 'analytics-node'
config  = require './config'
crypto = require 'crypto'

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

    if user.profilePhoto
        avatar = "#{user.profilePhoto.href}/-/scale_crop/200x200/"
    else
        photoHash = crypto.createHash('md5').update(user.id).digest('hex')
        avatar = "http://www.gravatar.com/avatar/#{photoHash}?default=retro&s=200"

    traits = []

    for traitName, traitEnabled of (user.traits or {}) when traitEnabled
        traits.push traitName

    userTraits = {
        id: user.id
        avatar: avatar
        email: user.email
        active: user.active
        description: user.bio
        name: user.displayName
        createdAt: user.created
        registerSource: user.source
        futureShifts: user.counts?.shifts
        connections: user.counts?.connections
    }

    ev = {
        userId: userTraits.id
        traits: userTraits
    }

    if not SEND_ANALYTICS
        console.log 'Suppressing analytics.identify:', ev
        return

    analytics.identify ev
