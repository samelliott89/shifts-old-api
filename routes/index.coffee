auth      = require '../auth'

shiftV1   = require './v1/shifts'
userV1    = require './v1/users'
authV1    = require './v1/auth'
searchV1  = require './v1/search'
captureV1 = require './v1/capture'
friendV1  = require './v1/friends'
pagesV1   = require './v1/pages'
_errs     = require '../errors'

module.exports = (app) ->
    app.route('/resetPassword').get(pagesV1.resetPassword)

    app.route '/api'
        .get userV1.apiIndex

    app.route '/api/users/:userID'
        .get userV1.getUser
        .post auth.currentUserRequired, userV1.editUser

    app.route '/api/requestPasswordReset'
        .post userV1.requestPasswordReset

    app.route '/api/users/:userID/changePassword'
        .post userV1.changePassword

    app.route '/api/users/:userID/friends'
        .get auth.authRequired, friendV1.getFriends # Friendship is checked in controller
        .post auth.currentUserRequired, friendV1.createFriendship
        .delete auth.currentUserRequired, friendV1.deleteFriendship

    app.route '/api/users/:userID/friends/pending'
        .get auth.currentUserRequired, friendV1.getPendingFriendships

    app.route '/api/users/:userID/feed'
        .get auth.currentUserRequired, shiftV1.getShiftFeed

    app.route '/api/users/:userID/shifts'
        .get    auth.authRequired, shiftV1.getShiftsForUser
        .post   auth.currentUserRequired, shiftV1.addShifts

    app.route '/api/shifts/:shiftID'
        .get    auth.authRequired, shiftV1.getShift
        .delete auth.authRequired, shiftV1.deleteShift

    app.route '/api/users/:userID/captures'
        .post   auth.currentUserRequired, captureV1.addCapture

    app.route '/api/search/users'
        .get    searchV1.userSearch

    app.post '/api/auth/register', authV1.register
    app.post '/api/auth/login', authV1.login
    app.get '/api/auth/token', auth.authRequired, authV1.refreshToken

    app.use (req, res, next) -> next new _errs.NotFound()