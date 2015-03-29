_ = require 'underscore'
config = require '../config'
mandrill = require 'mandrill-api/mandrill'

mandrillClient = new mandrill.Mandrill config.MANDRILL_API_KEY

defaultMessage = {
    from_email: 'hi@heyrobby.com'
    from_name: 'Team Robby'
    track_opens: true
    track_clicks: true
    auto_text: true
}

exports.sendEmail = (opts, globalVars) ->
    opts.message = _.defaults opts.message, defaultMessage
    opts.async ?= false

    if globalVars
        opts.message.merge_language = 'handlebars'
        opts.message.global_merge_vars = []

        for name, content of globalVars
            opts.message.global_merge_vars.push {name, content}

    _chimpSuccess = (allResults) ->
        for result in allResults
            if result.reject_reason
                console.log 'Mailchimp error'
                console.error result

    _chimpFailure = (err) ->
        console.log 'Mailchimp error:'
        console.error err

    if opts.template_name
        opts.template_content = [{}]
        func = 'sendTemplate'
    else
        func = 'send'

    mandrillClient.messages[func] opts, _chimpSuccess, _chimpFailure
