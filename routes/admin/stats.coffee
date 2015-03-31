_ = require 'underscore'
models = require '../../models'

countByDay = (items, field = 'created') ->

    graph = _.groupBy items, (shift) ->
        created = new Date(shift[field])
        new Date(created.getFullYear(), created.getMonth(), created.getDate(), 0, 0, 0, 0)

    graph = _.map graph, (shifts, day) ->
        {date: day, shifts: shifts.length}

    graph = _.sortBy graph, (item) ->
        new Date(item.date).getTime()

queryForGraph = (modelName, itemsSince, itemsSinceField, fields) ->
    itemsSinceField = 'created'
    itemsSince ?= new Date(Date.now() - (1000*60*60*24*7*3)) # Three weeks
    fields ?= ['id', 'created']

    models[modelName]
        .filter (row) -> row(itemsSinceField).gt itemsSince
        .withFields fields...
        .execute()
        .then (cursor) ->
            cursor.toArray()

exports.shiftsCreated = (req, res, next) ->
    queryForGraph 'Shift', req.query['since']
        .then (results) ->
            graph = countByDay(results)
            res.json {graph}
        .catch next

exports.capturesCreated = (req, res, next) ->
    queryForGraph 'Capture', req.query['since']
        .then (results) ->
            graph = countByDay(results)
            res.json {graph}
        .catch next

exports.usersCreated = (req, res, next) ->
    queryForGraph 'User', req.query['since']
        .then (results) ->
            graph = countByDay(results)
            res.json {graph}
        .catch next