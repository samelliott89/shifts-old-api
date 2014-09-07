exports.getShifts = (req, res) ->
    res.json {page: 'getShifts'}

exports.addShifts = (req, res) ->
    res.json {page: 'addShifts'}

exports.getShift = (req, res) ->
    res.json {page: 'getShift'}

exports.editShift = (req, res) ->
    res.json {page: 'editShift'}

exports.bulkEditShifts = (req, res) ->
    res.josn {page: 'bulkEditShifts'}