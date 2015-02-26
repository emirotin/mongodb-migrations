fs = require 'fs'
path = require 'path'
Q = require 'q'
_ = require 'lodash'
mkdirp = require 'mkdirp'
mongoConnect = require('./utils').connect

class Migrator
  constructor: (dbConfig, logFn) ->
    @_isDisposed = false
    @_m = []
    @_result = {}
    deferred = Q.defer()
    @_dbReady = deferred.promise
    mongoConnect dbConfig, (err, db) =>
      if err
        deferred.reject err
      else
        @_db = db
        deferred.resolve()
    @_collName = dbConfig.collection

    if logFn or logFn == null
      @log = logFn
    else
      @log = (src, msg) ->
        # TODO: console.error.bind(console, 'connection error:')
        pad = Array(if src == 'system' then 6 else 4).join(' ')
        console.log pad + msg

  add: (m) ->
    # m must be an { id, up, down } object
    @_m.push m

  bulkAdd: (array) ->
    # array must be an Array of { id, up, down } objects
    @_m = @_m.concat array

  _coll: ->
    @_db.collection(@_collName)

  _runWhenReady: (direction, cb, progress) ->
    if @_isDisposed
      return cb new Error 'This migrator is disposed and cannot be used anymore'
    onSuccess = =>
      @_ranMigrations = {}
      @_coll().find().toArray (err, docs) =>
        if err
          return cb err
        for doc in docs
          @_ranMigrations[doc.id] = true
        @_run direction, cb, progress
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
      @_result = {}
      m = @_m
    @_lastDirection = direction

    logFn = @log
    log = (src) ->
      (msg) ->
        logFn?(src, msg)
    userLog = log('user')
    systemLog = log('system')

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
        @_result[migration.id] = res
        _.defer ->
          progress?(migration.id, res)
        msg = "Migration '#{migration.id}': #{res.status}"
        if res.status == 'skip'
          msg += " (#{res.reason})"
        systemLog msg
        if res.status == 'error'
          systemLog '  ' + res.error
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

      skipReason = null
      if not fn
        skipReason = "no migration function for direction #{direction}"
      if direction == 'up' and id of @_ranMigrations
        skipReason = "migration already ran"
      if direction == 'down' and id not of @_result
        skipReason = "migration wasn't in the recent `migrate` run"
      if skipReason
        migrationDone status: 'skip', reason: skipReason
        return runOne()

      context = { db: @_db, log: userLog }
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

  _loadMigrationFiles: (dir, cb) ->
    mkdirp dir, 0o0774, (err) ->
      if err
        return cb err
      fs.readdir dir, (err, files) ->
        if err
          return cb err
        files = files
          .map (f) ->
            n = f.match(/^(\d+)/)?[1]
            if n
              n = parseInt n, 10
            else n = null
            [n, f]
          .filter (f) -> !!f[0]
          .sort (f1, f2) -> f1[0] - f2[0]
          .map (f) ->
            fileName = path.join dir, f[1]
            if fileName.match /\.coffee$/
              require('coffee-script/register')
            [f[0], require fileName]
        cb null, files

  runFromDir: (dir, done, progress) ->
    @_loadMigrationFiles dir, (err, files) =>
      if err
        return done err
      @bulkAdd files.map (f) -> f[1]
      @migrate done, progress

  create: (dir, id, done, coffeeScript=false) ->
    @_loadMigrationFiles dir, (err, files) ->
      if err
        return done err
      maxNum = _.max files.map (f) -> f[0]
      nextNum = Math.max(maxNum, 0) + 1
      slug = (id or '').toLowerCase().replace /\s+/, '-'
      ext = if coffeeScript then 'coffee' else 'js'
      fileName = path.join dir, "#{nextNum}-#{slug}.#{ext}"
      if coffeeScript
        body = """
          module.exports.id = "#{id}"

          module.exports.up = (done) ->
            # use @db for MongoDB communication, and @log() for logging
            done()

          module.exports.down = (done) ->
            # use @db for MongoDB communication, and @log() for logging
            done()
        """
      else
        body = """
          module.exports.id = "#{id}";

          module.exports.up = function (done) {
            // use this.db for MongoDB communication, and this.log() for logging
            done();
          };

          module.exports.down = function (done) {
            // use this.db for MongoDB communication, and this.log() for logging
            done();
          };
        """
      fs.writeFile fileName, body, done

  dispose: (cb) ->
    @_isDisposed = true
    onSuccess = =>
      try
        @_db.close()
        cb?(null)
      catch e
        cb?(e)
    @_dbReady.then onSuccess, cb

module.exports.Migrator = Migrator
