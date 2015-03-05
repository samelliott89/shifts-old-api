_ = require 'underscore'

auth      = require '../auth'
_errs      = require '../errors'

authV1     = require './v1/auth'
userV1     = require './v1/users'
pagesV1    = require './v1/pages'
shiftV1    = require './v1/shifts'
searchV1   = require './v1/search'
friendV1   = require './v1/friends'
scraperV1  = require './v1/scraper'
captureV1  = require './v1/capture'
settingsV1 = require './v1/settings'
calendarV1 = require './v1/calendar'
intergrationsV1 = require './v1/intergrations'

admin = require './admin'

module.exports = (app) ->

    app.route('/api').get(userV1.apiIndex)
    app.route('/v1').get(userV1.apiIndex)

    ##
    # Main authentication
    ##
    app.route('/v1/auth/token')          .get    auth.authRequired, authV1.refreshToken
    app.route('/v1/auth/register')       .post   authV1.register
    app.route('/v1/auth/login')          .post   authV1.login
    app.route('/resetPassword')          .get    pagesV1.resetPassword
    app.route('/v1/requestPasswordReset').post   userV1.requestPasswordReset
    app.route('/v1/auth/cookie')         .post   authV1.saveAuthCookie
    app.route('/v1/auth/cookie')         .delete authV1.clearAuthCookie



    ##
    # Users and settings
    ##
    app.route '/v1/users/:userID'
        .get    auth.authRequired,        userV1.getUser
        .post   auth.currentUserRequired, userV1.editUser

    app.route '/v1/users/:userID/settings'
        .get    auth.currentUserRequired, settingsV1.getSettings
        .post   auth.currentUserRequired, settingsV1.updateSettings

    app.route '/v1/users/:userID/changePassword'
        .post                             userV1.changePassword

    app.route '/v1/users/:userID/friends'
        .get    friendV1.getFriends
        .post   auth.currentUserRequired, friendV1.createFriendship
        .delete auth.currentUserRequired, friendV1.deleteFriendship

    app.route '/v1/users/:userID/friends/pending'
        .get    auth.currentUserRequired, friendV1.getPendingFriendships

    app.route '/v1/search/users'
        .get    auth.authRequired,        searchV1.userSearch


    ##
    # Calendar feed
    ##
    app.route '/v1/calendar/:calendarID/feed.ics'
        .get                           calendarV1.getCalFeed

    app.route '/v1/users/:userID/calendar'
        .get auth.currentUserRequired, calendarV1.getCalFeedItem


    ##
    # Shift and feed management
    ##
    app.route '/v1/users/:userID/feed'
        .get    auth.currentUserRequired, shiftV1.getShiftFeed

    app.route '/v1/users/:userID/shifts'
        .get                              shiftV1.getShiftsForUser
        .post   auth.currentUserRequired, shiftV1.addShifts

    app.route '/v1/calendar/:calendarID'
        .get                              calendarV1.getCalFeed

    app.route '/v1/shifts/:shiftID'
        .get    auth.authRequired,        shiftV1.getShift
        .delete auth.authRequired,        shiftV1.deleteShift

    app.route '/v1/users/:userID/captures'
        .post   auth.currentUserRequired, captureV1.addCapture


    ##
    # Bookmarklet and other intergrations
    ##
    app.route('/v1/parse/bookmarklet')   .post                    scraperV1.recieveBookmarkletScrape
    app.route('/v1/parse/frame')         .get                     intergrationsV1.frame
    app.route('/intergrations/debug')    .post                    intergrationsV1.debug
    app.route('/intergrations/debug/:id').get                     intergrationsV1.getDebugHtml

    ##
    # Admin and misc routes
    ##
    app.route('/_admin/get')      .get auth.adminRequired, admin.get
    app.route('/_admin/getToken') .get auth.adminRequired, admin.getAuthToken
    app.route('/_admin/pageDumps').get auth.adminRequired, admin.listPageDumps
    app.route('/_admin/pageDumps').put auth.adminRequired, admin.updatePageDumps
    app.route('/_admin/captures') .get auth.adminRequired, admin.listRosterCaptures

    # 404 handler
    app.use (req, res, next) -> next new _errs.NotFound()