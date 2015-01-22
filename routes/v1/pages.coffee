jwt = require 'jsonwebtoken'

auth = require '../../auth'
config = require '../../config'

module.exports.resetPassword = (req, res, next) ->
    _render = (context)->
        context.layout = false
        res.render 'resetPassword', context

    resetToken = req.query.t
    unless resetToken
        _render {msg: 'Password reset token missing. Please request a new password reset email via the app.'}
        return

    try
        jwt.verify resetToken, config.SECRET
    catch e
        _render {msg: 'Password reset token is invalid. Please request a new password reset email via the app.'}
        return

    _render {
        showResetForm: true
        resetToken: resetToken
    }