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

    scriptName = req.params.name
    coffeescript = req.body.coffeescript
    javascript = coffeeLib.compile coffeescript

    models.Script
        .get scriptName
        .update {coffeescript, javascript}
        .run()
        .then (script) -> res.json {script}
        .catch next
