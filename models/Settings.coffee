# Shitty way to get around circular requires
module.exports = {helpers: {}}

crypto = require 'crypto'
bluebird = Promise = require 'bluebird'
_ = require 'underscore'

auth = require '../auth'

thinky = require './thinky'
_errs = require '../errors'

defaultSettings = {
    'startOfWeek': 0
    'softNotifcationPermission': undefined
    'shiftReminderMinutes': 60 * 2
    'completedOnboarding': false
    'calendarTitle': ''
}

validSettings = _.keys defaultSettings

modelSchema =
    ownerID: String
    updated: Date

modelOptions =
    pk: 'ownerID'

Settings = thinky.createModel 'Settings', modelSchema, modelOptions
module.exports.model = Settings

module.exports.helpers = {validSettings, defaultSettings}