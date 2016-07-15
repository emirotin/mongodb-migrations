path = require 'path'
fs = require 'fs'
rimraf = require 'rimraf'
mm = require '../src/mongodb-migrations'
testsCommon = require './common'

describe 'Migrations Builder', ->
  migrator = null
  dir = path.join __dirname, 'created-migrations'

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      { migrator } = res
      rimraf dir, done

  it 'should create migration stubs for JS', (done) ->

    migrator.create dir, 'test1', (err, res) ->
      return done(err) if err
      fs.existsSync(path.join dir, '1-test1.js').should.be.ok()
      migrator.create dir, 'test2', (err, res) ->
        return done(err) if err
        fs.existsSync(path.join dir, '2-test2.js').should.be.ok()
        done()

  it 'should create migration stubs for Coffee', (done) ->

    migrator.create dir, 'test1', (err, res) ->
      return done(err) if err
      fs.existsSync(path.join dir, '1-test1.coffee').should.be.ok()
      done()
    , true
