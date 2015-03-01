_ = require 'underscore'
jwt = require 'jsonwebtoken'
cheerio = require 'cheerio'

models = require '../../models'
config = require '../../config'

bmRegex = /(src=\"https:\/\/s3-ap-southeast-2.amazonaws.com\/pages.getshifts.co\/debugBookmarklet.js\?r=[\d.]*\")/g
linkRegex = /(src|href)=(['"])\//g

MSG_DIRECT_ACCESS = 'Oops. This page shouldn\'t be accessed directly.</br></br>Log into your schedule and run the bookmarklet.'

exports.debug = (req, res, next) ->
    {debugData} = req.body
    debugData = _.omit debugData, 'id'
    debugData.created = new Date()

    if (debugData.type is 'eoi') and (debugData.attachedDump)
        promise = models.DebugDump
            .get debugData.attachedDump
            .update {eoiEmail: debugData.email}
            .run()
    else
        obj = new models.DebugDump(debugData)
        promise = obj.save()

    promise
        .then (dump) -> res.json {success: true, id: dump.id}
        .catch next

exports.getDebugHtml = (req, res, next) ->
    models.DebugDump
        .get req.params['id']
        .run()
        .then (dump) ->
            html = dump.pageHtml or '<pre>pageHtml is undefined</pre>'

            if req.query['clean']
                $ = cheerio.load html
                $('#rostergenius-script').remove()
                $('#robby-script').remove()
                $('.xrby-parent').remove()
                html = $.html()
                urlPrefix = dump.location.protocol + '//' + dump.location.host + '/'
                html = html.replace linkRegex, "$1=$2#{urlPrefix}"

            res.send html
        .catch next

exports.frame = (req, res, next) ->
    foundParser = null

    _render = (show, context = {}) ->
        context.show = show
        context.layout = false
        context.parser = JSON.stringify(context.parser)  if context.parser
        res.render 'bmarkFrame', context

    _renderError = (err) ->
        console.log 'rendering error!'
        if err instanceof models.Errors.DocumentNotFound
            res.clearCookie config.AUTH_COOKIE_NAME
            _render 'login', {parser: foundParser}
        else
            console.log err
            _render 'alert', {alertClass: '-error', msg: 'Unexpected server error.'}

    # Show error if the URL querystring isnt present
    unless req.query.url
        return _render 'alert', {alertClass: '-warn', fullMsg: MSG_DIRECT_ACCESS}

    models.Parser
        .getAll true, {index: 'isEnabled'}
        .run()
        .then (parsers) ->
            # Match the supplied URL to a parser
            for parser in parsers
                for urlRegexStr in parser.validUrls
                    urlRegex = new RegExp urlRegexStr
                    console.log urlRegex
                    if urlRegex.test req.query.url
                        foundParser = parser

            # If the URL didnt match a parser, show no suppor error message
            unless foundParser
                return _render 'noSupport'

            # Get auth token and show login page if it's not present
            authToken = req.cookies[config.AUTH_COOKIE_NAME]
            unless authToken
                _render 'login', {parser: foundParser}
                return

            # Verify the authToken. If we can't, delete the token and show the login screen
            try
                authDetails = jwt.verify authToken, config.SECRET
            catch e
                res.clearCookie config.AUTH_COOKIE_NAME
                return _render 'login', {parser: foundParser}

            models.getUser authDetails.id, {clean: true, req: {} }
                .then (user) ->
                    _render 'loggedIn', {user, parser: foundParser}
                .catch _renderError
        .catch _renderError