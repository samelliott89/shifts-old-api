_ = require 'underscore'
bluebird = require 'bluebird'

config = require '../../config'
slack = require '../../slack'
models = require '../../models'
_errs = require '../../errors'
auth = require '../../auth'
r = models.r

mandrill = require '../../services/mandrill'

_cleanCaptures = (captures) ->
    captures.forEach (cap) ->
        cap.owner = cap.owner.clean null, {includeOwnUserFields: true}
        cap.photo = {
            href: "http://www.ucarecdn.com/#{cap.ucImageID}"
            id: cap.ucImageID
            type: 'uploadcare'
        }

    return captures

_sendRejectEmail = (capture, reason) ->
    models.getUser capture.ownerID
        .then (owner) ->
            email = {
                template_name: 'dynamic-basic-text'
                message: {
                    subject: 'There was a problem with your schedule capture'
                    to: [{email: owner.email, name: owner.displayName }]
                }
            }

            imgLink = "http://www.ucarecdn.com/#{capture.ucImageID}/-/preview/1000x1000/-/progressive/yes/"

            mandrill.sendEmail email, {
                heading: "Your recent schedule capture was not imported"
                paragraphs: [
                    "Just letting you know that Atum was unable to find any valid shifts in your <a href=\"#{imgLink}\">recent schedule capture</a>: #{reason}"
                    'If you believe this is a mistake, or have any questions, just reply to this email or contact us at hi@getatum.com'
                ]
            }

_sendRejectSlackMessage = ({req, willSendEmail}) ->
    attachment = {fields: []}

    if req.body.rejectedReason.length > 2
        attachment.fields.push {
            title: 'Internal reject reason'
            value: req.body.rejectedReason
            short: true
        }

    if willSendEmail
        attachment.fields.push {
            title: 'Reject email'
            value: req.body.rejectedEmail
            short: true
        }

    text = ''

    if not req.user.traits.admin
        text += '<!channel>: '

    text += "#{req.user.displayName} has rejected "

    if req.body.delete
        text += 'and deleted '

    if req.body.owner?.displayName
        text += "#{req.body.owner?.displayName}'s "
    else
        text += 'a '

    text += 'capture '

    if willSendEmail
        text += 'with a rejection email'

    slack.sendMessage {
        text: text
        attachments: [attachment]
        channel: slack.REJECT_CHANNEL
    }

exports.getPendingCaptures = (req, res, next) ->
    models.Capture
        .filter (row) -> {processed: false}
        .filter r.row('rejected').not()
        .orderBy models.r.asc('created')
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then _cleanCaptures
        .then (captures) -> res.json {captures}
        .catch next

exports.getRejectedCaptures = (req, res, next) ->
    models.Capture
        .filter {processed: false, rejected: true}
        .orderBy  models.r.desc('created')
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then _cleanCaptures
        .then (captures) -> res.json {captures}
        .catch next

exports.getRecentCaptures = (req, res, next) ->
    models.Capture
        .filter {processed: true}
        .orderBy models.r.desc('created')
        .limit 30
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then _cleanCaptures
        .then (captures) -> res.json {captures}
        .catch next

exports.updateCapture = (req, res, next) ->
    whitelistedFields = [
        'rejected'
        'rejectedReason'
    ]

    capture = _.pick req.body, whitelistedFields
    willSendEmail = req.body.rejectedEmail?.length > 2

    if req.body.delete and req.user.traits.admin
        capture.processed = true
        capture.processedByID = req.user.id # here
        capture.processedDate = new Date()

    if req.body.rejected
        _sendRejectSlackMessage {req, willSendEmail}

    capture.id = req.params['captureID']
    models.Capture
        .get capture.id
        .update capture
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then (newCapture) ->
            res.json {capture: newCapture}

            if willSendEmail
                _sendRejectEmail newCapture, req.body.rejectedEmail
        .catch next

exports.claimCapture = (req, res, next) ->
    captureID = req.params['captureID']

    models.Capture
        .get captureID
        .update {claimedByID: req.user.id}
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then (capture) ->
            res.json {capture}
        .catch next


exports.addCaptureShifts = (req, res, next) ->
    shifts = null
    owner = null

    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()
    _errs.handleValidationErrors {req}

    captureID = req.params['captureID']

    models.Capture
        .get captureID
        .getJoin({owner: true, processedBy: true, claimedBy: true})
        .run()
        .then (capture) ->
            owner = capture.owner
            processed = capture.processed

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

            email = {
                template_name: 'dynamic-basic-text'
                message: {
                    subject: 'Your new shifts have been added to Atum'
                    to: [{email: owner.email, name: owner.displayName }]
                }
            }

            shiftWord = if shifts.length is 1 then 'shift has' else 'shifts have'

            mandrill.sendEmail email, {
                heading: "Your Schedule Capture was successful"
                paragraphs: [
                    "Awesome! <b>#{shifts.length} #{shiftWord} been added to your Atum profile.</b>"
                    "If you have any questions, just reply to this email (or email us at hi@getatum.com) and we'll sort you out."
                    " "
                ]
            }

            slack.sendMessage {text: "#{req.user.displayName} has added #{shifts.length} for #{owner.displayName}'s capture."}

            models.Capture.get(captureID).update({
                processed: true
                processedByID: req.user.id # here
                processedDate: new Date()
            }).run()
        .then (result) ->
            res.json {success: true}
        .catch next
