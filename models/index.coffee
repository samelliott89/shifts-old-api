_ = require 'underscore'
thinky = require './thinky'
{importModel} = require './modelHelpers'

exports.r = thinky.r
exports.Errors = thinky.Errors
exports.Query = thinky.Query

importModel 'User',       exports
importModel 'Link',       exports
importModel 'Shift',      exports
importModel 'Parse',      exports
importModel 'Parser',     exports
importModel 'Script',     exports
importModel 'Capture',    exports
importModel 'Calendar',   exports
importModel 'Settings',   exports
importModel 'DebugDump',  exports
importModel 'Friendship', exports