_ = require 'underscore'
Promise = require 'bluebird'

{createModel} = require './modelHelpers'
_errs = require '../errors'

module.exports = createModel 'Link',
    id: String
    href: String
    text: String
    type: String
    icon: Array
    iconSize: String

{_data, helpers, model} = module.exports

model.ensureIndex 'type'

model.changes()
    .execute (err, cursor) ->
        return _errs.sendError(err)  if err

        cursor.each (err, item) ->
            return _errs.sendError(err)  if err
            _data[item.id] = item

helpers.getLinksForType = (type) -> new Promise (resolve, reject) ->
    storedItems = _.filter _data, {type}

    if storedItems.length > 0
        return resolve storedItems

    model
        .getAll type, {index: 'type'}
        .run()
        .then (links) ->
            for link in links
                _data[link.id] = link

            resolve links
        .catch reject
