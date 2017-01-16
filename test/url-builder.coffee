mm = require '../src/mongodb-migrations'
urlBuilder = require '../src/url-builder'

describe 'Url Builder', ->

  it 'uses the url as given', (done) ->
    config =
      url: 'mongodb://aaa.bb.ccc:27101/some-db?ssl=true'

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal config.url
    done()

  it 'builds a single node url', (done) ->
    config =
      user: 'someuser'
      password: 'somepass'
      host: 'abcde',
      port: 27111
      db: '_mm'
      collection: '_migrations'

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal "mongodb://#{config.user}:#{config.password}@" +
      "#{config.host}:#{config.port}/#{config.db}"
    done()

  it 'builds a single node url with ssl', (done) ->
    config =
      user: 'someuser'
      password: 'somepass'
      host: 'abcde',
      port: 27111
      db: '_mm'
      collection: '_migrations',
      ssl: true

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal "mongodb://#{config.user}:#{config.password}@" +
      "#{config.host}:#{config.port}/#{config.db}?ssl=true"
    done()

  it 'builds a single node url with an authDatabase', (done) ->
    config =
      user: 'someuser'
      password: 'somepass'
      host: 'abcde',
      port: 27111
      db: '_mm'
      collection: '_migrations',
      authDatabase: 'admin'

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal "mongodb://#{config.user}:#{config.password}@" +
      "#{config.host}:#{config.port}/#{config.db}?authSource=#{config.authDatabase}"
    done()

  it 'builds a replicaset url with two replicas', (done) ->
    config =
      user: 'someuser'
      password: 'somepass'
      replicaset:
        name: 'rs-ds023680'
        members: [
          {
            host: 'bee.boo.bar'
            port: 23680
          }
          {
            host: 'choo.choo'
            port: 24610
          }
        ]
      db: '_mm'
      collection: '_migrations'

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal "mongodb://#{config.user}:#{config.password}@" +
      "#{config.replicaset.members[0].host}:#{config.replicaset.members[0].port}," +
      "#{config.replicaset.members[1].host}:#{config.replicaset.members[1].port}/" +
      "#{config.db}?replicaSet=#{config.replicaset.name}"
    done()

  it 'builds a replicaset url with three replicas', (done) ->
    config =
      user: 'someuser'
      password: 'somepass'
      replicaset:
        name: 'rs-ds023680'
        members: [
          {
            host: 'bee.boo.bar'
            port: 23680
          }
          {
            host: 'choo.choo'
            port: 24610
          }
          {
            host: 'aaa.bbb.ccc'
            port: 22718
          }
        ]
      db: '_mm'
      collection: '_migrations'

    connString = urlBuilder.buildMongoConnString config
    connString.should.be.equal "mongodb://#{config.user}:#{config.password}@" +
      "#{config.replicaset.members[0].host}:#{config.replicaset.members[0].port}," +
      "#{config.replicaset.members[1].host}:#{config.replicaset.members[1].port}," +
      "#{config.replicaset.members[2].host}:#{config.replicaset.members[2].port}/" +
      "#{config.db}?replicaSet=#{config.replicaset.name}"
    done()
