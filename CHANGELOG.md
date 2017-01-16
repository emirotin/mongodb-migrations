## 0.8.5

* Added support for setting authentication database via the `authSource` string.

## 0.8.4

* Migration files other than `.js` and `.coffee` **will be skipped**, along with dotfiles

## 0.8.3

* The new `dedupe` command. Run it once (`mm dedupe` with optional `--config` parameter as usual)
to remove the duplicate migration records introduced by 0.8.0.
It's important to do to ensure the migrtions collection is in valid state which is required to run the migrations down.

## 0.8.2

* Added a new machine-friendly `code` to the result in case of skipped migrations
* fix the regression when the migrations would be recorded multiple times

## 0.8.1

* update README

## 0.8.0

* _fix regression_: allow configs with `url` option
* **[breaking change]** Skipped migrations are now also recorded in the DB as being ran (and removed on rollback, see below).
* **[_potentially_ breaking change]** Fix the erroneous `rollback` behaviour where it was creating another record for the migration
instead of deleting the old one.

## 0.7.0

* Validate config object when creating the migrator instance
* **[_potentially_ breaking change]** Added default value for `collection` param: `_migrations`.
* Added support for the arbitrary connection options (passed down to `MongoClient`). Direct usage of `poolSize` is deprecated (to be removed in 1.0)
* **[_potentially_ breaking change]** Added `'use strict';` to the generated JS migration stub (@alyyousuf7).

## 0.6.2

* Added support for `timeout` options (kudos @alyyousuf7)
* Code refactoring
* Fixed tests for true-ish values

### 0.6.1

* Fix regression - wrong migration files prefix

### 0.6.0

* Migrated from Q to Bluebird
* Updated dependencies
* Added support for replicasets (kudos @antony)

## 0.5.x

### 0.5.2
* Support `config.ssl`

### 0.5.1
* Support DEBUG parameter for error stack reporting

### 0.5.0

* **[_potentially_ breaking change]** MongoDB driver updated to 2.x. If you use the `db` object in your migrations
check this [article](http://mongodb.github.io/node-mongodb-native/2.0/tutorials/changes-from-1.0/)
for the list of differences.

## 0.4.x

### 0.4.1

* hotfix release

### 0.4.0

* switched to native MongoClient.connect, removed dependency on mongo-pool2

## 0.3.x

### 0.3.1

* Added Migrator#dispose to close the MongoDB connections

### 0.3.0

* Updated mongo-pool2 to 0.1.0 which has MongoDB driver 1.4.x

## 0.2.x

### 0.2.0

* **[breaking change]** Simplify the expected config file structure — all keys are expected on the top level

## 0.1.x

### 0.1.2

* Minor README update

### 0.1.1

* Minor README update
* Technical release for fixing npm publish issue

### 0.1.0

* Full README
* More tests

## 0.0.x

### 0.0.9
Automatically pick mm-config.{js,json,coffee}

### 0.0.8
Fix for the case when migrations directory does not exist

### 0.0.7
Report exact skip reason

### 0.0.6
Binary bugfix

### 0.0.5
Binary bugfix

### 0.0.4
Binary file for creating and running migrations

### 0.0.3
Allow creating migration stubs

### 0.0.2
Allow running migrations from directory

### 0.0.1
Initial release, has tests, allows migration and rollback, only programmatic API
