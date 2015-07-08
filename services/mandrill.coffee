_ = require 'underscore'
config = require '../config'
mandrill = require 'mandrill-api/mandrill'
Promise = require 'bluebird'

mandrillClient = new mandrill.Mandrill config.MANDRILL_API_KEY

defaultMessage = {
    from_email: 'hi@getatum.com'
    from_name: 'Team Atum'
    track_opens: true
    track_clicks: true
    auto_text: true
}

exports.sendEmail = (opts, globalVars) -> new Promise (resolve, reject) ->
    unless config.env is 'prod'
        console.log 'Supressing email send:'
        console.log opts
        console.log globalVars
        resolve undefined
        return

    opts.message = _.defaults opts.message, defaultMessage
    opts.async ?= false

    if globalVars
        opts.message.merge_language = 'handlebars'
        opts.message.global_merge_vars = []

        for name, content of globalVars
            opts.message.global_merge_vars.push {name, content}

    _chimpSuccess = (allResults) ->
        failed = false
        for result in allResults
            if result.reject_reason
                failed = true
                console.log 'Mailchimp error'
                console.error result

        if failed
            reject allResults
        else
            resolve allResults

    _chimpFailure = (err) ->
        reject err
        console.log 'Mailchimp error:'
        console.error err

    if opts.template_name
        opts.template_content = [{}]
        func = 'sendTemplate'
    else
        func = 'send'

    mandrillClient.messages[func] opts, _chimpSuccess, _chimpFailure
