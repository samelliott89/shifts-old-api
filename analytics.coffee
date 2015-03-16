# Analytics = require 'analytics-node'
config  = require './config'
# analytics = new Analytics config.SEGMENT_IO_KEY

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

    # analytics.track ev