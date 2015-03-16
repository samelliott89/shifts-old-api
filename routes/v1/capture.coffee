models = require '../../models'
analytics = require '../../analytics'

exports.addCapture = (req, res, next) ->

    capture = new models.Capture
        ownerID: req.user.id
        ucImageID: req.body.ucImageID
        tzName: req.body.tzName
        processed: false
        created: new Date()

    models.Capture.save capture
        .then (result) ->
            analytics.track req, 'Roster Capture'
            res.json {capture: capture}
        .catch next
