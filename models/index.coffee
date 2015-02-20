_ = require 'underscore'
thinky = require './thinky'
{importModel} = require './modelHelpers'

exports.r = thinky.r
exports.Errors = thinky.Errors
exports.Query = thinky.Query

importModel 'User',       exports
importModel 'Settings',   exports
importModel 'Shift',      exports
importModel 'Capture',    exports
importModel 'Friendship', exports
importModel 'DebugDump',  exports
importModel 'Parse',      exports
importModel 'Calendar',   exports
importModel 'Link',       exports