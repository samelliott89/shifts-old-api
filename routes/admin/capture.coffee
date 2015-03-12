_ = require 'underscore'
bluebird = require 'bluebird'

models = require '../../models'
_errs = require '../../errors'
r = models.r

exports.listRosterCaptures = (req, res, next) ->
    models.Capture
        .filter {processed: false}
        .orderBy 'rejected', models.r.asc('created')
        .getJoin()
        .run()
        .then (captures) ->
            captures.forEach (cap) ->
                cap.owner = models.cleanUser cap.owner, req
                cap.photo = {
                    href: "http://www.ucarecdn.com/#{cap.ucImageID}"
                    id: cap.ucImageID
                    type: 'uploadcare'
                }
            res.json {captures}
        .catch next

exports.updateCapture = (req, res, next) ->
    whitelistedFields = [
        'rejected'
        'rejectedReason'
    ]

    capture = _.pick req.body, whitelistedFields
    capture.id = req.params['captureID']
    models.Capture
        .insert(capture, {conflict: 'update', returnChanges: true})
        .run()
        .then ({changes}) ->
            console.log changes
            res.json {capture: changes[0].new_val}
        .catch next

exports.addCaptureShifts = (req, res, next) ->
    console.log 'Recieved addCaptureShifts'

    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()
    _errs.handleValidationErrors {req}

    captureID = req.params['captureID']

    models.Capture
        .get captureID
        .getJoin()
        .run()
        .then ({owner, processed}) ->
            if processed
                throw new _errs.BadRequest 'The requested capture has already been processed'
                return

            shifts = _.map req.body.shifts, (shift) ->
                {
                    start: new Date(shift.start)
                    end: new Date(shift.end)
                    ownerID: owner.id
                    created: new Date()
                    source: models.SHIFT_SOURCE_CAPTURE
                    captureID: captureID
                }

            models.Shift.insert(shifts).run()
        .then (result) ->
            models.Capture.get(captureID).update({processed: true}).run()
        .then (result) ->
            res.json {success: true}
        .catch next
