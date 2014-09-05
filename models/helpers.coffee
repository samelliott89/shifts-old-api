NOT_FOUND_MSG = 'document not found'

exports.notFound = (err) -> NOT_FOUND_MSG not in err.message.toLowerCase()
