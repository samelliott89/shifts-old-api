_ = require 'underscore'
models = require '../../models'

exports.debug = (req, res, next) ->
    {debugData} = req.body
    debugData = _.omit debugData, 'id'
    debugData.created = new Date()

    obj = new models.DebugDump(debugData)
    obj.save()
        .then ->
            res.json {'success': true}
        .catch next
