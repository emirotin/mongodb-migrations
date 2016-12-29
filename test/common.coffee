mm = require '../src/mongodb-migrations'
mongoConnect = require('../src/utils').connect

config =
  host: 'localhost'
  port: 27017
  db: '_mm'
  collection: '_migrations'
  timeout: 200

module.exports =
  config: config

  beforeEach: (done) ->
    mongoConnect config, (err, db) ->
      if err
        console.error err
        throw err
      db.collection(config.collection).remove {}, ->
        migrator = new mm.Migrator config, null
        done { migrator, db, config }
