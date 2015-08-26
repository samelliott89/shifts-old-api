_ = require 'underscore'

models = require '../../models'
_errs = require '../../errors'
analytics = require '../../analytics'
pushService = require '../../services/pushNotifications'

exports.getSettings = (req, res, next) ->
    userID = req.params.userID

    models.Settings.filter({ownerID: userID}).run()
        .then ([settings]) ->
            settings ?= {}
            settings = _.defaults settings, models.defaultSettings
            delete settings.ownerID
            res.json {settings}
        .catch next

exports.updateSettings = (req, res, next) ->
    settings = _.pick req.body, models.validSettings
    userID = req.params.userID
    settings.ownerID = userID
    console.log "Device Type - " + settings.deviceType + " Device ID - " + settings.deviceID;
    pushService.setup(settings.deviceType, settings.deviceID)

    models.Settings
        .insert settings, {returnChanges: true, conflict: 'update'}
        .run()
        .then ({changes}) ->
            changes = changes[0]
            console.log "Changes: ", changes
            settings = _.extend {}, models.defaultSettings, changes.new_val
            delete settings.ownerID


            analytics.track req, 'Update Settings'

            res.json {settings}
        .catch next
