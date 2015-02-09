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

exports.listDebugs = (req, res, next) ->
    models.DebugDump
        .run()
        .then (dumps) ->
            dumps = _.map dumps, (dump) ->
                {
                    id: dump.id
                    created: dump.created
                    href: dump.location?.href
                    identifier: dump.identifier
                }
            res.json {dumps}
        .catch next

exports.getDebugHtml = (req, res, next) ->
    models.DebugDump
        .get req.params['id']
        .run()
        .then (dump) ->
            res.send(dump.pageHtml or '<pre>pageHtml is undefined</pre>')
        .catch next