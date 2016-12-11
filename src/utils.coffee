{ MongoClient } = require('mongodb')
urlBuilder = require('./url-builder')
_ = require('lodash')

DEFAULT_POOL_SIZE = 5

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

exports.connect = (config, cb) ->
  options = _buildOptions(config)

  url = urlBuilder.buildMongoConnString(config)
  MongoClient.connect url, options, cb

exports.repeatString = (str, n) ->
  Array(n + 1).join(str)
