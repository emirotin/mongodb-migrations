(function() {
  var DEFAULT_POOL_SIZE, MongoClient, _, urlBuilder;

  MongoClient = require('mongodb').MongoClient;

  urlBuilder = require('./url-builder');

  _ = require('lodash');

  DEFAULT_POOL_SIZE = 5;

  exports.connect = function(config, cb) {
    var options, poolSize, ref, url;
    poolSize = (ref = config.poolSize) != null ? ref : DEFAULT_POOL_SIZE;
    url = urlBuilder.buildMongoConnString(config);
    options = config.options || {};
    _.set(options, 'server.poolSize', poolSize);
    return MongoClient.connect(url, options, cb);
  };

  exports.repeatString = function(str, n) {
    return Array(n + 1).join(str);
  };

}).call(this);
