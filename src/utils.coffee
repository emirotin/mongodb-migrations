MongoClient = require('mongodb').MongoClient
urlBuilder = require('./url-builder')
_ = require('lodash')

DEFAULT_POOL_SIZE = 5

exports.connect = (config, cb) ->
  poolSize = config.poolSize ? DEFAULT_POOL_SIZE

  url = urlBuilder.buildMongoConnString(config)
  options = config.options || {}
  _.set(options, 'server.poolSize', poolSize)

  MongoClient.connect url, options, cb

exports.repeatString = (str, n) ->
  Array(n + 1).join(str)
