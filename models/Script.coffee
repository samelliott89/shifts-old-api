{createModel} = require './modelHelpers'
Promise = require 'bluebird'
_errs = require '../errors'

module.exports = createModel 'Script', {
    name: String
    javascript: String
    coffeescript: String
    isEnabled: Boolean
}, {pk: 'name'}

{_data, helpers, model} = module.exports

model.changes()
    .execute (err, cursor) ->
        return _errs.sendError(err)  if err

        cursor.each (err, item) ->
            return _errs.sendError(err)  if err
            _data[item.name] = item

helpers.getScript = (name) -> new Promise (resolve, reject) ->

    if _data[name]
        return resolve _data[name]

    model.get(name).run()
        .then (obj) ->
            _data[name] = obj
            resolve obj
        .catch reject