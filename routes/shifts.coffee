_ = require 'underscore'
q = require 'q'

auth = require '../auth'
models = require '../models'
errors = require '../errors'

VALID_SHIFT_FIELDS = ['start', 'end', 'title']

getCurrentUsersShift = (req) ->
    dfd = q.defer()
    shiftID = req.param 'shiftID'
    currentUserID = req.user?.id

    models.getShift shiftID
        .then (shift) ->
            if shift.owner.id isnt currentUserID
                return dfd.reject new errors.InvalidPermissions()
            dfd.resolve shift
        .catch (err) ->
            dfd.reject err

    return dfd.promise

exports.getShiftsForUser = (req, res) ->
    userID = req.param 'userID'

    models.getShiftsForUser userID
        .then (shifts) ->
            res.json {shifts}

exports.addShifts = (req, res) ->
    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()

    validationErrors = req.validationErrors(true)
    return res.status(400).json {errors: validationErrors}  if validationErrors

    rawShifts = req.body.shifts

    shifts = req.body.shifts.map (shift) ->
        # Only include whitelisted fields
        shift = _.pick shift, VALID_SHIFT_FIELDS

        shift.start = new Date shift.start
        shift.end = new Date shift.end

        shift = new models.Shift shift

        # req.user isnt a 'proper' User object, so we assign the relationship
        # the 'manual' way. models.Shift.filter().joinAll() will still work.
        shift.ownerID = req.user.id
        return shift

    models.Shift.save shifts
        .done (result) -> res.json {cool: 'Successfully created shifts!'}

exports.getShift = (req, res, next) ->
    getCurrentUsersShift req
        .then (shift) ->
            res.json {shift}
        .catch next

exports.editShift = (req, res, next) ->
    getCurrentUsersShift req
        .then (shift) ->
            newShift = _.pick req.body, VALID_SHIFT_FIELDS
            _.extend shift, newShift
            shift.save()
            res.json {shift}
        .catch next

exports.bulkEditShifts = (req, res) ->
    res.json {page: 'bulkEditShifts'}

exports.deleteShift = (req, res, next) ->
    shiftID = req.param 'shiftID'

    getCurrentUsersShift req
        .then (shift) -> models.deleteShift shiftID
        .then -> res.status(204).end()
        .catch next
