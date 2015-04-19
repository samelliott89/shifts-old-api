{createModel} = require './modelHelpers'
Promise = require 'bluebird'
_errs = require '../errors'

module.exports = createModel 'Query', {
    id: String
    name: String
    javascript: String
    coffeescript: String
}

{helpers, model} = module.exports