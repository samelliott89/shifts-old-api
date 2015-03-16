_ = require 'underscore'
request = require 'request'
elasticsearch = require 'elasticsearch'

config = require '../../config'
models = require '../../models'
_errs = require '../../errors'
analytics = require '../../analytics'

esClient = new elasticsearch.Client
    host: config.ELASTIC_SEARCH_HOST
    log: 'warning'

esRiverUrl = "http://#{config.ELASTIC_SEARCH_HOST}/_river/rethinkdb/_meta"

_checkESRiverStatus = ->
    console.log 'Checking ElasticSearch RethinkDB river'
    request esRiverUrl, (err, resp, body) ->
        if err
            console.log 'Couldn\'t connect to Elastic Search at ' + config.ELASTIC_SEARCH_HOST
            throw err

        body = JSON.parse body

        return  if body.found
        _createESRiver()

_createESRiver = ->
    console.log 'Creating ES River'
    body =
        type: 'rethinkdb'
        rethinkdb:
            host: config.RETHINKDB_HOST
            port: config.RETHINKDB_PORT
            databases: {}

    body.rethinkdb.databases[config.RETHINKDB_DB] =
        User:
            backfill: true,
            index: config.ELASTIC_SEARCH_INDEX

    requestOpts =
        url: esRiverUrl
        method: 'PUT'
        json: true
        body: body

    request.put requestOpts, (err, resp, body) ->
        if err
            console.log 'Error creating ES RethinkDB river'
            throw err

        if body.created
            console.log 'Successfully created ES RethinkDB river'
            console.log 'You may need to restart ShiftsAPI or ElasticSearch for it to take effect'
        else
            console.log 'ES RethinkDB was not created. Search may not work until this is resolved'
            console.log 'ES response:'
            console.log body

_checkESRiverStatus()

exports.userSearch = (req, res, next) ->
    req.checkQuery('q', 'Search query `q` of 1 or more characters is required').isLength(1, 2000)
    _errs.handleValidationErrors {req}

    searchQuery = req.param 'q'

    esSearch =
        index: config.ELASTIC_SEARCH_INDEX
        type: 'User'
        body: query: constant_score: filter: fquery:
            query:
                multi_match:
                    query: searchQuery
                    fields: ['displayName', 'bio', 'email']
            _cache: true

    analytics.track req, 'Search', {searchQuery: searchQuery}

    esClient.search esSearch
        .then (resp) ->
            results = _.map resp.hits.hits, (result) ->
                cleanedResult = models.cleanUser result._source, req
                return cleanedResult


            res.json {results}
        .catch next
