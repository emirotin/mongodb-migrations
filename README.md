# mongodb-migrations


> A Node.js migration framework for MongoDB with both programmatic and CLI API.

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

In case of `js` or `coffee` the file should be a CommonJS module exporting the
configuration object.

In case of `coffee` the `coffee-script >= 1.7.0` package must be importable
from the current directory (include it as your project's dependency).

The configuration object can have the following keys:

* `host` — MongoDB host
* `port` — MongoDB port
* `db` — MongoDB database name
* `user` _[optional]_ — MongoDB user name when authentication is required
* `password` _[optional]_ — MongoDB password when authentication is required
* `collection` — The name of the MongoDB collection to track
already ran migrations
* `directory` — the directory (path relative to the current folder)
to store migration files in and read them from.

### Creating Migrations

The app simplifies creating migration stubs by providing a command

```bash
  mm create MIGRATION-NAME [--coffee|-c]
```

This creates automatically numbered file `NNN-migration-name.js`
(or `.coffee` if `-c` of `--coffee` flag provided)
inside of the `directory` defined in the [configuration](#configuration) file.

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

Run all migrations from the directory by simply calling

```bash
mm
```

or

```bash
mm migrate
```

See [Configuration](#configuration) if your config file has
non-standard name.

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
whatever else) you can pass you custom function having this signature:

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

where `migrationDef` is an object with `id`, `up` _[optional]_
and `down` _[optional]_ keys, all having the same meaning
as described in [Creating Migrations](#creating-migrations).

#### `migrator.bulkAdd`

To add multiple migrations at once, call

```javascript
migrator.bulkAdd(migrationDefsArray),
```

where `migrationDefsArray` is an array of objects explained in
[migrator.add](#migrator.add).

### Running

### Running from directory

### Rollback

### Creating migrations

### Tracking progress
