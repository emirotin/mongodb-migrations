# mongodb-migrations


> A Node.js migration framework for MongoDB with both programmatic and CLI API.

## Installation

```
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

```
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

```
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

#### Migration functions

The `up` and `down` functions take a single parameter — a Node-style callback:

```
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
By default these messages are printed to `stdout` with proper indentation
(see [Custom logging](#custom-logging) for advanced usage).


### Sample migration file

### Running migrations

## Programmatic usage

### Creating `Migrator` object

#### Custom logging

### Adding migrations

#### `.add`
#### `.bulkAdd`

### Running

### Running from directory

### Creating migrations

### Tracking progress
