module.exports.id = "runFromDir-should-find-coffee"

module.exports.up = (done) ->
  @db.collection('test').insert({ name: '123', ok: 1 }, done);
