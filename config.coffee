_ = require 'underscore'
baseConfig = require './defaults.json'
config = module.exports = _.extend baseConfig, process.env

config.env = (config.NODE_ENV or 'dev').toLowerCase()
if config.env is 'prod'
    config.releaseStage = 'Production'
else
    config.releaseStage = config.env