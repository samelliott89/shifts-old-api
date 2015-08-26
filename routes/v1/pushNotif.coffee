pushService = require '../../services/pushNotifications'


exports.sendTestPushNotificationToAll = ->
    console.log 'Sending Push Notifications..'
    pushService.sendAll('Hello Hello!')
    
exports.sendTestPushNotificationToDevice = ->
    pushService.sendPush 'Particular Device', 'IOS', 'ca1c1a2b0377ef55edc184da19e810d170d325652038b033ebf24e10d2c03e0e'
