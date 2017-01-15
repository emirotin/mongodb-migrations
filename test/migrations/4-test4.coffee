module.exports.id = "4-test4"

module.exports.up = (done) ->
  @db.collection('test').insert({ name: '123', ok: 1 }, done);
