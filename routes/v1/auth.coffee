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

    <p>Thanks so much for joining Robby. The app designed to make managing your schedule really easy.</p>

    <p>To get the most out of Robby we suggest you start adding your shifts straight away. This can be done easily through our
    intuitive user interface or automatically if we <a href="http://heyrobby.com/supported-schedules?utm_source=welcomeEmail&utm_medium=email&utm_campaign=supportedSchedules">support</a>
    your online schedule at work. If we don't current support your schedule, feel free to reach out to us and we'll see what we can do!</p>

    <p>You can also <em>connect</em> with people you work with in order to view their schedule, see when they have days off and when you're
    working with them next.<p>

    <p>If you have any questions or feeback, just reply to this email and we'll definitely help you out.</p>

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
        subject: "Welcome to Robby!"
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
            if models.helpers.notFound err
                next new _errs.AuthFailed {email:msg: 'No account exists for this email'}
            else
                _errs.handleRethinkErrors err

exports.refreshToken = (req, res) ->
    token = auth.createToken req.user
    res.json {token}