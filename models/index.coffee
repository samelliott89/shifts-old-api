_ = require 'underscore'

exports.helpers = require './helpers'

userModelDef = require './User'
exports.User = userModelDef.model
_.extend exports, userModelDef.helpers

shiftModelDef = require './Shift'
exports.Shift = shiftModelDef.model
_.extend exports, shiftModelDef.helpers