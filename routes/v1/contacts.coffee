models = require '../../models'
_ = require 'underscore'


exports.checkContacts = (req, res, next) ->
    emails = req.body.emails
    #emails = ["prabhu.saitu@gmail.com", "robin.r@gmail.com"]
    models.getAllUsersByEmails(emails)
        .then((users) ->
            _.map users, models.cleanUser
            res.json users
        )
