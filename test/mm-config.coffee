_ = require('lodash')
{ config } = require('./common')

module.exports = _.assign {}, config,
  directory: "created-migrations"
