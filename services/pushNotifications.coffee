config 	= require '../config'

pubnub = require('pubnub')(
  ssl: true
  publish_key: config.PUBNUB_PUBLISH_KEY
  subscribe_key: config.PUBNUB_SUBSCRIBE_KEY)


_makePushNotification = (message, deviceType) ->

	notification = {}

	if deviceType == "iOS"
		notification = 'pn_apns': 'aps':
			'alert': message
			'badge': 1
			'sound': 'bingbong.aiff'

	return notification

exports.sendPush = (message, deviceType, deviceID) ->
	
	console.log 'Send push...'

	notification = _makePushNotification(message, deviceType)
	console.log 'Notification - ', notification

	_successCallback = ->
		pubnub.publish
			channel: 'apns-test'
			message: message
			callback: (e) ->
				console.log 'SUCCESS!', e
			error: (e) ->
				console.log 'FAILED! RETRY PUBLISH!', e

	pubnub.mobile_gw_provision
		device_id: deviceID
		channel: 'apns-test'
		op: 'add'
		gw_type: 'apns'
		error: (msg) ->
			console.log msg
		callback: _successCallback

