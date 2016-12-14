path = require 'path'
{ MigrationsRunner } = require '../src/migrations-runner'
testsCommon = require './common'

describe 'MigrationsRunner', ->
  dbConfig = null
  coll = null

  beforeEach (done) ->
    testsCommon.beforeEach (res) ->
      {db, config} = res
      dbConfig = config

      coll = db.collection 'test'
      coll.remove {}, ->
        done()

  it 'should set default migrations collection', (done) ->
    config1 =
      host: 'localhost'
      port: 27017
      db: '_mm'
    m1 = new MigrationsRunner config1, null
    m1._collName.should.be.equal('_migrations')

    config2 =
      host: 'localhost'
      port: 27017
      db: '_mm'
      collection: '_custom'
    m2 = new MigrationsRunner config2, null
    m2._collName.should.be.equal('_custom')

    done()

  it 'should run migrations up in order', (done) ->
    migrations = [
      {
        id: '1'
        up: (done) ->
          @db.collection('test').insert({ x: 2, runnerTest: true }, done)
      }
      {
        id: '2'
        up: (done) ->
          @db.collection('test').update({ runnerTest: true }, { $mul: x: 2 }, done)
      }
      {
        id: '3'
        up: (done) ->
          @db.collection('test').update({ runnerTest: true }, { $inc: x: 3 }, done)
      }
    ]
    runner = new MigrationsRunner dbConfig
    runner.runUp migrations, (err, res) ->
      return done(err) if err
      (!!res).should.be.ok()
      res['1'].status.should.be.equal('ok')
      res['2'].status.should.be.equal('ok')
      res['3'].status.should.be.equal('ok')
      coll.find({}).toArray (err, docs) ->
        return done(err) if err
        (docs).should.be.ok()
        docs.length.should.be.equal(1)
        docs[0].x.should.be.equal(7)
        done()
    return

  it 'should run migrations down in order', (done) ->
    migrations = [
      {
        id: '3'
        down: (done) ->
          @db.collection('test').insert({ x: 2, runnerTest: true }, done)
      }
      {
        id: '2'
        down: (done) ->
          @db.collection('test').update({ runnerTest: true }, { $mul: x: 2 }, done)
      }
      {
        id: '1'
        down: (done) ->
          @db.collection('test').update({ runnerTest: true }, { $inc: x: 3 }, done)
      }
    ]
    runner = new MigrationsRunner dbConfig
    runner.runUp migrations.slice().reverse(), (err, res) ->
      return done(err) if err
      runner.runDown migrations, (err, res) ->
        return done(err) if err
        (!!res).should.be.ok()
        res['1'].status.should.be.equal('ok')
        res['2'].status.should.be.equal('ok')
        res['3'].status.should.be.equal('ok')
        coll.find({}).toArray (err, docs) ->
          return done(err) if err
          (docs).should.be.ok()
          docs.length.should.be.equal(1)
          docs[0].x.should.be.equal(7)
          done()
    return

  it 'should run migrations up from directory', (done) ->
    dir = path.join __dirname, 'migrations'
    runner = new MigrationsRunner dbConfig
    runner.runUpFromDir dir, (err, res) ->
      return done(err) if err
      coll.find({name: 'tobi'}).count (err, count) ->
        return done(err) if err
        count.should.be.equal 1

        coll.find({name: 'loki'}).count (err, count) ->
          return done(err) if err
          count.should.be.equal 1

          coll.find({ok: 1}).count (err, count) ->
            return done(err) if err
            count.should.be.equal 2
            done()

  it 'should run migrations down from directory', (done) ->
    dir = path.join __dirname, 'migrations'
    runner = new MigrationsRunner dbConfig

    runner.runUpFromDir dir, (err, res) ->
      return done(err) if err
      coll.find({name: 'loki'}).count (err, count) ->
        return done(err) if err
        count.should.be.equal(1)

        runner.runDownFromDir dir, (err, res) ->
          return done(err) if err
          coll.find({name: 'loki'}).count (err, count) ->
            return done(err) if err
            count.should.be.equal 0
            done()

  it 'should run specific migrations up from directory', (done) ->
    dir = path.join __dirname, 'migrations'
    runner = new MigrationsRunner dbConfig

    runner.runSpecificUpFromDir dir, ['1', 'test3'], (err, res) ->
      return done(err) if err
      coll.find({}).toArray (err, docs) ->
        return done(err) if err
        (!!docs).should.be.ok()
        docs.length.should.be.equal(1)
        docs[0].name.should.be.equal('tobi')
        docs[0].ok.should.be.equal(1)
        done()

  it 'should run specific migrations down from directory', (done) ->
    dir = path.join __dirname, 'migrations'
    runner = new MigrationsRunner dbConfig

    runner.runUpFromDir dir, (err, res) ->
      return done(err) if err
      runner.runSpecificDownFromDir dir, ['test3', '2-test2.js'], (err, res) ->
        return done(err) if err
        coll.find({}).sort(name: 1).toArray (err, docs) ->
          return done(err) if err
          (!!docs).should.be.ok()
          docs.length.should.be.equal(2)
          docs[0].name.should.be.equal('loki')
          docs[0].ok.should.be.equal(2)
          docs[1].name.should.be.equal('tobi')
          docs[1].ok.should.be.equal(2)
          done()
