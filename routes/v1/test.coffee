_errs = require '../../errors'

exports.throwError = (req, res, next) ->
    mode = req.params['mode']
    errorName = req.params['error']

    console.log {mode, errorName}

    error = new _errs[errorName]()

    if mode is 'throw'
        throw error
    else if mode is 'next'
        next error

    res.json {'Hello': 'World'}