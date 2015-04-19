models = require '../../models'
config = require '../../config'
_errs = require '../../errors'
coffeeLib = require 'coffee-script'

createSandboxedQuery = (queryStr) ->
    {r, User, Link, Shift, Parse, Parser, Script, Capture, Calendar, Settings, DebugDump, Friendship} = models
    DB = config.RETHINKDB_DB
    eval queryStr

evaluateQuery = ({javascript}) ->
    createSandboxedQuery(javascript).execute()
        .then (result) -> return result

module.exports.getAllQueries = (req, res, next) ->
    models.Query
        .run()
        .then (queries) ->
            res.json {queries}
        .catch next

module.exports.updateQuery = (req, res, next) ->
    req.checkBody('coffeescript', 'A coffee-script body is required').notEmpty()
    req.checkBody('name', 'A name is required').notEmpty()
    _errs.handleValidationErrors {req}

    coffeescript = req.body.coffeescript
    javascript = coffeeLib.compile coffeescript, {bare: true}

    query = {
        id: req.params?.queryID
        name: req.body.name
        coffeescript: coffeescript
        javascript: javascript
    }

    models.Query
        .insert(query, {conflict: 'update', returnChanges: true})
        .run()
        .then ({changes}) ->
            res.json {query: changes[0].new_val}

module.exports.executeQuery = (req, res, next) ->
    query = {}
    queryID = req.params.queryID

    models.Query.get queryID
        .run()
        .then (_query) -> query = _query
        .then evaluateQuery
        .then (result) ->
            query.lastResult = result
            res.json {query, result}

            query.save()

        .catch (err) ->
            errObj = {}
            Object.getOwnPropertyNames(err).forEach (key) -> errObj[key] = err[key]

            console.log '\nError executing query:'
            console.log errObj
            console.log '\nname'
            console.log errObj.name

            res.json {error: errObj}