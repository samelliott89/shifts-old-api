auth        = require '../auth'
shiftRoutes = require './shifts'
userRoutes  = require './users'
authRoutes  = require './auth'

module.exports = (app) ->
    app.route '/api'
        .get userRoutes.apiIndex

    app.route '/api/users/:userID'
        .get userRoutes.getUser
        .put auth.currentUserRequired, userRoutes.editUser

    app.route '/api/users/:userID/shifts'
        .get    shiftRoutes.getShifts
        .post   auth.currentUserRequired, shiftRoutes.addShifts
        .put    auth.currentUserRequired, shiftRoutes.bulkEditShifts
        .delete auth.currentUserRequired, shiftRoutes.deleteShift

    app.route '/api/shifts/:shiftID'
        .get shiftRoutes.getShift
        .put shiftRoutes.editShift

    app.post '/api/auth/register', authRoutes.register
    app.post '/api/auth/login', authRoutes.login
    app.get '/api/auth/logout', authRoutes.logout

    app.use (req, res) -> res.status(404).json error: 'route not found'