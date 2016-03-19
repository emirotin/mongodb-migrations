# A CLI utility for mongodb-migrations

fs = require('fs')
path = require('path')
optparser = require('nomnom')
_ = require('lodash')
debug = !!process.env.DEBUG

mm = require('..')
Migrator = mm.Migrator

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
    config = _.extend {}, defaults, require(fileName)
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

optparser.parse()
