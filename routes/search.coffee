elasticsearch = require 'elasticsearch'
config = require '../config'
models = require '../models'
_ = require 'underscore'

esClient = new elasticsearch.Client
    host: config.ELASTIC_SEARCH_HOST
    log: 'warning'

exports.userSearch = (req, res, next) ->
    searchQuery = req.param 'q'

    unless searchQuery
        throw new _errs.ValidationError {q:msg:'Search query is required'}

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

    esClient.search esSearch
        .then (resp) ->
            results = _.map resp.hits.hits, (result) ->
                cleanedResult = models.cleanUser result._source, req
                cleanedResult._score = result._score
                return cleanedResult

            res.json {results}
        .catch next
