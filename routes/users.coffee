_ = require 'underscore'
bluebird = require 'bluebird'

models  = require '../models'
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

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated
        user: req.user
