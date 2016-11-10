(function() {
  var DEFAULT_POOL_SIZE, MongoClient, urlBuilder;

  MongoClient = require('mongodb').MongoClient;

  urlBuilder = require('./url-builder');

  DEFAULT_POOL_SIZE = 5;

  exports.connect = function(config, cb) {
    var poolSize, ref, ref1, socketTimeoutMS, url;
    poolSize = (ref = config.poolSize) != null ? ref : DEFAULT_POOL_SIZE;
    socketTimeoutMS = (ref1 = config.socketTimeoutMS) != null ? ref1 : 0;
    url = urlBuilder.buildMongoConnString(config);
    return MongoClient.connect(url, {
      server: {
        poolSize: poolSize
      },
      socketTimeoutMS: socketTimeoutMS
    }, cb);
  };

  exports.repeatString = function(str, n) {
    return Array(n + 1).join(str);
  };

}).call(this);
