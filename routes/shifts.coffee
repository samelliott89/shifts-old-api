_ = require 'underscore'

models = require '../models'

exports.getShifts = (req, res) ->
    userID = req.param 'userID'

    models.getShiftsForUser userID
        .then (shifts) ->
            res.json {shifts}
        .catch (err) ->
            res.status(500).json {error: err.toString()}

exports.addShifts = (req, res) ->
    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()

    errors = req.validationErrors(true)
    return res.status(400).json {errors}  if errors

    rawShifts = req.body.shifts
    onlyFields = ['start', 'end', 'title']

    shifts = req.body.shifts.map (shift) ->
        # Only include whitelisted fields
        shift = _.pick shift, onlyFields

        shift.start = new Date shift.start
        shift.end = new Date shift.end

        shift = new models.Shift shift

        # req.user isnt a 'proper' User object, so we assign the relationship
        # the 'manual' way. models.Shift.filter().joinAll() will still work.
        shift.ownerID = req.user.id
        return shift

    models.Shift.save shifts
        .then (result) -> res.json {cool: 'Successfully created shifts!'}
        .catch (err)   -> res.json {Error: 'Error creating shifts', err}

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