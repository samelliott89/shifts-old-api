shiftRoutes = require './shifts'
userRoutes = require './users'

module.exports = (app) ->
    app.route '/api/users/:userID'
        .get userRoutes.getUser
        .post userRoutes.editUser

    app.route '/api/users/:userID/shifts'
        .get shiftRoutes.getShiftsForUser
        .post shiftRoutes.addShiftsForUser

    app.route '/api/shifts/:shiftID'
        .get shiftRoutes.getShift
        .post shiftRoutes.editShift

    app.use (req, res) -> res.status(404).json error: 'route not found'