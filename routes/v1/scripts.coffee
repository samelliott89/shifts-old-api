models = require '../../models'

module.exports.hotfix = (req, res, next) ->
    console.log 'hotfix!'
    models.Script
        .get('hotfix')
        .run()
        .then (script) ->
            res.set 'Content-Type', 'text/javascript'
            res.send script.javascript
        .catch next