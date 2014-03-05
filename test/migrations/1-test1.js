exports.id = 'test1';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.insert({ name: 'tobi' }, done);
};

exports.down = function (done) {
  var coll = this.db.collection('test');
  coll.remove({}, done);
};