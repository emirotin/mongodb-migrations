(function() {
  var DEFAULT_POOL_SIZE, MongoClient, _, buildMongoConnString;

  _ = require('lodash');

  MongoClient = require('mongodb').MongoClient;

  DEFAULT_POOL_SIZE = 5;

  buildMongoConnString = function(config) {
    var hasUser, s;
    s = "mongodb://";
    if (config.user) {
      hasUser = true;
      s += config.user;
    }
    if (config.password) {
      if (!hasUser) {
        throw new Error('Password provided but Username is not');
      }
      s += ':' + config.password;
    }
    if (hasUser) {
      s += '@';
    }
    s += config.host;
    if (config.port) {
      s += ':' + config.port;
    }
    s += '/';
    if (config.db) {
      s += config.db;
    }
    if (config.ssl) {
      s += '?ssl=true';
    }
    return s;
  };

  exports.connect = function(config, cb) {
    var poolSize, ref;
    poolSize = (ref = config.poolSize) != null ? ref : DEFAULT_POOL_SIZE;
    return MongoClient.connect(buildMongoConnString(config), {
      server: {
        poolSize: poolSize
      }
    }, cb);
  };

}).call(this);
