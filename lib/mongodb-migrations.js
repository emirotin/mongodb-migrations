(function() {
  var Migrator, Q, _, fs, mkdirp, mongoConnect, path;

  fs = require('fs');

  path = require('path');

  Q = require('q');

  _ = require('lodash');

  mkdirp = require('mkdirp');

  mongoConnect = require('./utils').connect;

  Migrator = (function() {
    function Migrator(dbConfig, logFn) {
      var deferred;
      this._isDisposed = false;
      this._m = [];
      this._result = {};
      deferred = Q.defer();
      this._dbReady = deferred.promise;
      mongoConnect(dbConfig, (function(_this) {
        return function(err, db) {
          if (err) {
            return deferred.reject(err);
          } else {
            _this._db = db;
            return deferred.resolve();
          }
        };
      })(this));
      this._collName = dbConfig.collection;
      if (logFn || logFn === null) {
        this.log = logFn;
      } else {
        this.log = function(src, msg) {
          var pad;
          pad = Array(src === 'system' ? 6 : 4).join(' ');
          return console.log(pad + msg);
        };
      }
    }

    Migrator.prototype.add = function(m) {
      return this._m.push(m);
    };

    Migrator.prototype.bulkAdd = function(array) {
      return this._m = this._m.concat(array);
    };

    Migrator.prototype._coll = function() {
      return this._db.collection(this._collName);
    };

    Migrator.prototype._runWhenReady = function(direction, cb, progress) {
      var onError, onSuccess;
      if (this._isDisposed) {
        return cb(new Error('This migrator is disposed and cannot be used anymore'));
      }
      onSuccess = (function(_this) {
        return function() {
          _this._ranMigrations = {};
          return _this._coll().find().toArray(function(err, docs) {
            var doc, j, len;
            if (err) {
              return cb(err);
            }
            for (j = 0, len = docs.length; j < len; j++) {
              doc = docs[j];
              _this._ranMigrations[doc.id] = true;
            }
            return _this._run(direction, cb, progress);
          });
        };
      })(this);
      onError = function(err) {
        return cb(err);
      };
      return this._dbReady.then(onSuccess, onError);
    };

    Migrator.prototype._run = function(direction, done, progress) {
      var allDone, i, insertPromises, l, log, logFn, m, migrationsCollection, runOne, systemLog, userLog;
      if (direction === 'down') {
        m = _(this._m).reverse().filter((function(_this) {
          return function(m) {
            var _r, ref;
            return (_r = (ref = _this._result[m.id]) != null ? ref.status : void 0) && _r !== 'skip';
          };
        })(this)).value();
      } else {
        direction = 'up';
        this._result = {};
        m = this._m;
      }
      this._lastDirection = direction;
      logFn = this.log;
      log = function(src) {
        return function(msg) {
          return typeof logFn === "function" ? logFn(src, msg) : void 0;
        };
      };
      userLog = log('user');
      systemLog = log('system');
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
          var context, fn, id, migration, migrationDone, skipReason;
          if (i >= l) {
            return allDone();
          }
          migration = m[i];
          i += 1;
          migrationDone = function(res) {
            var deferred, msg;
            _this._result[migration.id] = res;
            _.defer(function() {
              return typeof progress === "function" ? progress(migration.id, res) : void 0;
            });
            msg = "Migration '" + migration.id + "': " + res.status;
            if (res.status === 'skip') {
              msg += " (" + res.reason + ")";
            }
            systemLog(msg);
            if (res.status === 'error') {
              systemLog('  ' + res.error);
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
          skipReason = null;
          if (!fn) {
            skipReason = "no migration function for direction " + direction;
          }
          if (direction === 'up' && id in _this._ranMigrations) {
            skipReason = "migration already ran";
          }
          if (direction === 'down' && !(id in _this._result)) {
            skipReason = "migration wasn't in the recent `migrate` run";
          }
          if (skipReason) {
            migrationDone({
              status: 'skip',
              reason: skipReason
            });
            return runOne();
          }
          context = {
            db: _this._db,
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
      return mkdirp(dir, 0x1fc, function(err) {
        if (err) {
          return cb(err);
        }
        return fs.readdir(dir, function(err, files) {
          if (err) {
            return cb(err);
          }
          files = files.map(function(f) {
            var n, ref;
            n = (ref = f.match(/^(\d+)/)) != null ? ref[1] : void 0;
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
            var fileName;
            fileName = path.join(dir, f[1]);
            if (fileName.match(/\.coffee$/)) {
              require('coffee-script/register');
            }
            return [f[0], require(fileName)];
          });
          return cb(null, files);
        });
      });
    };

    Migrator.prototype.runFromDir = function(dir, done, progress) {
      return this._loadMigrationFiles(dir, (function(_this) {
        return function(err, files) {
          if (err) {
            return done(err);
          }
          _this.bulkAdd(files.map(function(f) {
            return f[1];
          }));
          return _this.migrate(done, progress);
        };
      })(this));
    };

    Migrator.prototype.create = function(dir, id, done, coffeeScript) {
      if (coffeeScript == null) {
        coffeeScript = false;
      }
      return this._loadMigrationFiles(dir, function(err, files) {
        var body, ext, fileName, maxNum, nextNum, slug;
        if (err) {
          return done(err);
        }
        maxNum = _.max(files.map(function(f) {
          return f[0];
        }));
        nextNum = Math.max(maxNum, 0) + 1;
        slug = (id || '').toLowerCase().replace(/\s+/, '-');
        ext = coffeeScript ? 'coffee' : 'js';
        fileName = path.join(dir, nextNum + "-" + slug + "." + ext);
        if (coffeeScript) {
          body = "module.exports.id = \"" + id + "\"\n\nmodule.exports.up = (done) ->\n  # use @db for MongoDB communication, and @log() for logging\n  done()\n\nmodule.exports.down = (done) ->\n  # use @db for MongoDB communication, and @log() for logging\n  done()";
        } else {
          body = "module.exports.id = \"" + id + "\";\n\nmodule.exports.up = function (done) {\n  // use this.db for MongoDB communication, and this.log() for logging\n  done();\n};\n\nmodule.exports.down = function (done) {\n  // use this.db for MongoDB communication, and this.log() for logging\n  done();\n};";
        }
        return fs.writeFile(fileName, body, done);
      });
    };

    Migrator.prototype.dispose = function(cb) {
      var onSuccess;
      this._isDisposed = true;
      onSuccess = (function(_this) {
        return function() {
          var e;
          try {
            _this._db.close();
            return typeof cb === "function" ? cb(null) : void 0;
          } catch (_error) {
            e = _error;
            return typeof cb === "function" ? cb(e) : void 0;
          }
        };
      })(this);
      return this._dbReady.then(onSuccess, cb);
    };

    return Migrator;

  })();

  module.exports.Migrator = Migrator;

}).call(this);
