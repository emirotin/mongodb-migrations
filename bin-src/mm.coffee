# A CLI utility for mongodb-migrations

fs = require('fs')
path = require('path')
optparser = require('nomnom')
_ = require('lodash')
Promise = require('bluebird')

mm = require('..')
{ connect } = require('../lib/utils')
Migrator = mm.Migrator

debug = !!process.env.DEBUG

defaults =
  directory: "migrations"

dir = process.cwd()

config = null

readConfig = (fileName) ->
  if config
    return

  if not fileName
    for ext in ['json', 'js', 'coffee']
      fileName = "mm-config.#{ext}"
      if fs.existsSync path.join dir, fileName
        break
      fileName = null

  if not fileName
    exit "Config file not specified, default not found"

  try
    fileName = path.join dir, fileName
    if fileName.match /\.coffee$/
      require('coffee-script/register')
    config = _.assign {}, defaults, require(fileName)
  catch e
    exit fileName + " cannot be imported", e

cwd = ->
  path.join dir, config.directory

createMigrator = ->
  new Migrator config

runMigrations = (opts) ->
  readConfig opts.config
  createMigrator().runFromDir cwd(), exit

createMigration = (opts) ->
  readConfig opts.config
  id = opts._[1..].join ' '
  if not id
    exit "Migration ID is required"
  createMigrator().create cwd(), id, exit, opts.coffee

exit = (msg, err) ->
  if msg
    console.error "Error: " + msg
    if debug and err?.stack
      console.error err.stack
    process.exit 1
  process.exit 0

dedupe = (opts) ->
  readConfig opts.config
  Promise.fromCallback (cb) ->
    connect config, cb
  .then (db) ->
    return db.collection(config.collection)
  .then (coll) ->
    console.log('Loading the list of migration records...')
    coll.find({}).toArray()
    .then (docs) ->
      console.log("Found total of #{docs.length} records. Detecting uniques")
      knownIds = {}
      mongoIdsToRemove = []
      uniqueIds = 0
      docs.forEach (d) ->
        if knownIds[d.id]
          mongoIdsToRemove.push(d._id)
        else
          knownIds[d.id] = true
          uniqueIds += 1
      console.log("Found #{uniqueIds} unique records. #{mongoIdsToRemove.length} to remove")
      if debug
        console.log(mongoIdsToRemove)

      return mongoIdsToRemove
    .then (mongoIdsToRemove) ->
      coll.deleteMany(_id: $in: mongoIdsToRemove)
  .then ->
    console.log('Done')
    exit()
  .catch (err) ->
    exit err.message, err

optparser
  .script 'mm'
  .option 'config',
    metavar: 'FILE'
    help: """
      The name of the file in the current directory, can be .js, or .json, or .coffee.
      For .coffee, the `coffee-script` >= 1.7.0 package must be importable from the current directory.
    """

optparser
  .command 'migrate'
  .callback runMigrations

optparser
  .nocommand()
  .callback runMigrations

optparser
  .command 'create'
  .option 'coffee',
    abbr: 'c'
    flag: true
    help: 'Generate migration stub in CoffeeScript'
  .callback createMigration

optparser
  .command 'dedupe'
  .help 'Remove duplicate entries from the migrations collection. Fixes the regression introduced by 0.8.0 and fixed in 0.8.2.'
  .callback dedupe

optparser.parse()
