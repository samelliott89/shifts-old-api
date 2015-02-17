_  = require 'underscore'

_errs  = require '../../errors'
models  = require '../../models'
config  = require '../../config'
auth  = require './auth'
intergrations  = require '../../intergrations'

bluebird = require 'bluebird'

exports.recieveBookmarkletScrape = (req, res, next) ->
    req.checkBody('parseData', 'Parse data required').notEmpty()
    req.checkBody('parserName', 'Parse name required').notEmpty()
    # Email and password validated by login function
    _errs.handleValidationErrors {req}

    onLoginSuccess = ({user}) ->
        {shifts, parseKey} = intergrations.parseBookmarkletScrape(req.body.parserName, req.body.parseData)
        oldShiftsToDelete = []

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

                models.Shift.insert(newShifts, {conflict: 'update'}).run()
            .then ({generated_keys}) ->
                newParse = {
                    parseKey,
                    ownerID: user.id
                    shifts: generated_keys
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
            .then () ->
                res.json {success: true}
            .catch next

    onLoginFailure = (err) ->
        next err

    fakeResponse = {json: onLoginSuccess}
    fakeNext = onLoginFailure

    auth.login req, fakeResponse, fakeNext

    # res.json