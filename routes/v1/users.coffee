_ = require 'underscore'
bluebird = require 'bluebird'
jwt = require 'jsonwebtoken'
mandrill = require 'mandrill-api/mandrill'

auth = require '../../auth'
config = require '../../config'
models = require '../../models'
_errs = require '../../errors'

mandrillClient = new mandrill.Mandrill config.MANDRILL_API_KEY

exports.getUser = (req, res, next) ->
    userID = req.param 'userID'
    promises = [
        models.getUser userID, {req, clean: true}
        models.getFriends userID
    ]

    bluebird.all promises
        .then ([user, friendships]) ->
            user.counts = { connections: friendships.length }
            res.json {user}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.editUser = (req, res, next) ->
    req.checkBody('email', 'Valid email required').optional().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').optional().isLength(8)

    # Validate only uploadCare photos
    if req.body.profilePhoto?.type?
        req.checkBody('profilePhoto.type', 'Profile photo type of uploadcare is required').optional().equals('uploadcare')
        req.checkBody('profilePhoto.id', 'Valid profile photo id for type is required').optional().isUUID()
    _errs.handleValidationErrors {req}

    allowedFields = ['email', 'displayName', 'bio', 'profilePhoto']
    photoAllowedFields = ['type', 'id']

    models.getUser req.param('userID')
        .then (user) ->
            # Get only the whitelisted fields and set them on the user object
            newUserFields = _.pick req.body, allowedFields
            if newUserFields.profilePhoto
                newUserFields.profilePhoto = _.pick newUserFields.profilePhoto, photoAllowedFields
                newUserFields.profilePhoto.href = "http://www.ucarecdn.com/#{newUserFields.profilePhoto.id}"

            _.extend user, newUserFields
            user.save()
        .then (user) ->
            user = user.clean {req}
            res.json {user}
        .catch next

exports.requestPasswordReset = (req, res, next) ->
    req.checkBody('email', 'Valid email required').isEmail()
    _errs.handleValidationErrors {req}

    models.getUser req.body.email
        .then (user) ->
            resetObject = {id: user.id}
            resetToken = jwt.sign resetObject, config.SECRET, {expiresInMinutes: config.PW_RESET_DURATION}
            user.pwResetToken = resetToken
            user.save()
        .then (user) ->
            resetUrl = "https://api.getshifts.co/resetPassword?t=#{user.pwResetToken}"
            messageHTML = """
            <p>Hey,</p>

            <p>You may have requested to reset your password. If so, <a href=\"#{resetUrl}\">click this link</a>
                and enter a new password.</p>

            <p>If you haven't, you can safely ignore this email.</p>

            <p>If you have any questions, just reply to this email and we'll do our best to help you out.</p>

            <p>
                Cheers,<br/>
                Sam + Josh
            </p>
            """
            message = {
                html: messageHTML
                subject: "Shifts Password Reset"
                from_email: "hi@getshifts.co"
                from_name: "Shifts"
                to: [{
                    email: user.email
                    name: user.displayName
                }]
                important: true
                track_opens: true
                track_clicks: true
                auto_text: true
                tags: ['shifts-transactional', 'resetpw']
            }

            _chimpSuccess = ([result]) ->
                invalidstatus = ['rejected', 'invalid']
                if result and not result.reject_reason
                    res.json {success: true}
                else
                    console.log 'Could not send password reset email: '
                    console.log result
                    next new _errs.ServerError 'Error sending password reset email'

            _chimpFailure = (err) ->
                console.log err
                throw new _errs.ServerError 'Error sending password reset email'

            mandrillClient.messages.send {message}, _chimpSuccess, _chimpFailure
        .catch (err) ->
            console.log 'caught error :(', err
            _errs.handleRethinkErrors err, next

exports.changePassword = (req, res, next) ->
    req.checkBody('newPassword', 'Password of minimum 8 characters required').notEmpty().isLength(8)

    if req.isAuthenticated
        unless req.param('userID') is req.user.id
            return next new _errs.InvalidPermissions()

        req.checkBody('oldPassword', 'Old password is required').notEmpty()
    else
        req.checkBody('resetToken', 'Reset token is required').notEmpty()

    _errs.handleValidationErrors {req}

    if req.isAuthenticated
        userID = req.param('userID')
    else
        # This will throw an error if token is invalid, and middleware picks that up
        jwt.verify req.body.resetToken, config.SECRET
        userID = jwt.decode(req.body.resetToken).id

    models.getUser userID, {includePassword: true}
        .then (user) ->
            if req.isAuthenticated
                unless auth.checkPassword user, req.body.oldPassword
                    throw new _errs.AuthFailed {password:msg: 'Password is incorrect'}
            else
                # This check probably isnt needed, but it does invalidate previously
                # sent (but not yet expired) tokens
                unless user.pwResetToken and user.pwResetToken is req.body.resetToken
                    throw new _errs.AuthFailed 'Password reset token is incorrect'

            user.setPassword req.body.newPassword
            delete user.pwResetToken
            user.save()
        .then (user) ->
            res.json {success: true}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated
        user: req.user
