_ = require('lodash')

buildHost = (opts) ->
  { host, port } = opts
  if port
    host += ':' + port
  return host

module.exports =
  buildMongoConnString: (config) ->
    if config.url
      return config.url

    hasUser = !!config.user
    { replicaset } = config

    s = "mongodb://"

    if hasUser
      s += config.user

    if config.password
      if not hasUser
        throw new Error '`password` provided but `user` is not'
      s += ':' + config.password

    if hasUser
      s += '@'

    if replicaset
      s += replicaset.members.map(buildHost).join ','
    else
      s += buildHost(config)

    s += '/'

    if config.db
      s += config.db

    params = []

    if replicaset
      params.push "replicaSet=#{replicaset.name}"

    if config.ssl
      params.push 'ssl=true'

    if config.authDatabase
      params.push "authSource=#{config.authDatabase}"

    if params.length > 0
      s += '?' + params.join('&')

    return s
