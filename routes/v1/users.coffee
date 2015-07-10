_ = require 'underscore'
bluebird = require 'bluebird'
jwt = require 'jsonwebtoken'
mandrill = require '../../services/mandrill'

auth = require '../../auth'
config = require '../../config'
models = require '../../models'
_errs = require '../../errors'
analytics = require '../../analytics'

exports.getUser = (req, res, next) ->
    userID = req.param 'userID'
    promises = [
        models.getUser userID, {req, clean: true}
        models.getFriends userID
        models.getShiftsForUser userID, {req, throwOnInvalidPermission: false}
    ]

    bluebird.all promises
        .then ([user, friendships, shifts]) ->
            user.counts = {
                connections: friendships.length
                shifts: shifts.length
            }
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

    allowedFields = ['email', 'displayName', 'bio', 'profilePhoto', 'phone']
    photoAllowedFields = ['type', 'id']

    models.getUser req.param('userID')
        .then (user) ->
            # Get only the whitelisted fields and set them on the user object
            newUserFields = _.pick req.body, allowedFields
            if newUserFields.profilePhoto
                newUserFields.profilePhoto = _.pick newUserFields.profilePhoto, photoAllowedFields
                newUserFields.profilePhoto.href = "https://www.ucarecdn.com/#{newUserFields.profilePhoto.id}"

            if req.body.changedDisplayName
                newUserFields.defaultDisplayNameSet = false

            _.extend user, newUserFields
            user.save()
        .then (user) ->
            user = user.clean {req}
            analytics.track req, 'Update User'
            res.json {user}
        .catch next

exports.requestPhoneNumber = (req, res, next) ->

    user = req.user
    models.getUser req.params.userID
        .then (userReceiving) ->
            email =
                template_name: 'dynamic-basic-text'
                message:
                    subject: "Phone Number Request from #{user.displayName}"
                    to: [{email: userReceiving.email, name: userReceiving.displayName }]

            mandrill.sendEmail email, {
                heading: "Phone number request from #{user.displayName}"
                paragraphs: [
                    "Hey #{userReceiving.displayName},"
                    "#{user.displayName} would like you to add your mobile number to Atum."
                    "This will make it easy for #{user.displayName} to contact you if they want to swap a shift or oganise to do something on your day off together."
                    "You can add your mobile number from your Profile by tapping on 'Edit Profile' and going to 'Number'."
                ]
            }

        .then (mandrilResp) ->
            res.json {success: true}
            analytics.track req, 'Request Phone Number'

        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.requestSchedule = (req, res, next) ->

    user = req.user
    models.getUser req.params.userID
        .then (userReceiving) ->
            email =
                template_name: 'dynamic-basic-text'
                message:
                    subject: "Schedule Request from #{user.displayName}"
                    to: [{email: userReceiving.email, name: userReceiving.displayName }]

            mandrill.sendEmail email, {
                heading: "Schedule request from #{user.displayName}"
                paragraphs: [
                    "Hey #{userReceiving.displayName},"
                    "#{user.displayName} would like you to add your schedule to Atum."
                    "This will make it easy for the both of you to swap shifts and organise things to do on your days off."
                ]
            }

        .then (mandrilResp) ->
            res.json {success: true}
            analytics.track req, 'Request Schedule'

        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.requestPasswordReset = (req, res, next) ->
    req.checkBody('email', 'Valid email required').isEmail()
    _errs.handleValidationErrors {req}

    models.getUser req.body.email
        .then (user) ->
            resetObject = {id: user.id}
            resetToken = jwt.sign resetObject, config.SECRET, {expiresInMinutes: config.PW_RESET_DURATION}
            user.pwResetToken = resetToken
            analytics.track {user:id: user.id}, 'Reset Password'
            user.save()
        .then (user) ->
            resetUrl = "https://api.getshifts.co/resetPassword?t=#{user.pwResetToken}"
            email =
                template_name: 'dynamic-basic-text'
                message:
                    subject: 'Atum Password Reset'
                    to: [{email: user.email, name: user.displayName }]

            mandrill.sendEmail email, {
                heading: "Atum Password Reset"
                paragraphs: [
                    "Hi #{user.displayName}"
                    "You may have requested to reset your password. If so, <a href=\"#{resetUrl}\">click this link</a> and enter a new password."
                    "If you haven't, you can safely ignore this email."
                    "If you have any questions, just reply to this email and we'll do our best to help you out."
                    "Team Atum"
                ]
            }

        .then (mandrilResp) ->
            res.json {success: true}

        .catch (err) ->
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
                    throw new _errs.AuthFailed {password:msg: 'Old password is incorrect'}
            else
                # This check probably isnt needed, but it does invalidate previously
                # sent (but not yet expired) tokens
                unless user.pwResetToken and user.pwResetToken is req.body.resetToken
                    throw new _errs.AuthFailed 'Password reset token is incorrect'

            user.setPassword req.body.newPassword
            delete user.pwResetToken
            user.save()
        .then (user) ->
            analytics.track req, 'Update Password'
            res.json {success: true}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.apiIndex = (req, res, next) ->
    _respond = (links) ->
        res.json {
            message: 'Shifts API'
            isAuthenticated: req.isAuthenticated
            user: req.user
            links: links
        }

    models.getLinksForType 'sidemenu'
        .then (links) -> _respond(links)
        .catch (err)  ->
            console.log err
            _respond()