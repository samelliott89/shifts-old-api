_ = require 'underscore'

auth      = require '../auth'

shiftV1   = require './v1/shifts'
userV1    = require './v1/users'
authV1    = require './v1/auth'
searchV1  = require './v1/search'
captureV1 = require './v1/capture'
friendV1  = require './v1/friends'
pagesV1   = require './v1/pages'
_errs     = require '../errors'

createRoutes = (app, prefixes, routes) ->
    exprRoutes = []

    for url, methods of v1Routes
        for prefix in prefixes
            exprRoutes.push(app.route(prefix + url))

        for method, routeFuncs of methods
            if _.isFunction routeFuncs
                routeFuncs = [auth.authRequired, routeFuncs]

            for exprRoute in exprRoutes
                exprRoute[method](routeFuncs...)

perms = {
    currentUser: (func) ->
        return [auth.currentUserRequired, func]
}

v1Routes = {
    '/': {get: userV1.apiIndex}

    '/api/auth/token':
        get:    authV1.refreshToken

    '/users/:userID':
        get:    userV1.getUser
        post:   perms.currentUser userV1.editUser

    '/users/:userID/changePassword':
        post:   userV1.changePassword

    '/users/:userID/friends':
        get:    friendV1.getFriends
        post:   perms.currentUser friendV1.createFriendship
        delete: perms.currentUser friendV1.deleteFriendship

    '/users/:userID/friends/pending':
        get:    perms.currentUser friendV1.getPendingFriendships

    '/users/:userID/feed':
        get:    perms.currentUser shiftV1.getShiftFeed

    '/users/:userID/shifts':
        get:    shiftV1.getShiftsForUser
        post:   perms.currentUser shiftV1.addShifts

    '/shifts/:shiftID':
        get:    shiftV1.getShift
        delete: shiftV1.deleteShift

    '/users/:userID/captures':
        post:   perms.currentUser captureV1.addCapture

    '/search/users':
        get:    searchV1.userSearch
}

module.exports = (app) ->

    createRoutes app, ['/v1', '/api'], v1Routes

    # DEBUG - remove this soon
    app.route('/testErrors/:mode/:error').get(require('./v1/test').throwError)

    # These are outside of v1Routes because they don't require auth
    app.route('/resetPassword').get(pagesV1.resetPassword)
    app.post '/v1/auth/register', authV1.register
    app.post '/v1/auth/login', authV1.login
    app.post '/v1/requestPasswordReset', userV1.requestPasswordReset

    # Legacy - remove these at the end of Feb.
    app.post '/api/auth/register', authV1.register
    app.post '/api/auth/login', authV1.login
    app.post '/api/requestPasswordReset', userV1.requestPasswordReset

    app.use (req, res, next) -> next new _errs.NotFound()