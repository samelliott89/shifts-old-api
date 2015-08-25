pushService = require '../../services/pushNotifications'


exports.sendTestPushNotification = ->
    console.log 'Sending Push Notifications..'
    pushService.sendAll('Hello Hello!')