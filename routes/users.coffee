_ = require 'underscore'
bluebird = require 'bluebird'
jwt = require 'jsonwebtoken'

config = require '../config'
models = require '../models'
_errs = require '../errors'

exports.getUser = (req, res, next) ->
    userID = req.param 'userID'
    models.getUser userID, {req, clean: true}
        .then (user) ->
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
            console.log 'Generated reset token:', resetToken
            user.pwResetToken = resetToken
            user.save()
        .then (user) ->
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
            res.json {status: 'success'}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated
        user: req.user
