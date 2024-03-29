_ = require 'underscore'
crypto = require 'crypto'
bluebird = require 'bluebird'

auth = require '../auth'
models = require '../models'
_errs = require '../errors'
analytics = require '../analytics'
r = models.r

hex = '0-9a-f'
hex = "[#{hex}#{hex.toUpperCase()}]"
uuidRegex = new RegExp("#{hex}{8}-#{hex}{4}-#{hex}{4}-#{hex}{4}-#{hex}{12}")

exports.get = (req, res, next) ->
    query = req.query['q']
    index = user = undefined

    if uuidRegex.test(query)
        index = 'id'

    if /\w@\w/.test query
        index = 'email'

    if index
        models.User
            .getAll query, {index}
            .eqJoin 'id', r.table('Settings')
            .map (row) ->
                settings = row('right').without('ownerID')
                row('left').merge {settings}
            .run()
            .then (results) ->
                if results.length is 0
                    return res.json {results: []}

                user = results[0]

                unless user.profilePhoto
                    photoHash = crypto.createHash('md5').update(user.id).digest('hex')
                    user.defaultPhoto = "http://www.gravatar.com/avatar/#{photoHash}?default=retro"

                bluebird.all [
                    models.getFriends(user.id)
                    models.Shift.getAll(user.id, {index: 'ownerID'}).run()
                ]
            .then ([connections, shifts]) ->
                _.extend user, {connections, shifts}
                res.json {results: [user]}
            .catch next

    else
        res.json {results: []}

exports.getAuthToken = (req, res, next) ->
    models.User.get(req.query.userID or '')
        .run()
        .then (user) ->
            token = auth.createToken user
            res.json {token, user}
        .catch next

exports.listPageDumps = (req, res, next) ->
    models.DebugDump
        .orderBy models.r.desc('created')
        .without 'pageHtml'
        .run()
        .then (dumps) ->
            dumps = _.map dumps, (dump) ->
                protocol = dump.location?.protocol or 'http:'
                dump._previewLink = "#{protocol}//api.getshifts.co/intergrations/debug/#{dump.id}?clean=true"
                return dump
            res.json {dumps}
        .catch next

exports.updatePageDumps = (req, res, next) ->
    if req.body.action is 'delete'

        req.checkBody('ids', 'Must supply list of page dump IDs to operate on').isArray()
        _errs.handleValidationErrors {req}

        models.DebugDump
            .getAll(req.body.ids...)
            .delete()
            .execute (err, result) ->
                res.json {success: true, result}
            .catch next
    else
        throw new _errs.NotFound 'Action not supported'

exports.identifyAllUsers = (req, res, next) ->
    models.User.run()
        .then (allUsers) ->
            allUsers.forEach analytics.identify
            res.json {success: true, note: 'This operation in asynchronous.'}
        .catch next