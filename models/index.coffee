_ = require 'underscore'

exports.helpers = require './helpers'

userModelDef = require './User'
exports.User = userModelDef.model
_.extend exports, userModelDef.helpers

shiftModelDef = require './Shift'
exports.Shift = shiftModelDef.model
_.extend exports, shiftModelDef.helpers

captureModelDef = require './Capture'
exports.Capture = captureModelDef.model
_.extend exports, captureModelDef.helpers

friendshipModelDef = require './Friendship'
exports.Friendship = friendshipModelDef.model
_.extend exports, friendshipModelDef.helpers