_  = require 'underscore'

_errs  = require '../../errors'
models  = require '../../models'
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

        parseObj = {parseKey, ownerID: user.id}

        models.Parse
            .filter parseObj
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

                console.log 'inserting shifts:', newShifts

                models.Shift.insert(newShifts, {conflict: 'update'}).run()
            .then ({generated_keys}) ->
                newParse = _.extend {shifts: generated_keys}, parseObj
                promises = [models.Parse.insert(newParse).run()]

                if oldShiftsToDelete.length
                    promises.push models.Shift.getAll(oldShiftsToDelete...).delete().execute()

                bluebird.all promises
            .then ([newParse, shiftDeleteCursor]) ->
                shiftDeleteCursor.toArray()
            .then (shiftDeleteResult) ->
                console.log shiftDeleteResult
                res.json {success: true, result: shiftDeleteResult}
            .catch next

    onLoginFailure = (err) ->
        next err

    fakeResponse = {json: onLoginSuccess}
    fakeNext = onLoginFailure

    auth.login req, fakeResponse, fakeNext

    # res.json