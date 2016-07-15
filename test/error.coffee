mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator Errors Handling', ->
  migrator = null
  db = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {migrator, db} = res
      coll = db.collection 'test'
      coll.remove {}, ->
        done()

  it 'should run migrations and stop on the first error', (done) ->
    migrator.add
      id: '1'
      up: (cb) ->
        cb null
    migrator.add
      id: '2'
      up: (cb) ->
        cb null
    migrator.add
      id: '3'
      up: (cb) ->
        cb new Error 'Some error'
    migrator.add
      id: '4'
      up: (cb) ->
        cb null
    migrator.migrate (err, res) ->
      err.toString().should.endWith 'Some error'

      res.should.be.ok()

      res['1'].should.be.ok()
      res['1'].status.should.be.equal 'ok'

      res['2'].should.be.ok()
      res['2'].status.should.be.equal 'ok'

      res['3'].should.be.ok()
      res['3'].status.should.be.equal 'error'
      res['3'].error.toString().should.endWith 'Some error'

      (!res['4']).should.be.ok()

      done()
