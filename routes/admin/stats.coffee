_ = require 'underscore'
models = require '../../models'

groupAndCount = (items, field = 'created', groupByFunc) ->

    groupByFunc ?= (created) ->
        new Date(created.getFullYear(), created.getMonth(), created.getDate(), 0, 0, 0, 0)

    _.chain items
        .groupBy (shift) ->
            created = new Date(shift[field])
            groupByFunc created
        .map (shifts, day) ->
            {date: day, shifts: shifts.length}
        .sortBy (item) ->
            new Date(item.date).getTime()
        .value()

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
            graph = groupAndCount(results)
            res.json {graph}
        .catch next

exports.capturesCreated = (req, res, next) ->
    frequency = req.query['frequency'] or 'day'

    switch req.query['frequency']
        when 'hour'
            groupByFunc = (created) -> new Date(created.getFullYear(), created.getMonth(), created.getDate(), created.getHours(), 0, 0, 0)
            since = new Date(Date.now() - (1000*60*60*24*2))
        else
            groupByFunc = undefined
            since = req.query['since']

    queryForGraph 'Capture', since
        .then (results) ->
            graph = groupAndCount results, 'created', groupByFunc
            res.json {graph}
        .catch next

exports.usersCreated = (req, res, next) ->
    queryForGraph 'User', req.query['since']
        .then (results) ->
            graph = groupAndCount(results)
            res.json {graph}
        .catch next