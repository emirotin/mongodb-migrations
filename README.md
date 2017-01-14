# mongodb-migrations

> A Node.js migration framework for MongoDB with both programmatic and CLI API.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Installation](#installation)
- [Common Usage (CLI)](#common-usage-cli)
  - [Configuration](#configuration)
  - [Creating Migrations](#creating-migrations)
    - [Migration functions](#migration-functions)
  - [Sample migration file](#sample-migration-file)
  - [Running migrations](#running-migrations)
- [Programmatic usage](#programmatic-usage)
  - [Creating `Migrator` object](#creating-migrator-object)
    - [Custom logging](#custom-logging)
  - [Adding migrations](#adding-migrations)
    - [`migrator.add`](#migratoradd)
    - [`migrator.bulkAdd`](#migratorbulkadd)
  - [`migrator.migrate`](#migratormigrate)
  - [`migrator.runFromDir`](#migratorrunfromdir)
  - [`migrator.rollback`](#migratorrollback)
  - [`migrator.create`](#migratorcreate)
  - [`migrator.dispose`](#migratordispose)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Installation

```bash
  npm install mongodb-migrations --save
```

## Common Usage (CLI)

The package installs a single CLI executable — `mm`.

When installing locally to your project this executable can be found at
`./node_modules/.bin/mm`.

When installing globally (normally not recommended) the executable should
automatically become accessible on your PATH.

### Configuration

The CLI app expects a configuration file to be present in the directory where
the app is being ran.

By default (if the configuration file is not set through the
command-line argument) the app checks `mm-config.json`, `mm-config.js`,
and `mm-config.coffee` files for existence.

File name can be passed through the means of `--config` parameter.
The path is relative to the current directory:

```bash
  mm --config=configs/mm.json
```

In case of `json` the file should contain valid JSON representation of the
configuration object.

In case of `js` or `coffee` the file should be a CommonJS module
exporting the configuration object. This is useful when you already have configuration
data (potentially in a different format) and want to avoid duplication. See `test/mm-config.coffee`
for an example of this usage.

In case of `coffee` the `coffee-script >= 1.7.0` package must be importable
from the current directory (include it as your project's dependency).

The configuration object can have the following keys:

* `url` — full MongoDB connection url (_optional_, when used the rest of the connection params (`host`, `port`, `db`, `user`, `password`, `replicaset`, `authDatabase`) are ignored),
* `host` — MongoDB host (_optional_ when using `url` or `replicaset`, **required** otherwise),
* `port` _[optional]_ — MongoDB port,
* `db` — MongoDB database name,
* `ssl` _[optional]_ - boolean, if `true`, `'?ssl=true'` is added to the MongoDB URL,
* `user` _[optional]_ — MongoDB user name when authentication is required,
* `password` _[optional]_ — MongoDB password when authentication is required,
* `authDatabase` _[optional]_ - MongoDB database to authenticate the user against,    
* `collection` _[optional]_ — The name of the MongoDB collection to track already ran migrations, **defaults to `_migrations`**,
* `directory` — the directory (path relative to the current folder) to store migration files in and read them from, used when running from the command-line or when using `runFromDir`,
* `timeout` _[optional]_ — time in milliseconds after which migration should fail if `done()` is not called (use 0 to disable timeout)
* `poolSize` _[optional, **deprecated, use `options.server.poolSize` instead**]_ - the size of the mongo connection pool,
* `options` _[optional]_ - arbitrary options passed to the MongoClient (_Note: if not set directly, `options.server.poolSize` defaults to `5`._),
* `replicaset` _[optional]_ - if using replica sets should be an object of the following structure:
```
name: 'rs-ds023680',
members: [
  {
    host: 'bee.boo.bar',
    port: 23680
  }
  {
    host: 'choo.choo',
    port: 24610
  }
]
```

### Creating Migrations

The app simplifies creating migration stubs by providing a command

```bash
  mm create MIGRATION-NAME [--coffee|-c]
```

This creates automatically numbered file `NNN-migration-name.js`
(or `.coffee` if `-c` of `--coffee` flag provided)
inside of the `directory` defined in the
[configuration](#configuration) file.

The migration file must be a CommonJS module exporting the
following:

* `id` — a string that's used to identify the migration
(filled automatically when creating migrations through `mm create`).
* `up` _[optional]_ — a function used for forward migration.
* `down` _[optional]_ — a function used for backward migration (rollback).

See [Configuration](#configuration) if your config file has
non-standard name.

#### Migration functions

The `up` and `down` functions take a single parameter — a Node-style callback:

```javascript
module.exports.up = function (done) {
  // call done() when migration is successfully finished
  // call done(error) in case of error
}
```

The `up` and `down` functions are executed with the scope
providing 2 convenient properties:

* `this.db` is an open MongoDB
[native driver](http://mongodb.github.io/node-mongodb-native/)
connection. Useful if you are not using any ODM library.
* `this.log` is a function allowing you to print
informative messages during the progress of your migration.
By default these messages are printed to `stdout` with proper indentation.
See [Custom logging](#custom-logging) for advanced usage.


### Sample migration file

```javascript
exports.id = 'create-toby';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.insert({ name: 'tobi' }, done);
};

exports.down = function (done) {
  var coll = this.db.collection('test');
  coll.remove({}, done);
};
```

### Running migrations

Run all migrations from the `directory` (specified in
[Configuration](#configuration)) by simply calling

```bash
mm
```

or

```bash
mm migrate
```

The utility only runs migrations that:

1. have `up` function defined,
1. were not ran before against this database.

Ran migrations are recorded in the `collection`
specified in [Configuration](#configuration).

**NOTE:** If there are some noop migrations (those without the `up` method)
they will be recorded in the `collection`, too.
See [`migrator.migrate`](#migratormigrate) for the explanation why.

The migration process is stopped instantly if some migration fails
(returns error in its callback).

See [Configuration](#configuration) if your config file has
non-standard name.

If you have `.coffee` migration files, `coffee-script >= 1.7.0` package
must be importable from the current directory.

### Debugging migrations

```bash
DEBUG=true mm
```

Running with `DEBUG=true` will print out the error stack on the console.

## Programmatic usage

The library also supports programmatic usage.

Start with `require`'ing it:

```javascript
var mm = require('mongodb-migrations');
```

### Creating `Migrator` object

Next, you have to create a `Migrator` object. The syntax is:

```javascript
var migrator = new mm.Migrator(config, [customLogFn]);
```

Where `config` is an object with the keys defined in the
[Configuration](#configuration) section (except of the `directory`
which does not make sense in this scenario).

#### Custom logging

By default when migrations are ran `migrator` will log
it's progress to console — 1 line for each migration added,
indicating the status (skipped, succeeded or failed).
It will also print any custom messages you pass to
`this.log` inside of the `up` / `down` function.

To suppress this logging pass `customLogFn = null` to the
`Migrator` constructor (`undefined` won't do the trick).

If you want to handle the logging on your own (save it to file, or
whatever else) you can pass your custom function having this signature:

```javascript
function customLogFn(level, message),
```

where `level` is either `"system"` (migration status message)
or `"user"` (when you call `this.log` inside of your migration),
and `message` is the actual message string.

### Adding migrations

Once you have the `migrator` object you can add migrations
definitions to it.

#### `migrator.add`

To add a single migration, call

```javascript
migrator.add(migrationDef),
```

where `migrationDef` is an object with `id`, `up` _[optional]_,
and `down` _[optional]_ keys, all having the same meaning
as described in [Creating Migrations](#creating-migrations).

#### `migrator.bulkAdd`

To add multiple migrations at once, call

```javascript
migrator.bulkAdd(migrationDefsArray),
```

where `migrationDefsArray` is an array of objects explained in
[migrator.add](#migratoradd).

### `migrator.migrate`

Once you have one or more migrations added, run them with calling

```javascript
migrator.migrate(doneFn, [progressFn]).
```

Migrations are ran in order they were added to the `migrator`.

The `doneFn` is called once all migrations are ran or once one of them
fails. The function has the signature

```javascript
function doneFn(error, results),
```

where `error` is `null` if everything is OK, or is an error
returned by the failed migration (if any).

The `results` object is always passed (even in case of an error).

Its keys are `id`s of the added migrations
(till the one that failed, if any, or till the last one).
The values are `result` objects having the following properties:

* `status` — `'ok'`, `'skip'`, or `'error'`,
* `error` - the `error` object returned from the failed migration,
* `reason` — the reason why the migration was skipped, can be
`"no migration function for direction up"`,
`"no migration function for direction down"`,
`"migration already ran"`,
`"migration wasn't in the recent migrate run"`, See [Rollback](#migratorrollback) for the explanation of the last case,
* `code` — a more machine-friendly version of `reason`, can be `"no_up"`, `"no_down"`, `"already_ran"`, `"not_in_recent_migrate"`.

The optional `progressFn` function is called once per each migration
and has the signature

```javascript
function progressFn(id, result),
```

where `id` is migration's ID, and `result` object is explained above.

Successfully ran migrations are recorded in the `collection`
specified in [Configuration](#configuration).

**NOTE:** for consistency and for the proper rollback operation migrations that
do not define the `up` methods (and thus are skipped) are still recorded in
the DB as being ran which is formally true as they are essentially noop.

This means that if one of your migrations has an issue, you roll back,
then fix this issue and rerun the migrations,
the entire set will be re-applied (as rollback assumes the DB is restored to the
pre-`migrate` state).

Obviously, this will lead to unexpected results if you don't properly define the
`down` methods where they are required.

### `migrator.runFromDir`

In case your migrations are modules in specific directory
(see [Running migrations](#running-migrations)) there's a convenience method
that reads them in order and then runs.

The files must conform to the following rules:

1. have their names starting with one or more digits
(this number defines the migrations order) — proper naming is held when
[Creating Migrations](#creating-migrations) using the CLI `mm` tool,
1. be CommonJS modules and export `id`, `up` _[optional]_,
and `down` _[optional]_ — see [Creating Migrations](#creating-migrations)
for explanation,
1. have filenames ending in `.js` or `.coffee`;
1. if the migration file has `.coffee` extension, the
`coffee-script >= 1.7.0` package must be importable
from the current directory.

To run the migrations from the `directory` call

```javascript
migrator.runFromDir(directory, doneFn, [progressFn])
```

The `doneFn` and `progressFn` have the same meaning as in
[migrator.migrate](#migratormigrate).


### `migrator.rollback`

If you decide that current migration run was unsuccessful,
you can roll back all recently ran transactions. Currently this
operation is only supported through programatic interface.

Do so by calling

```javascript
migrator.rollback()
```

This runs all the migrations added to the `migrator`
in the reverse order, and follows these rules:

1. migrations without the `down` method are skipped (but see the note below),
1. migrations not ran recently (potentially those
after the failed one) are skipped.

**NOTE:** Rolling back removes the migration records from the DB.
It's true even for the migrations that _do not_ have the `down` part.

### `migrator.create`

To programmatically create a migration stub file, call

```javascript
migrator.create(directory, id, doneFn, coffeeScript=false),
```

where `directory` is the directory to save the file to,
`id` is migration's ID, `doneFn` is a callback that gets
passed the error object in case of error,
and optional `coffeeScript` flag tells the library to create the stub
in CoffeeScript instead of plain JavaScript.

The ID is lowercased and then dasherized. It's your
responsibility to assure it's unique.

The method automatically handles files numbering and naming,
and sets the ID inside of the generated file.

### `migrator.dispose`

When you are done with the migrator you should call

```javascript
migrator.dispose(cb)
```

to release the MongoDB connections pool. Once disposed the migrator cannot be used anymore.

The `cb` is a Node-style callback:

```javascript
function cb(error).
```
