(function() {
  var DEFAULT_POOL_SIZE, MongoClient, urlBuilder;

  MongoClient = require('mongodb').MongoClient;

  urlBuilder = require('./url-builder');

  DEFAULT_POOL_SIZE = 5;

  exports.connect = function(config, cb) {
    var poolSize, ref, url;
    poolSize = (ref = config.poolSize) != null ? ref : DEFAULT_POOL_SIZE;
    url = urlBuilder.buildMongoConnString(config);
    return MongoClient.connect(url, {
      server: {
        poolSize: poolSize
      }
    }, cb);
  };

}).call(this);
