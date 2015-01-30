_ = require 'underscore'

models = require '../../models'
_errs = require '../../errors'

exports.getSettings = (req, res, next) ->
    userID = req.params.userID

    models.Settings.filter({ownerID: userID}).run()
        .then ([settings]) ->
            settings ?= models.defaultSettings
            delete settings.ownerID
            res.json {settings}
        .catch next

exports.updateSettings = (req, res, next) ->
    settings = _.pick req.body, models.validSettings
    userID = req.params.userID
    settings.ownerID = userID

    models.Settings
        .insert settings, {returnChanges: true, conflict: 'update'}
        .run()
        .then ({changes}) ->
            changes = changes[0]
            settings = _.extend {}, models.defaultSettings, changes.new_val
            delete settings.ownerID

            res.json {settings}
        .catch next