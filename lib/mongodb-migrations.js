(function() {
  var Migrator, Q, mongoPool, _;

  Q = require('q');

  _ = require('lodash');

  mongoPool = require('mongo-pool2');

  Migrator = (function() {
    function Migrator(dbConfig) {
      var deferred;
      this._m = [];
      this._result = {};
      deferred = Q.defer();
      this._dbReady = deferred.promise;
      mongoPool.create(dbConfig, (function(_this) {
        return function(err, pool) {
          if (err) {
            return deferred.reject(err);
          } else {
            _this._pool = pool;
            return deferred.resolve();
          }
        };
      })(this));
      this._collName = dbConfig.collection;
    }

    Migrator.prototype.add = function(m) {
      return this._m.push(m);
    };

    Migrator.prototype.bulkAdd = function(array) {
      return this._m = this._m.concat(array);
    };

    Migrator.prototype._coll = function() {
      var db;
      db = this._pool.acquire();
      return db.collection(this._collName);
    };

    Migrator.prototype._runWhenReady = function(direction, cb) {
      var onError, onSuccess;
      onSuccess = (function(_this) {
        return function() {
          _this._ranMigrations = {};
          return _this._coll().find().toArray(function(err, docs) {
            var doc, _i, _len;
            if (err) {
              return cb(err);
            }
            for (_i = 0, _len = docs.length; _i < _len; _i++) {
              doc = docs[_i];
              _this._ranMigrations[doc.id] = true;
            }
            return _this._run(direction, cb);
          });
        };
      })(this);
      onError = function(err) {
        return cb(err);
      };
      return this._dbReady.then(onSuccess, onError);
    };

    Migrator.prototype._run = function(direction, done, progress) {
      var allDone, i, insertPromises, l, log, m, migrationsCollection, runOne, systemLog, userLog;
      if (direction === 'down') {
        m = _(this._m).reverse().filter((function(_this) {
          return function(m) {
            var _r, _ref;
            return (_r = (_ref = _this._result[m.id]) != null ? _ref.status : void 0) && _r !== 'skip';
          };
        })(this)).value();
      } else {
        direction = 'up';
        this._result = {};
        m = this._m;
      }
      this._lastDirection = direction;
      log = function(depth) {
        var tab;
        tab = Array(depth).join(' ');
        return function() {
          var args;
          args = [tab].concat(arguments);
          return console.log.apply(console, args);
        };
      };
      userLog = log(6);
      systemLog = log(4);
      insertPromises = [];
      allDone = (function(_this) {
        return function(err) {
          return Q.all(insertPromises).then(function() {
            return done(err, _this._result);
          });
        };
      })(this);
      i = 0;
      l = m.length;
      migrationsCollection = this._coll();
      runOne = (function(_this) {
        return function() {
          var context, fn, id, migration, migrationDone;
          if (i >= l) {
            return allDone();
          }
          migration = m[i];
          i += 1;
          migrationDone = function(res) {
            var deferred;
            _this._result[migration.id] = res;
            _.defer(function() {
              return typeof progress === "function" ? progress(migration.id, res) : void 0;
            });
            systemLog('Migration', migration.id, res.status);
            if (res.status === 'error') {
              systemLog('  ', res.error);
            }
            if (res.status === 'ok') {
              deferred = Q.defer();
              insertPromises.push(deferred.promise);
              return migrationsCollection.insert({
                id: migration.id
              }, function(err) {
                if (err) {
                  return deferred.reject(err);
                } else {
                  return deferred.resolve();
                }
              });
            }
          };
          fn = migration[direction];
          id = migration.id;
          if (!fn || (direction === 'up' && id in _this._ranMigrations) || (direction === 'down' && !(id in _this._result))) {
            migrationDone({
              status: 'skip'
            });
            return runOne();
          }
          context = {
            db: _this._pool.acquire(),
            log: userLog
          };
          return fn.call(context, function(err) {
            if (err) {
              migrationDone({
                status: 'error',
                error: err
              });
              return allDone(err);
            } else {
              migrationDone({
                status: 'ok'
              });
              return runOne();
            }
          });
        };
      })(this);
      return runOne();
    };

    Migrator.prototype.migrate = function(done, progress) {
      return this._runWhenReady('up', done, progress);
    };

    Migrator.prototype.rollback = function(done, progress) {
      if (this._lastDirection !== 'up') {
        return done(new Error('Rollback can only be ran after migrate'));
      }
      return this._runWhenReady('down', done, progress);
    };

    Migrator.prototype._loadMigrationFiles = function(dir, cb) {
      var fs, path;
      fs = require('fs');
      path = require('path');
      return fs.readdir(dir, function(err, files) {
        if (err) {
          return cb(err);
        }
        files = files.map(function(f) {
          var n, _ref;
          n = (_ref = f.match(/^(\d+)/)) != null ? _ref[1] : void 0;
          if (n) {
            n = parseInt(n, 10);
          } else {
            n = null;
          }
          return [n, f];
        }).filter(function(f) {
          return !!f[0];
        }).sort(function(f1, f2) {
          return f1[0] - f2[0];
        }).map(function(f) {
          return require(path.join(dir, f[1]));
        });
        return cb(null, files);
      });
    };

    Migrator.prototype.runFromDir = function(dir, done, progress) {
      return this._loadMigrationFiles(dir, (function(_this) {
        return function(err, files) {
          if (err) {
            return done(err);
          }
          _this.bulkAdd(files);
          return _this.migrate(done, progress);
        };
      })(this));
    };

    Migrator.prototype.create = function(id, cb) {};

    return Migrator;

  })();

  module.exports.Migrator = Migrator;

}).call(this);
