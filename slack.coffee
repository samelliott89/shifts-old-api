config = require './config'
request = require 'request'

module.exports.REJECT_CHANNEL = '#roster-capture-reject'

module.exports.sendMessage = ({text, channel, attachments}) ->
    unless config.env is 'prod'
        chMessage = if channel then "#{channel}: " else ''
        console.log "[Slack] #{chMessage}#{text}"
        for a in attachments
            console.log a
        return

    req = {
        uri: config.CAPTURE_SLACK_NOTIFY_URL
        method: 'post'
        json: true
        body: {text, channel, attachments}
    }

    request req, (err, resp) ->
        if err
            console.log err
            return