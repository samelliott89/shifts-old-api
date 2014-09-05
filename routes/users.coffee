models  = require '../models'
helpers = require './helpers'

exports.getUser = (req, res) ->
    userID = req.param 'userID'
    models.getUser userID
        .then (user) -> res.json {user}
        .catch helpers.errorHandler req, res

exports.editUser = (req, res) ->
    res.json {page: 'editUser'}
