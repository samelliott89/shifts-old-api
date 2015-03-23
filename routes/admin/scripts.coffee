models = require '../../models'
_errs = require '../../errors'
coffeeLib = require 'coffee-script'

module.exports.getAllScripts = (req, res, next) ->
    models.Script
        .run()
        .then (scripts) ->
            res.json {scripts}
        .catch next

module.exports.updateScript = (req, res, next) ->
    req.checkBody('coffeescript', 'A coffee-script body is required').notEmpty()
    _errs.handleValidationErrors {req}

    coffeescript = req.body.coffeescript
    javascript = coffeeLib.compile coffeescript

    script = {
        name: req.params.name
        coffeescript: coffeescript
        javascript: javascript
    }

    models.Script
        .insert(script, {conflict: 'update', returnChanges: true})
        .run()
        .then ({changes}) ->
            res.json {script: changes[0].new_val}