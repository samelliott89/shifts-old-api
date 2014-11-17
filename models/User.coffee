thinky = require('thinky')()
Promise = require 'bluebird'
helpers = require './helpers'

User = thinky.createModel 'User',
    id:           String
    displayName:  String
    email:        String
    password:     String
    profilePhoto: String
    traits:       Object

User.ensureIndex 'email'

exports.model = User

prepareUser = (user, opts={}) ->
    unless opts.includePassword
        delete user.password

    unless opts.includeEmail
        delete user.email

    return user

exports.helpers =
    prepareUser: prepareUser

    # Getting a user via this helper is recommended because it will strip
    # sensitive data, like passwords, by default
    getUser: (key, opts={}) -> new Promise (resolve, reject) ->
        # If the key is an email, get via secondry index,
        # otherwise, assume it's an ID and just .get()
        if '@' in key
                User.getAll(key, {index: 'email'}).run (err, results) ->
                    # Reject if there's an error, or if results is empty
                    reject err if err

                    if results.length
                        resolve prepareUser results[0], opts
                    else
                        reject helpers.ERROR_NOT_FOUND
        else
            User.get(key).run()
                .then (user) -> resolve prepareUser user, opts
                .catch reject
