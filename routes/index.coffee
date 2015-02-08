_ = require 'underscore'

auth      = require '../auth'
_errs      = require '../errors'

authV1     = require './v1/auth'
userV1     = require './v1/users'
pagesV1    = require './v1/pages'
shiftV1    = require './v1/shifts'
searchV1   = require './v1/search'
friendV1   = require './v1/friends'
captureV1  = require './v1/capture'
settingsV1 = require './v1/settings'

admin = require './admin'

createRoutes = (app, routes, {prefixes, middleware}) ->
    exprRoutes = []
    prefixes ?= ['']

    for url, methods of routes
        for prefix in prefixes
            combinedUrl = prefix + url
            exprRoutes.push(app.route(combinedUrl))

        for method, routeFuncs of methods
            if _.isFunction routeFuncs
                routeFuncs = [middleware..., routeFuncs]

            for exprRoute in exprRoutes
                exprRoute[method](routeFuncs...)

perms = {
    currentUser: (func) ->
        return [auth.currentUserRequired, func]
}

v1Routes = {
    '/': {get: userV1.apiIndex}

    '/auth/token':
        get:    authV1.refreshToken

    '/users/:userID':
        get:    userV1.getUser
        post:   perms.currentUser userV1.editUser

    '/users/:userID/settings':
        get:    perms.currentUser settingsV1.getSettings
        post:   perms.currentUser settingsV1.updateSettings

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

adminRoutes = {
    '/get': {get: admin.get}
}

module.exports = (app) ->

    createRoutes app, v1Routes, {
        prefixes: ['/v1', '/api']
        middleware: [auth.authRequired]
    }

    createRoutes app, adminRoutes, {
        prefixes: ['/admin']
        middleware: [auth.adminRequired]
    }

    # DEBUG - remove this soon
    app.route('/testErrors/:mode/:error').get(require('./v1/test').throwError)

    # These are outside of v1Routes because they don't require auth
    app.get  '/resetPassword',                   pagesV1.resetPassword
    app.post '/v1/users/:userID/changePassword', userV1.changePassword
    app.post '/v1/auth/register',                authV1.register
    app.post '/v1/auth/login',                   authV1.login
    app.post '/v1/requestPasswordReset',         userV1.requestPasswordReset

    # Legacy - remove these at the end of Feb.
    app.post '/api/auth/register',               authV1.register
    app.post '/api/auth/login',                  authV1.login
    app.post '/api/requestPasswordReset',        userV1.requestPasswordReset

    app.use (req, res, next) -> next new _errs.NotFound()