bugsnag = require 'bugsnag'
config  = require '../config'

module.exports = ->
    bugsnag.register config.BUGSNAG_API_KEY, {releaseStage: config.releaseStage}