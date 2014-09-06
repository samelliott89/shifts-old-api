NOT_FOUND_MSG = 'document not found'

exports.ERROR_NOT_FOUND = {message: NOT_FOUND_MSG}

exports.notFound = (err) -> NOT_FOUND_MSG not in err.message.toLowerCase()
