module.exports = (id, coffeeScript) ->
  if coffeeScript
    return """
      module.exports.id = "#{id}"

      module.exports.up = (done) ->
        # use @db for MongoDB communication, and @log() for logging
        done()

      module.exports.down = (done) ->
        # use @db for MongoDB communication, and @log() for logging
        done()
    """
  else
    return """
      'use strict';

      module.exports.id = "#{id}";

      module.exports.up = function (done) {
        // use this.db for MongoDB communication, and this.log() for logging
        done();
      };

      module.exports.down = function (done) {
        // use this.db for MongoDB communication, and this.log() for logging
        done();
      };
    """
