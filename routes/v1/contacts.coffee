models = require '../../models'



exports.checkContacts = (req, res, next) ->
    usersFound = []
    emails = req.body.emails
    console.log 'Emails: ' + emails
    for email in emails
        models.getUser(email)
        .then (user) ->
            usersFound.push(user)
            console.log 'Found Users - ' + usersFound
            res.json { contacts: usersFound } 
        