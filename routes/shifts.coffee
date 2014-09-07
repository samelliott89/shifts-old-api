exports.getShifts = (req, res) ->
    res.json {page: 'getShifts'}

exports.addShifts = (req, res) ->
    req.checkBody('shifts', 'Shifts must be an array').isArray()
    req.checkBody('shifts', 'Shifts must have valid a start date').shiftsHaveStartDate()
    req.checkBody('shifts', 'Shifts must have valid a end date').shiftsHaveEndDate()
    req.checkBody('shifts', 'Shifts must end after they begin').shiftsEndIsAfterStart()

    errors = req.validationErrors(true)
    return res.status(400).json {errors}  if errors

    shifts = req.body.shifts

    res.json {page: 'addShifts', shifts}

exports.getShift = (req, res) ->
    res.json {page: 'getShift'}

exports.editShift = (req, res) ->
    res.json {page: 'editShift'}

exports.bulkEditShifts = (req, res) ->
    res.josn {page: 'bulkEditShifts'}