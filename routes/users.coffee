models = require '../models'

exports.getUser = (req, res) ->
    models.User.get(req.param('userID')).getJoin().run()
        .then (user) -> res.json {user}
        .catch (error) ->
            console.log error
            res.status(400).json {error: 'unexpected error occured', more: error}

exports.editUser = (req, res) ->
    res.json {page: 'editUser'}
