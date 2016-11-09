(function() {
  var DEFAULT_POOL_SIZE, MongoClient, urlBuilder;

  MongoClient = require('mongodb').MongoClient;

  urlBuilder = require('./url-builder');

  DEFAULT_POOL_SIZE = 5;

  exports.connect = function(config, cb) {
    var poolSize, ref, socketTimeoutMS, url;
    poolSize = (ref = config.poolSize) != null ? ref : DEFAULT_POOL_SIZE;

    // Default to infinite read timeout for mongo operations. (mongodb default
    // is 30 sec)
    socketTimeoutMS = (ref = config.socketTimeoutMS) != null ? ref : 0;

    url = urlBuilder.buildMongoConnString(config);
    return MongoClient.connect(url, {
      server: {
        poolSize: poolSize
      },
      socketTimeoutMS: 0
    }, cb);
  };

  exports.repeatString = function(str, n) {
    return Array(n + 1).join(str);
  };

}).call(this);
