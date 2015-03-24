_  = require 'underscore'
thinky = require './thinky'

exports.createModel = (name, props, modelOpts = {}) ->
    return {
        model: thinky.createModel name, props, modelOpts
        helpers: {}
        _data: {}
    }

exports.importModel = (name, _exports) ->
    modelDef = require './' + name
    _exports[name] = modelDef.model
    _.extend _exports, modelDef.helpers
