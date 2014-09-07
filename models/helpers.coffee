NOT_FOUND_MSG = 'document not found'

exports.ERROR_NOT_FOUND = {message: NOT_FOUND_MSG}

exports.notFound = (err) ->
    err.message.toLowerCase().indexOf(NOT_FOUND_MSG) isnt -1
