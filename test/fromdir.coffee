path = require 'path'
mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator from Directory', ->
  migrator = null
  db = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {migrator, db} = res
      coll = db.collection 'test'
      coll.remove {}, ->
        done()

  it 'should run migrations from directory', (done) ->
    dir = path.join __dirname, 'migrations'
    migrator.runFromDir dir, (err, res) ->
      return done(err) if err
      coll.find({name: 'tobi'}).count (err, count) ->
        return done(err) if err
        count.should.be.equal 1

        coll.find({name: 'loki'}).count (err, count) ->
          return done(err) if err
          count.should.be.equal 1

          coll.find({ok: 1}).count (err, count) ->
            return done(err) if err
            count.should.be.equal 3

            migrator.rollback (err, res) ->
              return done(err) if err
              coll.find().count (err, count) ->
                return done(err) if err
                count.should.be.equal 0
                done()
