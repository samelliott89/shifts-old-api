_ = require 'underscore'
baseConfig = require './defaults.json'

configPrefix = 'SHIFTS_WEB_'

config = _.chain process.env
    .map (value, key) ->
        if key.indexOf(configPrefix) > -1
            return [key.replace(configPrefix, ''), value]
        else
            return [key, value]
    .object()
    .value()


module.exports = _.extend baseConfig, config