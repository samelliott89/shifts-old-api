_ = require 'underscore'
moment = require 'moment-timezone'
Promise = require 'bluebird'
q = require 'q'
icalendar = require 'icalendar'

auth = require '../../auth'
models = require '../../models'
_errs = require '../../errors'

icalendar.PRODID = '-//Shifts Inc//robby calendar feed'

exports.getCalFeed = (req, res, next) ->
    calendarID = req.param 'calendarID'

    # This checks to make sure the current user has permission,
    # and throws InvalidPermissions error if not

    models.getShiftsViaCalendar calendarID
        .then (shifts) ->

            ical = new icalendar.iCalendar()

            for shift in shifts
                shiftEvent = new icalendar.VEvent shift.id
                shiftEvent.setDate shift.start, shift.end
                shiftEvent.setSummary 'Work shift'
                ical.addComponent shiftEvent

            res.send ical.toString()

        .catch (err) ->
            _errs.handleRethinkErrors err, next

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
