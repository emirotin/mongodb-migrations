(function() {
  module.exports = {
    buildMongoConnString: function(config) {
      var hasUser, host, i, len, member, params, ref, replicas, s;
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
      if (config.replicaset) {
        replicas = [];
        ref = config.replicaset.members;
        for (i = 0, len = ref.length; i < len; i++) {
          member = ref[i];
          host = member.host;
          if (member.port) {
            host += ':' + member.port;
          }
          replicas.push(host);
        }
        s += replicas.join(',');
      } else {
        s += config.host;
        if (config.port) {
          s += ':' + config.port;
        }
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
