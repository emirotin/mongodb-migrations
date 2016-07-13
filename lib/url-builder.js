(function() {
  var _, buildHost;

  _ = require('lodash');

  buildHost = function(opts) {
    var host;
    host = opts.host;
    if (opts.port) {
      host += ':' + opts.port;
    }
    return host;
  };

  module.exports = {
    buildMongoConnString: function(config) {
      var hasUser, params, replicaset, s;
      if (config.url) {
        return config.url;
      }
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
      if (replicaset = config.replicaset) {
        s += replicaset.members.map(buildHost).join(',');
      } else {
        s += buildHost(config);
      }
      s += '/';
      if (config.db) {
        s += config.db;
      }
      params = [];
      if (config.replicaset) {
        params.push('replicaSet=' + config.replicaset.name);
      }
      if (config.ssl) {
        params.push('ssl=true');
      }
      if (params.length > 0) {
        s += '?' + params.join('&');
      }
      return s;
    }
  };

}).call(this);
