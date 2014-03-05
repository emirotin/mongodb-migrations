mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator', ->
  migrator = null
  db = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {migrator, db} = res
      coll = db.collection 'test'
      done()

  it 'should exist', (done) ->
    migrator.should.be.ok
    db.should.be.ok
    done()

  it 'should run migrations and return result', (done) ->
    coll.remove {}, ->
      migrator.add
        id: 1
        up: (cb) ->
          coll.insert name: 'tobi', cb
      migrator.migrate (err, res) ->
        (!err).should.be.ok
        res.should.be.ok
        res[0].id.should.be.equal 1
        res[0].result.status.should.be.equal 'ok'
        done()

