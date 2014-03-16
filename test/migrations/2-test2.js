exports.id = 'test2';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.insert({ name: 'loki' }, done);
};