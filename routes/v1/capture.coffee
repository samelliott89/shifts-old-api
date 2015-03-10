models = require '../../models'

exports.addCapture = (req, res, next) ->

    capture = new models.Capture
        ownerID: req.user.id
        ucImageID: req.body.ucImageID
        tzOffset: req.body.tzOffset
        processed: false
        created: new Date()

    models.Capture.save capture
        .then (result) -> res.json {success: true}
        .catch next