path = require 'path'
mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Is up to date from Directory', ->
  migrator = null
  db = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {migrator, db} = res
      coll = db.collection 'test'
      coll.remove {}, ->
        done()

  it 'be false if migrations were not ran', (done) ->
    dir = path.join __dirname, 'migrations'
    migrator.isUpToDateFromDir dir, (err, res) ->
      return done(err) if err
      res.should.be.equal false
      done()

  it 'be true if migrations were ran', (done) ->
    dir = path.join __dirname, 'migrations'
    migrator.runFromDir dir, (err) ->
      return done(err) if err
      migrator.isUpToDateFromDir dir, (err, res) ->
        return done(err) if err
        res.should.be.equal true
        done()
