fs = require 'fs'
path = require 'path'
_ = require 'lodash'
mkdirp = require 'mkdirp'
{ repeatString } = require('./utils')
migrationStub = require('./migration-stub')
{ MigrationsRunner } = require('./migrations-runner')

defaultLog = (src, args...) ->
  pad = repeatString(' ', if src is 'system' then 4 else 2)
  console.log(pad, args...)

class Migrator
  constructor: (dbConfig, logFn) ->
    @_m = []
    @_migrateResult = null

    if logFn is undefined
      logFn = defaultLog

    @_runner = new MigrationsRunner(dbConfig, logFn)

  add: (m) ->
    # m must be an { id, up, down } object
    @_m.push m

  bulkAdd: (array) ->
    # array must be an Array of { id, up, down } objects
    @_m = @_m.concat array

  migrate: (done, progress) ->
    @_migrateResult = null
    _done = (err, result) =>
      @_migrateResult = result
      done(err, result)
    @_runner.runUp @_m, _done, progress
    return

  rollback: (done, progress) ->
    result = @_migrateResult

    if not result
      return done new Error('Rollback can only be ran after migrate')
    @_migrateResult = null

    migrations = @_m.reverse()
      .filter (m) -> (status = result[m.id]?.status) and status != 'skip'

    @_runner.runDown migrations, done, progress
    return

  _loadMigrationFiles: (dir, cb) ->
    mkdirp dir, 0o0774, (err) ->
      if err
        return cb err
      fs.readdir dir, (err, files) ->
        if err
          return cb err
        files = files
          .filter (f) ->
            path.extname(f) in ['.js', '.coffee'] and not f.startsWith('.')
          .map (f) ->
            n = f.match(/^(\d+)/)?[1]
            if n
              n = parseInt n, 10
            else
              n = null
            return  { number: n, name: f }
          .filter (f) -> !!f.name
          .sort (f1, f2) -> f1.number - f2.number
          .map (f) ->
            fileName = path.join dir, f.name
            if fileName.match /\.coffee$/
              require('coffee-script/register')
            return { number: f.number, module: require(fileName) }
        cb null, files

  runFromDir: (dir, done, progress) ->
    @_loadMigrationFiles dir, (err, files) =>
      if err
        return done err
      @bulkAdd _.map(files, 'module')
      @migrate done, progress

  create: (dir, id, done, coffeeScript=false) ->
    @_loadMigrationFiles dir, (err, files) ->
      if err
        return done err
      maxNum = _.maxBy(files, 'number')?.number ? 0
      nextNum = maxNum + 1
      slug = (id or '').toLowerCase().replace /\s+/, '-'
      ext = if coffeeScript then 'coffee' else 'js'
      fileName = path.join dir, "#{nextNum}-#{slug}.#{ext}"
      body = migrationStub(id, coffeeScript)
      fs.writeFile fileName, body, done

  dispose: (cb) ->
    @_runner.dispose(cb)

module.exports.Migrator = Migrator
