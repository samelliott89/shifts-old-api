auth        = require '../auth'
shiftRoutes = require './shifts'
userRoutes  = require './users'
authRoutes  = require './auth'

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

    app.post '/api/auth/register', authRoutes.register
    app.post '/api/auth/login', auth.passport.authenticate('local'), authRoutes.postLogin

    app.use (req, res) -> res.status(404).json error: 'route not found'