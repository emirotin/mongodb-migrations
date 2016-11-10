MongoClient = require('mongodb').MongoClient
urlBuilder = require('./url-builder')

DEFAULT_POOL_SIZE = 5

exports.connect = (config, cb) ->
  poolSize = config.poolSize ? DEFAULT_POOL_SIZE

  # Default to infinite read timeout for mongo operations.
  # (mongodb default is 30 sec.)
  socketTimeoutMS = config.socketTimeoutMS ? 0

  url = urlBuilder.buildMongoConnString(config)
  MongoClient.connect url, {
    server: { poolSize },
    socketTimeoutMS: socketTimeoutMS
  }, cb

exports.repeatString = (str, n) ->
  Array(n + 1).join(str)
