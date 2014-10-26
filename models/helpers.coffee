NOT_FOUND_MSG = 'document not found'

notFoundMsgs = [
    'not find a document'
    'document not found'
]

exports.ERROR_NOT_FOUND = {message: 'document not found'}

exports.notFound = (err) ->
    msg = err.message.toLowerCase()

    for errMsg in notFoundMsgs
        return true  if msg.indexOf(errMsg) > -1

    return false