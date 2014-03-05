Q = require 'q'
_ = require 'lodash'
mongoPool = require 'mongo-pool2'

class Migrator
  constructor: (dbConfig) ->
    @_m = []
    @_result = []
    deferred = Q.defer()
    @_dbReady = deferred.promise
    mongoPool.create dbConfig, (err, pool) =>
      if err
        deferred.reject err
      else
        @_pool = pool
        deferred.resolve()
    @_collName = dbConfig.collection

  add: (m) ->
    # m must be an { id, up, down } object
    @_m.push m

  bulkAdd: (array) ->
    # array must be an Array of { id, up, down } objects
    @_m = @_m.concat array

  _coll: ->
    db = @_pool.acquire()
    db.collection(@_collName)

  _runWhenReady: (direction, cb) ->
    onSuccess = =>
      @_ranMigrations = {}
      @_coll().find().toArray (err, docs) =>
        if err
          return cb err
        for doc in docs
          @_ranMigrations[doc.id] = true
        @_run direction, cb
    onError = (err) ->
      cb err
    @_dbReady.then onSuccess, onError

  _run: (direction, done, progress) ->
    if direction == 'down'
      m = _(@_m)
        .reverse()
        .filter (m) => (_r = @_result[m.id]?.status) and _r != 'skip'
        .value()
    else
      direction = 'up'
      @_result = []
      m = @_m
    @_lastDirection = direction

    log = (depth) ->
      ->
        args = [ Array(depth).join(' ') ].concat arguments
        console.log.apply console, args
    userLog = log(6)
    systemLog = log(4)

    insertPromises = []

    allDone = (err) =>
      Q.all(insertPromises).then =>
        done err, @_result

    i = 0
    l = m.length
    migrationsCollection = @_coll()
    runOne = =>
      if i >= l
        return allDone()
      migration = m[i]
      i += 1

      migrationDone = (res) =>
        @_result.push { id: migration.id, result: res }
        _.defer ->
          progress?(migration.id, res)
        systemLog 'Migration', migration.id, res.status
        if res.status == 'error'
          systemLog '  ', res.error
        if res.status == 'ok'
          deferred = Q.defer()
          insertPromises.push deferred.promise
          migrationsCollection.insert { id: migration.id }, (err) ->
            if err
              deferred.reject err
            else
              deferred.resolve()

      fn = migration[direction]
      id = migration.id

      if id of @_ranMigrations or not fn
        migrationDone status: 'skip'
        return runOne()

      context = { db: @_pool.acquire(), log: userLog }
      fn.call context, (err) ->
        if err
          migrationDone status: 'error', error: err
          allDone(err)
        else
          migrationDone status: 'ok'
          runOne()

    runOne()

  migrate: (done, progress) ->
    @_runWhenReady 'up', done, progress

  rollback: (done, progress) ->
    if @_lastDirection != 'up'
      return done new Error('Rollback can only be ran after migrate')
    @_runWhenReady 'down', done, progress

  create: (id, cb) ->

module.exports.Migrator = Migrator