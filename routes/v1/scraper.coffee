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

                models.Shift.insert(newShifts, {conflict: 'update'}).run()
            .then (newShifts) ->
                newShiftIds = _.pluck newShifts, 'id'
                newParse = _.extend {shifts: newShiftIds}, parseObj
                bluebird.all = [
                    models.Parse.insert(newParse).run()
                    models.Shift.getAll(oldShiftsToDelete...).delete().execute()
                ]
            .then ([newParse, shiftDeleteCursor]) ->
                shiftDeleteCursor.toArray()
            .then (shiftDeleteResult) ->
                console.log shiftDeleteResult
                res.json {success: true, result: shiftDeleteResult}
            .catch next

        res.json {shifts, parseKey}

    onLoginFailure = (err) ->
        next err

    fakeResponse = {json: onLoginSuccess}
    fakeNext = onLoginFailure

    auth.login req, fakeResponse, fakeNext

    # res.json