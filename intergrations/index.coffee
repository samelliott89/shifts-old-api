_errs  = require '../errors'
parsers = require './parsers'

exports.parseBookmarkletScrape = (name, parseData) ->
    console.log 'Recieved', name, 'scrape'

    parser = parsers[name]
    unless parser
        throw new Error 'Parser not found for ' + name

    return parser parseData