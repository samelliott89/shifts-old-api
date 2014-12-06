elasticsearch = require 'elasticsearch'
config = require '../config'
models = require '../models'
_ = require 'underscore'

esClient = new elasticsearch.Client
    host: config.ELASTIC_SEARCH_HOST
    log: 'warning'

exports.userSearch = (req, res) ->
    searchQuery = req.param 'q'
    console.log 'searchQuery:', searchQuery

    unless searchQuery
        res.status(400).json {error: 'Required param \'q\' missing'}

    esSearch =
        index: config.ELASTIC_SEARCH_INDEX
        type: 'users'
        body:
            query:
                constant_score:
                    filter:
                        fquery:
                            query:
                                match_phrase_prefix:
                                    displayName: searchQuery
                            _cache: true

    console.log 'ES Search'
    console.log esSearch

    esClient.search esSearch
        .then (resp) ->

            results = _.map resp.hits.hits, (result) ->
                cleanedResult = models.cleanUser result._source, req
                cleanedResult._score = result._score
                return cleanedResult

            res.json {results}
        .catch (err) ->
            console.log 'fuck, error'
            console.log err
            res.send(500).json({error: 'ES fucked up'})
