models = require '../models'
auth = require '../auth'
helpers = require './helpers'

exports.register = (req, res) ->
    req.checkBody('email', 'Valid email required').notEmpty().isEmail()
    req.checkBody('password', 'Password of minimum 8 characters required').notEmpty().isLength(8)

    errors = req.validationErrors(true);
    return res.status(400).json {errors}  if errors

    email = req.body.email
    password = req.body.password

    models.getUser email, {includePassword: true}
        .then ->
            # Email already exists, so return an error
            res.status(400).json {error: 'Email already exists'}
        .catch (err) ->
            return res.status(500).json {error: 'Unknown error occured'} unless models.helpers.notFound err

            newUser = new models.User
                email: email
                password: auth.hashPassword password

            newUser.saveAll()
                .then (user) -> res.json user
                .catch (err) -> res.status(500).json {error: 'Error creating user', message: err.message}

exports.postLogin = (req, res) ->
    res.json {user: models.prepareUser req.user}