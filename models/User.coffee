thinky = require('thinky')()
Promise = require 'bluebird'
helpers = require './helpers'

User = thinky.createModel 'User',
    id:           String
    displayName:  String
    email:        String
    password:     String
    profilePhoto: String

exports.model = User

exports.helpers =
    getUser: (key) ->
        # If the key is an email, get via secondry index,
        # otherwise, assume it's an ID and just .get()
        if '@' in key
            return new Promise (resolve, reject) ->
                User.getAll(key, {index: 'email'}).run (err, results) ->
                    # Reject if there's an error, or if results is empty
                    reject err if err

                    if results.length
                        resolve results[0]
                    else
                        reject helpers.ERROR_NOT_FOUND
        else
            User.get(key).run()