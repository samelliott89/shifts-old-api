models = require '../../models'

exports.addCapture = (req, res, next) ->

    capture = new models.Capture
        ownerID: req.user.id
        ucImageID: req.body.ucImageID
        tzName: req.body.tzName
        processed: false
        created: new Date()

    models.Capture.save capture
        .then (result) -> res.json {capture: capture}
        .catch next