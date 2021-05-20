exports.id = 'test3';

exports.up = function (done) {
  var coll = this.db.collection('test');
  coll.updateMany({ name: { $in: ['loki', 'tobi'] } }, { $set: { ok: 1 } }, done);
};
