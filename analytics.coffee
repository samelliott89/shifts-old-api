Analytics = require 'analytics-node'
config  = require './config'
analytics = new Analytics config.SEGMENT_IO

exports.segment = analytics
exports.track (req, eventName, eventProperies = {}) ->
    req ?= {user: {id: 0}}

    analytics.track {
        event: eventName
        userId: req.user.id
        properties: eventProperies
    }