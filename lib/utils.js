(function() {
  var DEFAULT_POOL_SIZE, MongoClient, _, _buildOptions, urlBuilder;

  MongoClient = require('mongodb').MongoClient;

  urlBuilder = require('./url-builder');

  _ = require('lodash');

  DEFAULT_POOL_SIZE = 5;

  exports._buildOptions = _buildOptions = function(config) {
    var options, poolSize;
    options = config.options || {};
    poolSize = config.poolSize;
    if (poolSize != null) {
      console.warn('The `poolSize` config param is deprecated.\nUse `options: { server: { poolSize: poolSize} }` instead.');
      if (_.get(options, 'server.poolSize')) {
        console.warn('The `poolSize` is overriding the `options: { server: { poolSize: poolSize} }` value.');
      }
      _.set(options, 'server.poolSize', poolSize);
    }
    if (!_.get(options, 'server.poolSize')) {
      _.set(options, 'server.poolSize', DEFAULT_POOL_SIZE);
    }
    return options;
  };

  exports.connect = function(config, cb) {
    var options, url;
    options = _buildOptions(config);
    url = urlBuilder.buildMongoConnString(config);
    return MongoClient.connect(url, options, cb);
  };

  exports.repeatString = function(str, n) {
    return Array(n + 1).join(str);
  };

}).call(this);
