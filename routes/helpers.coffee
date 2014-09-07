modelHelpers = require '../models/helpers'

exports.errorHandler = (req, res) -> (err) ->
    if modelHelpers.notFound err
        res.status(404).json {'error': 'User not found'}
    else
        res.status(500).json {'error': 'Unknown error occured'}