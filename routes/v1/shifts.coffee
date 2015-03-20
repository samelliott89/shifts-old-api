_ = require 'underscore'
moment = require 'moment-timezone'
Promise = require 'bluebird'
q = require 'q'

auth = require '../../auth'
models = require '../../models'
_errs = require '../../errors'
analytics = require '../../analytics'

VALID_SHIFT_FIELDS = ['start', 'end', 'title']

getCurrentUsersShift = (req) ->
    dfd = q.defer()
    shiftID = req.param 'shiftID'
    currentUserID = req.user?.id

    models.getShift shiftID
        .then (shift) ->
            if shift.owner.id isnt currentUserID
                return dfd.reject new _errs.InvalidPermissions()
            dfd.resolve shift
        .catch (err) ->
            dfd.reject err

    return dfd.promise

exports.getShiftFeed = (req, res, next) ->
    analytics.track req, 'View Shift Feed'

    models.getShiftsForUserAndCoworkers req.user.id
        .then ({shifts, users}) ->
            users = _.filter users, (user) -> user.id isnt req.user.id
            res.json {shifts, users}
        .catch next

exports.getShiftsForUser = (req, res, next) ->
    userID = req.param 'userID'

    shiftsSince = undefined
    if req.query['shiftsSince']
        shiftsSince = new Date(req.query['shiftsSince'])

    models.getShiftsForUser userID, {req, shiftsSince}
        .then (shifts) ->
            res.json {shifts}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.addShifts = (req, res, next) ->
    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()
    _errs.handleValidationErrors {req}

    _eventEdit = false
    _eventAdd = false

    checkPermissions = Promise.resolve []
    shiftIDsToEdit = _.pluck req.body.shifts, 'id'
        .filter (id) -> id isnt undefined

    if shiftIDsToEdit.length
        # Possibly editing
        checkPermissions = models.Shift
            .getAll(shiftIDsToEdit...)
            .filter {ownerID: req.user.id}
            .run()

    shifts = req.body.shifts.map (_shift) ->
        # Only include whitelisted fields
        shift = _.pick _shift, VALID_SHIFT_FIELDS
        shift = new models.Shift shift

        shift.start = new Date shift.start
        shift.end = new Date shift.end

        if _shift.id
            shift.id = _shift.id
            shift.updated = new Date()
            _eventEdit = true
        else
            shift.created = new Date()
            _eventAdd = true

        shift.ownerID = req.user.id
        return shift

    checkPermissions
        .then (result) ->
            unless result.length is shiftIDsToEdit.length
                return Promise.reject new _errs.InvalidPermissions 'Authentication provided invalid permissions to edit these shifts'

            models.Shift.insert(shifts, {conflict: 'update'}).run()
        .then (result) ->

            if _eventEdit
                analytics.track req, 'Edit Shift'

            if _eventAdd
                analytics.track req, 'Add Schedule', {method: 'manual', shiftCount: shifts.length}

            res.json {success: true}
        .catch next

exports.getShift = (req, res, next) ->
    getCurrentUsersShift req
        .then (shift) ->
            res.json {shift}
        .catch (err) ->
            _errs.handleRethinkErrors err, next

exports.deleteShift = (req, res, next) ->
    shiftID = req.param 'shiftID'

    getCurrentUsersShift req
        .then (shift) -> models.deleteShift shiftID
        .then ->
            analytics.track req, 'Delete Shift'
            res.json({success: true}).end()
        .catch (err) ->
            _errs.handleRethinkErrors err, next
