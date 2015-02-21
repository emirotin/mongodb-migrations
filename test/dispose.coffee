path = require 'path'
mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator Dispose', ->

  it.skip 'should be disposable', (done) ->
    migrator = new mm.Migrator testsCommon.config, null
    dir = path.join __dirname, 'migrations'
    migrator.runFromDir dir, (err, res) ->
      return done(err) if err
      migrator.dispose (err) ->
        return done(err) if err
        done()
        migrator.rollback (err) ->
          (err?).should.be.ok
          err.message.should.have.string 'disposed'
          done()
