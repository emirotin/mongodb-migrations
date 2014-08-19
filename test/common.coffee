mongoPool = require 'mongo-pool2'
mm = require '../src/mongodb-migrations'

config =
  host: 'localhost'
  port: 27017
  db: '_mm'
  collection: '_migrations'

module.exports =
  config: config

  beforeEach: (done) ->
    mongoPool.connect config, (err, db) ->
      if err
        return done err
      db.collection(config.collection).remove {}, ->
        migrator = new mm.Migrator config, null
        done { migrator, db }
