_ = require 'underscore'
models = require '../../models'

bmRegex = /(src=\"https:\/\/s3-ap-southeast-2.amazonaws.com\/pages.getshifts.co\/debugBookmarklet.js\?r=[\d.]*\")/g
linkRegex = /(src|href)=(['"])\//g

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
                    location: dump.location
                    identifier: dump.identifier
                }
            res.json {dumps}
        .catch next

exports.getDebugHtml = (req, res, next) ->
    models.DebugDump
        .get req.params['id']
        .run()
        .then (dump) ->
            html = dump.pageHtml or '<pre>pageHtml is undefined</pre>'

            if req.query['clean']
                console.log 'Cleaning'
                html = html.replace bmRegex, 'replaced'
                urlPrefix = dump.location.protocol + '//' + dump.location.host + '/'
                html = html.replace linkRegex, "$1=$2#{urlPrefix}"

            res.send html
        .catch next