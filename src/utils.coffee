MongoClient = require('mongodb').MongoClient
urlBuilder = require('./url-builder')

DEFAULT_POOL_SIZE = 5

exports.connect = (config, cb) ->
  poolSize = config.poolSize ? DEFAULT_POOL_SIZE

  url = urlBuilder.buildMongoConnString(config)
  MongoClient.connect url, { server: { poolSize } }, cb
