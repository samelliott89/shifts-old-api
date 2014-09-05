models = require '../models'

exports.getUser = (req, res) ->
    models.User.get(req.param('userID')).getJoin().run()
        .then (user) -> res.json {user}

exports.editUser = (req, res) ->
    res.json {page: 'editUser'}
