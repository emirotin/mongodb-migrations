fs = require 'fs'
path = require 'path'
Q = require 'q'
_ = require 'lodash'
mongoPool = require 'mongo-pool2'

class Migrator
  constructor: (dbConfig) ->
    @_m = []
    @_result = {}
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
      @_result = {}
      m = @_m
    @_lastDirection = direction

    log = (depth) ->
      tab = Array(depth).join(' ')
      ->
        args = [ tab ].concat arguments
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
        @_result[migration.id] = res
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

      if (not fn \
        or (direction == 'up' and id of @_ranMigrations) \
        or (direction == 'down' and id not of @_result)
      )
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

  _loadMigrationFiles: (dir, cb) ->
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
    @_loadMigrationFiles dir, (err, files) =>
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

module.exports.Migrator = Migrator