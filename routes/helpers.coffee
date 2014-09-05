helpers = require '../models/helpers'

exports.errorHandler = (req, res) -> (err) ->
    console.log err
    if helpers.notFound err
        res.status(404).json {'error': 'User not found'}
    else
        res.status(500).json {'error': 'Unknown error occured'}