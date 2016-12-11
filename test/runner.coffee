{ MigrationsRunner } = require '../src/migrations-runner'

describe 'MigrationsRunner', ->
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
