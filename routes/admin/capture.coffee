_ = require 'underscore'
bluebird = require 'bluebird'

config = require '../../config'
slack = require '../../slack'
models = require '../../models'
_errs = require '../../errors'
auth = require '../../auth'
r = models.r

mandrill = require 'mandrill-api/mandrill'
mandrillClient = new mandrill.Mandrill config.MANDRILL_API_KEY

_sendNotifications = (adminUser, user, shifts) ->
    messageHTML = """
    <p>Hey #{user.displayName},</p>

    <p>Your Schedule Capture was successful - #{shifts.length} shifts have been added to your Robby profile.</p>

    <p>If you have any questions, just reply to this email and we'll help you out.</p>
    """

    message = {
        html: messageHTML
        subject: "Your new shifts have been added to Robby"
        from_email: "hi@heyrobby.com"
        from_name: "Robby Schedule Capture"
        to: [{
            email: user.email
            name: user.displayName
        }]
        important: true
        track_opens: true
        track_clicks: true
        auto_text: true
        tags: ['shifts-transactional', 'capture-successful']
    }

    slack.sendMessage {text: "#{adminUser.displayName} has added #{shifts.length} for #{user.displayName}'s capture."}

    _chimpSuccess = ([result]) ->
        invalidstatus = ['rejected', 'invalid']
        if not result and result.reject_reason
            console.log 'Could not send welcome email: '
            console.log result

    _chimpFailure = (err) ->
        console.log 'Mailchimp error:'
        console.log err

    mandrillClient.messages.send {message}, _chimpSuccess, _chimpFailure

_cleanCaptures = (captures) ->
    captures.forEach (cap) ->
        cap.owner = cap.owner.clean null, {includeOwnUserFields: true}
        cap.photo = {
            href: "http://www.ucarecdn.com/#{cap.ucImageID}"
            id: cap.ucImageID
            type: 'uploadcare'
        }

    return captures

exports.getPendingCaptures = (req, res, next) ->
    models.Capture
        .filter (row) -> {processed: false}
        .filter r.row('rejected').not()
        .orderBy models.r.asc('created')
        .getJoin()
        .run()
        .then _cleanCaptures
        .then (captures) -> res.json {captures}
        .catch next

exports.getRejectedCaptures = (req, res, next) ->
    models.Capture
        .filter {processed: false, rejected: true}
        .orderBy  models.r.desc('created')
        .getJoin()
        .run()
        .then _cleanCaptures
        .then (captures) -> res.json {captures}
        .catch next

exports.getRecentCaptures = (req, res, next) ->
    models.Capture
        .filter {processed: true}
        .orderBy models.r.desc('created')
        .limit 30
        .getJoin()
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

    if req.body.delete and req.user.traits.admin
        capture.processed = true
        capture.processedBy = req.user.id
        capture.processedDate = new Date()

    if req.body.rejected
        if req.body.owner?.displayName
            captureOwner = "#{req.body.owner?.displayName}'s"
        else
            captureOwner = 'a'

        text = "<!channel>: #{req.user.displayName} has rejected #{captureOwner} capture"
        if capture.rejectedReason
            text += " because '#{capture.rejectedReason}'"

        slack.sendMessage {text}

    capture.id = req.params['captureID']
    models.Capture
        .insert(capture, {conflict: 'update', returnChanges: true})
        .run()
        .then ({changes}) ->
            res.json {capture: changes[0].new_val}
        .catch next

exports.claimCapture = (req, res, next) ->
    captureID = req.params['captureID']

    models.Capture
        .get captureID
        .update {claimedByID: req.user.id}
        .getJoin()
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
        .getJoin()
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
            _sendNotifications req.user, owner, shifts
            models.Capture.get(captureID).update({
                processed: true
                processedBy: req.user.id
                processedDate: new Date()
            }).run()
        .then (result) ->
            res.json {success: true}
        .catch next
