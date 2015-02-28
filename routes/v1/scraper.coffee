_        = require 'underscore'
jwt      = require 'jsonwebtoken'
bluebird = require 'bluebird'

auth           = require '../../auth'
_errs          = require '../../errors'
models         = require '../../models'
config         = require '../../config'
intergrations  = require '../../intergrations'
authRoutes     = require './auth'


exports.recieveBookmarkletScrape = (req, res, next) ->

    onLoginSuccess = ({user}) ->
        authToken = auth.createToken {id: user.id}
        res.cookie 'sessionAuthToken', authToken, {httpOnly: true}

        {shifts, parseKey} = intergrations.parseBookmarkletScrape req.body.parserName, req.body.parseData
        oldShiftsToDelete = []
        shiftCount = 0

        ownerParseKey = user.id + parseKey

        models.Parse
            .getAll ownerParseKey, {index: 'ownerParseKey'}
            .run()
            .then (previousParses) ->
                for prev in previousParses
                    oldShiftsToDelete = oldShiftsToDelete.concat prev.shifts

                newShifts = shifts.map (shift) ->
                    _.extend {}, shift, {
                        created: new Date()
                        ownerID: user.id
                        source: models.SHIFT_SOURCE_BOOKMARKLET
                    }

                shiftCount = newShifts.length
                models.Shift.insert(newShifts, {conflict: 'update'}).run()
            .then ({generated_keys}) ->
                newParse = {
                    parseKey,
                    ownerID: user.id
                    shifts: generated_keys
                    parserName: req.body.parserName
                }

                updatedParseObj = {
                    parseKey: '$REPLACED_' + parseKey
                    shifts: []
                }

                promises = [
                    models.Parse
                        .getAll ownerParseKey, {index: 'ownerParseKey'}
                        .update updatedParseObj
                        .do ->
                            models.r.db config.RETHINKDB_DB
                                .table 'Parse'
                                .insert newParse

                        .execute()
                ]

                if oldShiftsToDelete.length
                    promises.push models.Shift.getAll(oldShiftsToDelete...).delete().execute()

                bluebird.all promises
            .then ->
                res.json {
                    success: true
                    rememberMeIsSet: !!req.cookies[config.AUTH_COOKIE_NAME]
                    shiftCount: shiftCount
                    action: if oldShiftsToDelete.length then 'updated in' else 'added to'
                }
            .catch next

    onLoginFailure = (err) ->
        next err

    req.checkBody('parseData', 'Parse data required').notEmpty()
    req.checkBody('parserName', 'Parse name required').notEmpty()
    # Email and password validated by login function
    _errs.handleValidationErrors {req}

    _loginViaUsernamePassword = ->
        fakeResponse = {json: onLoginSuccess}
        fakeNext = onLoginFailure

        authRoutes.login req, fakeResponse, fakeNext

    authToken = req.cookies[config.AUTH_COOKIE_NAME]
    unless authToken
        return _loginViaUsernamePassword()

    try
        authDetails = jwt.verify authToken, config.SECRET
    catch e
        res.clearCookie config.AUTH_COOKIE_NAME
        return _loginViaUsernamePassword()

    models.getUser authDetails.id, {clean: true, req: {} }
        .then (user) -> onLoginSuccess {user}
        .catch next