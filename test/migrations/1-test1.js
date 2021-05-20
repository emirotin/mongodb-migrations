exports.id = 'test1';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.insertOne({ name: 'tobi' }, done);
};

exports.down = function (done) {
  var coll = this.db.collection('test');
  coll.deleteMany({}, done);
};
