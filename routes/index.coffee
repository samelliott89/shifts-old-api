auth        = require '../auth'
shiftRoutes = require './shifts'
userRoutes  = require './users'
authRoutes  = require './auth'

module.exports = (app) ->
    app.route '/api'
        .get userRoutes.apiIndex

    app.route '/api/users/:userID'
        .get userRoutes.getUser
        .put userRoutes.editUser

    app.route '/api/users/:userID/shifts'
        .get shiftRoutes.getShifts
        .post auth.currentUserRequired, shiftRoutes.addShifts
        .put auth.currentUserRequired, shiftRoutes.bulkEditShifts

    app.route '/api/shifts/:shiftID'
        .get shiftRoutes.getShift
        .put shiftRoutes.editShift

    app.post '/api/auth/register', authRoutes.register
    app.post '/api/auth/login', authRoutes.login

    app.use (req, res) -> res.status(404).json error: 'route not found'