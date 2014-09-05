exports.getShiftsForUser = (req, res) ->
    res.json {page: 'getShiftsForUser'}

exports.addShiftsForUser = (req, res) ->
    res.json {page: 'addShiftsForUser'}

exports.getShift = (req, res) ->
    res.json {page: 'getShift'}

exports.editShift = (req, res) ->
    res.json {page: 'editShift'}
