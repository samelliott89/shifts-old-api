auth        = require '../auth'
shiftRoutes = require './shifts'
userRoutes  = require './users'
authRoutes  = require './auth'
searchRoutes  = require './search'
captureRoutes  = require './capture'
_errs = require '../errors'

module.exports = (app) ->
    app.route '/api'
        .get userRoutes.apiIndex

    app.route '/api/users/:userID'
        .get userRoutes.getUser
        .put auth.currentUserRequired, userRoutes.editUser

    app.route '/api/users/:userID/shifts'
        .get    auth.currentUserRequired, shiftRoutes.getShiftsForUser
        .post   auth.currentUserRequired, shiftRoutes.addShifts
        .put    auth.currentUserRequired, shiftRoutes.bulkEditShifts

    app.route '/api/shifts/:shiftID'
        .get    auth.authRequired, shiftRoutes.getShift
        .put    auth.authRequired, shiftRoutes.editShift
        .delete auth.authRequired, shiftRoutes.deleteShift

    app.route '/api/users/:userID/captures'
        .post   auth.currentUserRequired, captureRoutes.addCapture

    app.route '/api/search/users'
        .get    searchRoutes.userSearch

    app.post '/api/auth/register', authRoutes.register
    app.post '/api/auth/login', authRoutes.login
    app.get '/api/auth/token', auth.authRequired, authRoutes.refreshToken
    app.get '/api/auth/logout', authRoutes.logout

    app.use (req, res) -> res.status(404).json error: 'route not found'