request = require 'request'

models = require '../../models'
analytics = require '../../analytics'
config = require '../../config'
slack = require '../../slack'

env = (config.NODE_ENV or 'dev').toLowerCase()
robbyToolsUrl = 'http://tools.heyrobby.com/#/capture'

sendSlackNotification = ({id}) ->
    models.Capture.get id
        .getJoin()
        .run()
        .then (capture) ->
            text = "<!channel>: #{capture.owner.displayName} has uploaded a new schedule capture. <#{robbyToolsUrl}|Convert it now!> (remember to tell this channel that you've got it)"
            slack.sendMessage {text}

exports.addCapture = (req, res, next) ->

    capture = new models.Capture
        ownerID: req.user.id
        ucImageID: req.body.ucImageID
        tzName: req.body.tzName
        created: new Date()
        processed: false
        rejected: false

    models.Capture.save capture
        .then (result) ->
            analytics.track req, 'Roster Capture'
            sendSlackNotification()
            res.json {capture: capture}
        .catch next
