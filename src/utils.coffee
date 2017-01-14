{ MongoClient } = require('mongodb')
urlBuilder = require('./url-builder')
_ = require('lodash')

DEFAULT_POOL_SIZE = 5
DEFAULT_COLLECTION = '_migrations'

# This is a utility backward-compat method,
# it shouldn't be used directly
exports._buildOptions = _buildOptions = (config) ->
  options = config.options || {}

  { poolSize } = config
  if poolSize?
    console.warn('''
      The `poolSize` config param is deprecated.
      Use `options: { server: { poolSize: poolSize} }` instead.
    ''')
    if _.get(options, 'server.poolSize')
      console.warn('''
        The `poolSize` is overriding the `options: { server: { poolSize: poolSize} }` value.
      ''')
    _.set(options, 'server.poolSize', poolSize)

  if not _.get(options, 'server.poolSize')
    _.set(options, 'server.poolSize', DEFAULT_POOL_SIZE)

  return options

validateConnSettings = (config) ->
  return if config.url
  { replicaset } = config
  if not replicaset
    if not config.host
      throw new Error('`host` is required when `replicaset` is not set')
  else
    if not (_.isObject(replicaset) and not _.isArray(replicaset))
      throw new Error('`replicaset` is not an object')
    if not replicaset.name
      throw new Error('`replicaset.name` is not set')
    if not _.isArray(replicaset.members)
      throw new Error('`replicaset.members` is not set or is not an array')
    replicaset.members.forEach (m) ->
      if not m?.host
        throw new Error('each of `replicaset.members` must have `host` set')

  if not config.db
    throw new Error('`db` is not set')

  if config.password and not config.user
    throw new Error('`password` provided but `user` is not')

  if config.authDatabase and not config.user
    throw new Error('`authDatabase` provided but `user` is not')

exports.normalizeConfig = (config) ->
  if not (_.isObject(config) and not _.isArray(config))
    throw new Error('`config` is not provided or is not an object')

  _.defaults config,
    collection: DEFAULT_COLLECTION

  validateConnSettings(config)

  return config

exports.connect = (config, cb) ->
  options = _buildOptions(config)

  url = urlBuilder.buildMongoConnString(config)
  MongoClient.connect url, options, cb

exports.repeatString = (str, n) ->
  Array(n + 1).join(str)
