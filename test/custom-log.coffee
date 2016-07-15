mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator Logging', ->
  it 'should allow custom logging', (done) ->
    messages = []
    log = (level, message) ->
      if level == 'user'
        messages.push message

    migrator = new mm.Migrator testsCommon.config, log

    migrator.add
      id: '1'
      up: (cb) ->
        this.log '1'
        this.log '2'
        cb()
    migrator.migrate (err, res) ->
      return done(err) if err
      res['1'].should.be.ok()
      messages.should.have.lengthOf 2
      messages[0].should.be.equal '1'
      messages[1].should.be.equal '2'
      done()
