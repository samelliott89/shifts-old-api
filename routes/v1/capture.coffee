request = require 'request'

models = require '../../models'
analytics = require '../../analytics'
config = require '../../config'

env = (config.NODE_ENV or 'dev').toLowerCase()

if env is 'prod'
    robbyToolsUrl = 'http://tools.heyrobby.com'
else if env is 'test'
    robbyToolsUrl = 'http://test-robbytools.elasticbeanstalk.com'
else
    robbyToolsUrl = 'http://localhost:5017'

sendSlackNotification = (capture) ->
    msg = "New roster capture has been added. <#{robbyToolsUrl}|Convert it now!> (remember to tell this channel that you've got it)"

    if env is 'prod'
        msg = '<!channel>: ' + msg
    else
        msg = "[#{env}]: #{msg}"

    req = {
        url: config.CAPTURE_SLACK_NOTIFY_URL
        method: 'post'
        json: true
        body: { text: msg }
    }
    request req, (err, resp) ->
        console.log err if err
        console.log 'Slack response error code:', resp.statusCode

exports.addCapture = (req, res, next) ->

    capture = new models.Capture
        ownerID: req.user.id
        ucImageID: req.body.ucImageID
        tzName: req.body.tzName
        processed: false
        created: new Date()

    models.Capture.save capture
        .then (result) ->
            analytics.track req, 'Roster Capture'
            sendSlackNotification()
            res.json {capture: capture}
        .catch next
