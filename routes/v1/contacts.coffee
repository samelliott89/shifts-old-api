models = require '../../models'
_ = require 'underscore'
_errs = require '../../errors'


exports.checkContacts = (req, res, next) ->
    req.checkBody('emails', 'Array of emails must be supplied').isArray()
    _errs.handleValidationErrors {req}

    emails = req.body.emails
    models.getAllUsersByEmails emails
        .then (users) ->
            res.json {users}
        .catch next