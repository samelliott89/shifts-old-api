models = require '../../models'

module.exports.hotfix = (req, res, next) ->

    models.getScript 'hotfix'
        .then (script) ->
            res.set 'Content-Type', 'text/javascript'
            res.send script.javascript
        .catch next