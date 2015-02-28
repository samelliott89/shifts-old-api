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

    <p>Sam here, cofounder of Robby. I'm guessing it's not everyday you download a new app
    so we just wanted to make sure everything's in place for you to feel welcome and at home.</p>

    <p>Hopefully by now you've gotten the hang of Robby. If you haven't already, we suggest adding your first
    week's or fortnight's schedule. Robby works best when you have all your upcoming shifts and
    you've connected with your friends and coworkers.</p>

    <p>Before I go, I just want to let you know that I'm here to answer any questions or respond to any feedback.
    Please let us know if you need any help, have feature ideas or just want to say hi.</p>

    <p>
        Cheers,<br/>
        Sam
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

    _chimpFailure = (err) ->
        console.log 'Mailchimp error:'
        console.log err

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
            if err instanceof _errs.NotFound
                err = new _errs.AuthFailed {email:msg: 'No account exists for this email'}

            next err

exports.refreshToken = (req, res) ->
    token = auth.createToken req.user
    res.json {token}

exports.saveAuthCookie = (req, res) ->
    sessionAuthToken = req.cookies.sessionAuthToken
    unless sessionAuthToken
        throw new _errs.ValidationFailed 'Session auth token not present'

    expires = new Date()
    expires.setDate expires.getDate() + 60
    console.log 'setting cookie to expire in', expires
    res.cookie config.AUTH_COOKIE_NAME, sessionAuthToken, { expires, httpOnly: true }
    res.clearCookie 'sessionAuthToken'
    res.json {success: true}

exports.clearAuthCookie = (req, res) ->
    res.clearCookie 'sessionAuthToken'
    res.clearCookie config.AUTH_COOKIE_NAME
    res.json {success: true}