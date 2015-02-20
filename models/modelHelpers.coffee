_  = require 'underscore'
thinky = require './thinky'

exports.createModel = (name, props) ->
    return {
        model: thinky.createModel name, props
        helpers: {}
    }

exports.importModel = (name, _exports) ->
    modelDef = require './' + name
    _exports[name] = modelDef.model
    _.extend _exports, modelDef.helpers
