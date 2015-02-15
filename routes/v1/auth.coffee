_ = require 'underscore'
mandrill = require 'mandrill-api/mandrill'

auth = require '../../auth'
_errs = require '../../errors'
models = require '../../models'
config = require '../../config'

mandrillClient = new mandrill.Mandrill config.MANDRILL_API_KEY

validRegistrationFields = ['email', 'password', 'displayName', 'profilePhoto']

_sendWelcomeEmail = (user) ->
    messageHTML = """
    <p>Hey #{user.displayName},</p>

    <p>Josh and Sam here from Robby. We're guessing it's not everyday you download a new app
    so we just wanted to make sure everything is in place for you to feel welcome and at home.</p>

    <p>We hope you've gotten the hang of Robby, but if we could suggest one thing to
    kick things off, it would be to add your first weeks or fortnights schedule. Robby works best when you upload a full schedule
    and you're <em>connected</em> with those you work with.</p>

    <p>Before we go, we just want to let you know that we're here to answer any questions or respond to any feedback.
    Please let us know if you if you need any help, feature ideas or just want to say hi.</p>

    <p>
        Cheers,<br/>
        Sam + Josh
    </p>
    """
    sendInMinutes = parseInt(config.WELCOME_EMAIL_DURATION)
    sendAt = new Date()
    sendAt.setMinutes(sendAt.getMinutes() + sendInMinutes)
    sendAtUTC = sendAt.toISOString().replace('T', ' ').split('.')[0]

    message = {
        html: messageHTML
        subject: "Sam and Josh here from Robby!"
        from_email: "sam@heyrobby.com"
        from_name: "Robby"
        to: [{
            email: user.email
            name: user.displayName
        }]
        important: true
        track_opens: true
        track_clicks: true
        auto_text: true
        tags: ['shifts-transactional', 'welcome-email']
    }

    _chimpSuccess = ([result]) ->
        invalidstatus = ['rejected', 'invalid']
        if not result and result.reject_reason
            console.log 'Could not send welcome email: '
            console.log result
            throw new _errs.ServerError 'Error sending welcome email'

    _chimpFailure = (err) ->
        console.log 'Mailchimp error:'
        console.log err
        throw new _errs.ServerError 'Error sending welcome email'

    mandrillClient.messages.send {message, send_at: sendAtUTC}, _chimpSuccess, _chimpFailure

exports.register = (req, res, next) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)
    _errs.handleValidationErrors {req}

    # Only include whitelisted fields
    userFields = _.pick req.body, validRegistrationFields

    models.getUser userFields.email, {includePassword: true}
        .then ->
            next new _errs.ValidationFailed {email:msg: 'The supplied email address is already taken'}

        .catch (err) ->
            unless err instanceof _errs.NotFound
                return next err

            newUser = new models.User userFields
            newUser.setPassword userFields.password
            newUser.traits = {}
            newUser.created = new Date()

            newUser.saveAll()
                .then (user) ->
                    token = auth.createToken user
                    res.json {user, token}
                    # Send welcome email to new user after response is sent back to client
                    _sendWelcomeEmail newUser
                .catch _errs.handleRethinkErrors err

exports.login = (req, res, next) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)
    _errs.handleValidationErrors {req}

    models.getUser req.body.email, {includePassword: true}
        .then (user) ->
            if auth.checkPassword user, req.body.password
                token = auth.createToken user
                user = user.clean()
                res.json {user, token}
            else
                next new _errs.AuthFailed {password:msg: 'Password is incorrect'}

        .catch (err) ->
            if models.helpers.notFound err
                next new _errs.AuthFailed {email:msg: 'No account exists for this email'}
            else
                _errs.handleRethinkErrors err

exports.refreshToken = (req, res) ->
    token = auth.createToken req.user
    res.json {token}