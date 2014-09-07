models  = require '../models'
helpers = require './helpers'

exports.getUser = (req, res) ->
    userID = req.param 'userID'
    models.getUser userID
        .then (user) -> res.json {user}
        .catch helpers.errorHandler req, res

exports.editUser = (req, res) ->
    res.json {page: 'editUser'}

exports.apiIndex = (req, res) ->
    res.json
        message: 'Shifts API'
        isAuthenticated: req.isAuthenticated()
        user: req.user