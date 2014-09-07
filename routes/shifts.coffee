_ = require 'underscore'

models = require '../models'

exports.getShifts = (req, res) ->
    res.json {page: 'getShifts'}

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
        shift = new models.Shift shift
        shift.owner = req.user
        return shift

    models.Shift.save shifts
        .then (result) -> res.json {cool: 'Successfully created shifts!'}
        .catch (err)   -> res.json {Error: 'Error creating shifts', err}

exports.getShift = (req, res) ->
    res.json {page: 'getShift'}

exports.editShift = (req, res) ->
    res.json {page: 'editShift'}

exports.bulkEditShifts = (req, res) ->
    res.josn {page: 'bulkEditShifts'}