mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrator Progress Reporting', ->
  it 'should call back the progress parameter', (done) ->
    messages = []
    log = (level, message) ->
      if level == 'user'
        messages.push message

    migrator = new mm.Migrator testsCommon.config, log

    migrator.add
      id: '1'
      up: (cb) ->
        this.log '1'
        cb()
    migrator.add
      id: '2'
      up: (cb) ->
        this.log '2'
        cb()

    resultsCount = 0

    migrator.migrate (err, res) ->
      return done(err) if err
    , (migrationId, migrationRes) ->
      status = migrationRes?.status
      if status != 'ok'
        message = "Error running #{migrationId}, result is #{status}"
        return done(new Error(message))
      resultsCount += 1
      return done() if resultsCount == 2
