Promise = require 'bluebird'
_ = require 'lodash'
{ connect: mongoConnect, normalizeConfig, loadSpecificMigrationsFromDir, loadMigrationsFromDir } = require('./utils')

class MigrationsRunner
  constructor: (dbConfig, @log = _.noop) ->
    # this will throw in case of invalid values
    dbConfig = normalizeConfig(dbConfig)

    @_isDisposed = false

    @_dbReady = new Promise.fromCallback (cb) ->
      mongoConnect dbConfig, cb
    .then (db) =>
      @_db = db

    @_collName = dbConfig.collection
    @_timeout = dbConfig.timeout

  _coll: ->
    @_db.collection(@_collName)

  _runWhenReady: (migrations, direction, cb, progress) ->
    if @_isDisposed
      return cb new Error 'This migrator is disposed and cannot be used anymore'
    onSuccess = =>
      ranMigrations = {}
      @_coll().find().toArray (err, docs) =>
        if err
          return cb err
        for doc in docs
          ranMigrations[doc.id] = true
        @_run ranMigrations, migrations, direction, cb, progress
    onError = (err) ->
      cb err
    @_dbReady.then onSuccess, onError

  _run: (ranMigrations, migrations, direction, done, progress) ->
    result = {}

    logFn = @log
    log = (src) ->
      (msg) ->
        logFn?(src, msg)
    userLog = log('user')
    systemLog = log('system')

    i = 0
    l = migrations.length
    migrationsCollection = @_coll()

    migrationsCollectionUpdatePromises = []

    handleMigrationDone = (id) ->
      p = if direction is 'up'
        Promise.fromCallback (cb) ->
          migrationsCollection.insert { id }, cb
      else
        Promise.fromCallback (cb) ->
          migrationsCollection.deleteMany { id }, cb

      migrationsCollectionUpdatePromises.push(p)

    allDone = (err) ->
      Promise.all(migrationsCollectionUpdatePromises)
      .then ->
        done err, result

    migrationContext = { db: @_db, log: userLog }
    timeout = @_timeout

    runOne = ->
      if i >= l
        return allDone()
      migration = migrations[i]
      fn = migration[direction]
      id = migration.id
      i += 1

      migrationDone = (res) ->
        result[id] = res
        _.defer ->
          progress?(id, res)
        msg = "Migration '#{id}': #{res.status}"
        if res.status is 'skip'
          msg += " (#{res.reason})"
        systemLog msg
        if res.status is 'error'
          systemLog '  ' + res.error
        if res.status is 'ok' or (res.status is 'skip' and res.code in ['no_up', 'no_down'])
          handleMigrationDone(id)


      skipReason = null
      skipCode = null
      if not fn
        skipReason = "no migration function for direction #{direction}"
        skipCode = "no_#{direction}"
      if direction is 'up' and id of ranMigrations
        skipReason = "migration already ran"
        skipCode = 'already_ran'
      if direction is 'down' and id not of ranMigrations
        skipReason = "migration wasn't in the recent `migrate` run"
        skipCode = 'not_in_recent_migrate'
      if skipReason
        migrationDone status: 'skip', reason: skipReason, code: skipCode
        return runOne()

      isCallbackCalled = false
      if timeout
        timeoutId = setTimeout () ->
          isCallbackCalled = true
          err = new Error "migration timed-out"
          migrationDone status: 'error', error: err
          allDone(err)
        , timeout

      fn.call migrationContext, (err) ->
        return if isCallbackCalled
        clearTimeout timeoutId

        if err
          migrationDone status: 'error', error: err
          allDone(err)
        else
          migrationDone status: 'ok'
          runOne()

    runOne()

  runUp: (migrations, done, progress) ->
    @_runWhenReady(migrations, 'up', done, progress)

  runDown: (migrations, done, progress) ->
    @_runWhenReady(migrations, 'down', done, progress)

  _runFromDir: (dir, direction, done, progress) ->
    loadMigrationsFromDir dir, (err, migrations) =>
      return done(err) if err
      migrations = _.map(migrations, 'module')
      if direction is 'down'
        migrations = migrations.reverse()
      @_runWhenReady(migrations, direction, done, progress)

  runUpFromDir: (dir, done, progress) ->
    @_runFromDir(dir, 'up', done, progress)

  runDownFromDir: (dir, done, progress) ->
    @_runFromDir(dir, 'down', done, progress)

  _runSpecificFromDir: (dir, migrationIds, direction, done, progress) ->
    loadSpecificMigrationsFromDir dir, migrationIds, (err, migrations) =>
      return done(err) if err
      @_runWhenReady(migrations, direction, done, progress)

  runSpecificUpFromDir: (dir, migrationIds, done, progress) ->
    @_runSpecificFromDir(dir, migrationIds, 'up', done, progress)

  runSpecificDownFromDir: (dir, migrationIds, done, progress) ->
    @_runSpecificFromDir(dir, migrationIds, 'down', done, progress)

  dispose: (cb) ->
    @_isDisposed = true
    onSuccess = =>
      try
        @_db.close()
        cb?(null)
      catch e
        cb?(e)
    @_dbReady.then onSuccess, cb

module.exports.MigrationsRunner = MigrationsRunner
