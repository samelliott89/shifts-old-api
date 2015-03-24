config = require './config'
request = require 'request'

module.exports.sendMessage = ({text, channel}) ->
    unless config.env is 'prod'
        console.log 'Slack:', text
        return

    req = {
        uri: config.CAPTURE_SLACK_NOTIFY_URL
        method: 'post'
        json: true
        body: { text, channel }
    }

    console.log req

    request req, (err, resp) ->
        if err
            console.log err
            return