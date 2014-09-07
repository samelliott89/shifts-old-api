auth        = require '../auth'
shiftRoutes = require './shifts'
userRoutes  = require './users'
authRoutes  = require './auth'

module.exports = (app) ->
    app.route '/api/users/:userID'
        .get userRoutes.getUser
        .put userRoutes.editUser

    app.route '/api/users/:userID/shifts'
        .get shiftRoutes.getShifts
        .post shiftRoutes.addShifts
        .put shiftRoutes.bulkEditShifts

    app.route '/api/shifts/:shiftID'
        .get shiftRoutes.getShift
        .put shiftRoutes.editShift

    app.post '/api/auth/register', authRoutes.register
    app.post '/api/auth/login', auth.passport.authenticate('local'), authRoutes.postLogin

    app.use (req, res) -> res.status(404).json error: 'route not found'