config 	= require '../config'
pubnub = require('pubnub')(
  ssl: true
  publish_key: config.PUBNUB_PUBLISH_KEY
  subscribe_key: config.PUBNUB_SUBSCRIBE_KEY)
PNmessage = require('pubnub').PNmessage

_makeSubscription = ( deviceType, deviceID, channel ) ->

    if deviceType == 'IOS'
        pubnub.mobile_gw_provision
            device_id: deviceID
            channel: channel
            op: 'add'
            gw_type: 'apns'
            error: () ->
                console.log "Error while trying to set subscription for this device - ", msg
            callback: (msg) ->
                console.log 'Channel subscription successful for this device. - ' + msg

    if deviceType == 'Android'
        pubnub.mobile_gw_provision
            device_id: deviceID
            channel  : channel
            op: 'add'
            gw_type: 'gcm'
            error: () ->
                console.log "Error while trying to set subscription for this device - ", msg
            callback: (msg) ->
                console.log 'Channel subscription successful for this device. - ' + msg


_makePushNotification = (message, deviceType) ->
    notification = PNmessage();
    notification.pubnub = pubnub
    notification.callback = (msg) ->
        console.log(msg)
    notification.error = (msg) ->
        console.log(msg)

    if deviceType == "IOS"
        notification.apns = {
            alert: message,
        }

    if deviceType == "Android"
        notification.gcm = {
            title: 'Atum',
            message: message
        }

    return notification

exports.setup = (deviceType, deviceID) ->
    #Device id is associated with a each channel individually
    _makeSubscription( deviceType, deviceID, 'all')
    _makeSubscription( deviceType, deviceID, deviceID)

exports.sendAll = (message) ->

    notif = PNmessage();
    notif.pubnub = pubnub
    notif.callback = (msg) ->
        console.log(msg)
    notif.error = (msg) ->
        console.log(msg)
    notif.channel = 'all'
    notif.apns = {
        alert: message
    }
    notif.gcm = {
        title: 'Atum',
        message: message
    }
    notif.publish();

    return

exports.sendPush = (message, deviceType, deviceID) ->
    notification = _makePushNotification(message, deviceType)
    notification.channel = deviceID
    notification.publish();
    return
