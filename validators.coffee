_ = require 'underscore'
validator = require('express-validator').validator

module.exports =
    isArray: Array.isArray

    shiftsHaveStartDate: (shifts) ->
        invalidShifts = _.find shifts, (shift) ->
            !validator.isDate(shift.start)

        # return true if invalidShifts is undefined
        !invalidShifts?

    shiftsHaveEndDate: (shifts) ->
        invalidShifts = _.find shifts, (shift) ->
            !validator.isDate(shift.end)

        # return true if invalidShifts is undefined
        !invalidShifts?

    shiftsEndIsAfterStart: (shifts) ->
        invalidShifts = _.find shifts, (shift) ->
            !validator.isAfter(shift.end, shift.start)
        # return true if invalidShifts is undefined
        !invalidShifts?