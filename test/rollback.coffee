path = require 'path'
mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator Rollback', ->
  migrator = null
  db = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {migrator, db} = res
      coll = db.collection 'test'
      coll.remove {}, ->
        done()

  it 'should cleanup the migrations collection properly', (done) ->
    dir = path.join __dirname, 'migrations'
    migrator.runFromDir dir, (err, res) ->
      return done(err) if err
      migrator.rollback (err, res) ->
        return done(err) if err
        coll.find().count (err, count) ->
          return done(err) if err
          count.should.be.equal 0

          migrationsCol = db.collection '_migrations'
          migrationsCol.find().count (err, count) ->
            return done(err) if err
            count.should.be.equal 0
            done()
