module.exports.id = "runFromDir-should-find-coffee"

module.exports.up = (done) ->
  @db.collection('test').insertOne({ name: '123', ok: 1 }, done);
