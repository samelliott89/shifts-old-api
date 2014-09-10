## Getting started

* `$ git clone git@github.com:Shifts/shifts-api.git`
* `$ cd shifts-api`
* `$ npm install`

The Shifts API uses rethinkDB as it's data store.

Run `$ coffee app.coffee` to start the server.

## Contributing

### Style Guide

The Shifts API uses a style guide as defined in `.jshintrc`. Make sure your editor has jshint enabled and that your commits are jshint compliant.

A few items of note are:

* Indentations should not be tabs and should consist of 4 spaces.
* All variables, parameters and properties should be `camelCase` and NOT `snake_case`.
* Strings should use single quotes (`'`).
* Comparisons should use the identity operator `===` wherever possible over the equality operator `==`.
* There should be no trailing space.
