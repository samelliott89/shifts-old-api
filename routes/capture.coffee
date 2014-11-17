models = require '../models'

exports.addCapture = (req, res) ->

    res.json {status: 'cool, it worked'}

    if req.user.traits?.fakeCamera
        _addFakeShifts = ->
            fakeShifts = [
                {
                    "start": "Wed Nov 19 2014 09:30:00 GMT-0800 (PST)"
                    "end": "Wed Nov 19 2014 17:00:00 GMT-0800 (PST)"
                    "ownerID": req.user.id
                },{
                    "start": "Thu Nov 20 2014 08:00:00 GMT-0800 (PST)"
                    "end": "Thu Nov 20 2014 15:00:00 GMT-0800 (PST)"
                    "ownerID": req.user.id
                },{
                    "start": "Fri Nov 21 2014 11:15:00 GMT-0800 (PST)"
                    "end": "Fri Nov 21 2014 20:30:00 GMT-0800 (PST)"
                    "ownerID": req.user.id
                },{
                    "start": "Sat Nov 22 2014 12:00:00 GMT-0800 (PST)"
                    "end": "Sat Nov 22 2014 20:30:00 GMT-0800 (PST)"
                    "ownerID": req.user.id
                },{
                    "start": "Tue Nov 25 2014 09:30:00 GMT-0800 (PST)"
                    "end": "Tue Nov 25 2014 15:30:00 GMT-0800 (PST)"
                    "ownerID": req.user.id
                }
            ]

            shifts = fakeShifts.map (shift) ->
                shift.start = new Date shift.start
                shift.end = new Date shift.end
                shift = new models.Shift shift
                shift.ownerID = req.user.id
                return shift

            models.Shift.save shifts
                .done (result) -> console.log 'Saved fake shifts', result

        setTimeout _addFakeShifts, 3 * 1000