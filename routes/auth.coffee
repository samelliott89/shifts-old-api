models = require '../models'
auth = require '../auth'

exports.register = (req, res) ->
    email = req.body.email
    password = req.body.password

    models.getUser email
        .then ->
            # Email already exists, so return an error
            res.status(400).json {error: 'Email already exists'}
        .catch (err) ->
            return res.status(500).json {error: 'Unknown error occured'} unless models.helpers.notFound err

            console.log 'Password:', password
            pwordHashed = auth.hashPassword password
            console.log 'Hash:', pwordHashed

            newUser = new models.User
                email: email
                password: pwordHashed

            newUser.saveAll()
                .then (user) ->
                    console.log 'Yay, created user', user.id
                    console.log user
                    res.json user
                .catch (err) ->
                    console.log 'Error creating user...'
                    console.log err
                    res.status(500).json {error: 'Error creating user', message: err.message}