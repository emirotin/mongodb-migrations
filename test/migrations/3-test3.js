exports.id = 'test3';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.update({ name: { $in: ['loki', 'tobi'] } }, { $set: { ok: 1 } }, { multi: true }, done);
};

exports.down = function (done) {
  var coll = this.db.collection('test');
  coll.update({ name: { $in: ['loki', 'tobi'] } }, { $set: { ok: 3 } }, { multi: true }, done);
};
