icalendar = require 'icalendar'
icalendar.PRODID = '-//Shifts Inc//robby calendar feed'

models = require '../../models'

exports.getCalFeed = (req, res, next) ->
    calendarID = req.param 'calendarID'

    models.getShiftsViaCalendar calendarID
        .then (shifts) ->

            ical = new icalendar.iCalendar()

            for shift in shifts
                shiftEvent = new icalendar.VEvent shift.id
                shiftEvent.setDate shift.start, shift.end
                shiftEvent.setSummary 'Work shift'
                ical.addComponent shiftEvent

            res.send ical.toString()

        .catch next

exports.getCalFeedItem = (req, res, next) ->
    userID = req.param 'userID'

    # Gets calendar, or creates new if doesnt exist yet
    models.Calendar
        .getAll userID, {index: 'ownerID'}
        .run()
        .then ([calendarFeed]) ->
            return calendarFeed if calendarFeed
            newCalendar = new models.Calendar {ownerID: userID}
            newCalendar.save()
        .then (calendar) ->
            calFeedPath = "/v1/calendar/#{calendar.id}/feed.ics"
            calendar.path = calFeedPath

            if req.query.redirect
                res.redirect calFeedPath
            else
                res.json {calendar}
        .catch next
