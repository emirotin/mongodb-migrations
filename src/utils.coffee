_ = require 'lodash'
MongoClient = require('mongodb').MongoClient

DEFAULT_POOL_SIZE = 5

buildMongoConnString = (config) ->
  s = "mongodb://"

  if config.user
    hasUser = true
    s += config.user

  if config.password
    if not hasUser
      throw new Error 'Password provided but Username is not'
    s += ':' + config.password

  if hasUser
    s += '@'

  s += config.host

  if config.port
    s+= ':' + config.port

  s += '/'

  if config.db
    s += config.db

  if config.ssl
    s += '?ssl=true'

  return s

exports.connect = (config, cb) ->
  poolSize = config.poolSize ? DEFAULT_POOL_SIZE

  MongoClient.connect buildMongoConnString(config), { server: { poolSize } }, cb
