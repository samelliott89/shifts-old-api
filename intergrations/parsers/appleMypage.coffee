_ = require 'underscore'
moment = require 'moment'
cheerio = require 'cheerio'

mypageLocaleMapper = {
    'en_us': 'en'
    'fr_FR': 'fr'
}

START_OF_WEEK_REGEX = /\s{2,}(.+)/

MOMENT_FORMATS = {
    shiftTime: 'MMM DD YYYY hh:mmA Z'
}

trim = (str) -> str.replace(/^\s+|\s+$/g,'')
parseShiftTime = ({weekStarting, time, timezoneOffset, dayIndex, locale}) ->
    dateRaw = "#{weekStarting} #{time} #{timezoneOffset}"
    date = moment dateRaw, MOMENT_FORMATS.shiftTime, locale
    date.add {days: dayIndex}
    return date

module.exports = (parseData) ->
    locale = mypageLocaleMapper[parseData.locale] or 'en'
    console.log 'Started appleMypage parser'
    $ = cheerio.load parseData.html

    # First, find the 'schedule begins' header, extract the date part and remove extra characters
    # Then parse it into a real date (moment) object
    weekStartingRaw = $('.cellHeader3').text()
    weekStartingRaw = weekStartingRaw.match(START_OF_WEEK_REGEX)[1]
    weekStartingRaw = weekStartingRaw.replace(/,/g, '')
    shifts = []

    # Now, iterate over the days (table rows).
    $('table:nth-child(2) tr').each (index, row) ->
        $row = $ row

        return  if $row.hasClass 'disable'

        [startTime, _x, endTime] = $row.find('td.time')
        baseData = {
            weekStarting: weekStartingRaw
            timezoneOffset: parseData.timezoneOffset
            dayIndex: index
            locale: locale
        }

        shiftStart = parseShiftTime _.extend {time: $(startTime).text()}, baseData
        shiftEnd = parseShiftTime _.extend {time: $(endTime).text()}, baseData

        # If the end time is before the start time, we assume it's an overnighter
        # and we need to add another day
        if shiftEnd < shiftStart
            shiftEnd.add {days: 1}

        shifts.push {
            start: shiftStart
            end: shiftEnd
        }

    return {shifts, parseKey: weekStartingRaw.toLowerCase()}