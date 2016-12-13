_ = require 'lodash'
{ repeatString, loadMigrationsFromDir, slugify, writeFile } = require('./utils')
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

  runFromDir: (dir, done, progress) ->
    loadMigrationsFromDir dir, (err, files) =>
      if err
        return done err
      @bulkAdd _.map(files, 'module')
      @migrate done, progress

  create: (dir, id, done, coffeeScript=false) ->
    loadMigrationsFromDir dir, (err, files) ->
      if err
        return done err
      maxNum = _.maxBy(files, 'number')?.number ? 0
      nextNum = maxNum + 1
      slug = slugify(id)
      ext = if coffeeScript then 'coffee' else 'js'
      fileName = "#{nextNum}-#{slug}.#{ext}"
      body = migrationStub(id, coffeeScript)
      writeFile(dir, fileName, body, done)

  dispose: (cb) ->
    @_runner.dispose(cb)

module.exports.Migrator = Migrator
