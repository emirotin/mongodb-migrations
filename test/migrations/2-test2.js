exports.id = 'test2';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.insert({ name: 'loki' }, done);
};

exports.down = function (done) {
  var coll = this.db.collection('test');
  coll.update({ name: { $in: ['loki', 'tobi'] } }, { $set: { ok: 2 } }, { multi: true }, done);
};
