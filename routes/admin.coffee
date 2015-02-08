_ = require 'underscore'
crypto = require 'crypto'
bluebird = require 'bluebird'

models = require '../models'
r = models.r

hex = '0-9a-f'
hex = "[#{hex}#{hex.toUpperCase()}]"
uuidRegex = new RegExp("#{hex}{8}-#{hex}{4}-#{hex}{4}-#{hex}{4}-#{hex}{12}")

exports.get = (req, res, next) ->
    query = req.query['q']
    index = user = undefined

    if uuidRegex.test(query)
        index = 'id'

    if '@' in query
        index = 'email'

    if index
        models.User
            .getAll query, {index}
            .eqJoin 'id', r.table('Settings')
            .map (row) ->
                settings = row('right').without('ownerID')
                row('left').merge {settings}
            .run()
            .then ([_user]) ->
                user = _user
                console.log 'user id:', user.id

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