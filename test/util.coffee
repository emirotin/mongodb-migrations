{ _buildOptions } = require '../src/utils'

describe 'Utils', ->

    describe '_buildOptions', ->
        
        it 'should allow custom options and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    a: 1
            _buildOptions(config).should.be.deepEqual({
                a: 1
                server: poolSize: 5
            })
            done()

        it 'should allow deeply nested options and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    a: b: 'c'
            _buildOptions(config).should.be.deepEqual({
                a: b: 'c'
                server: poolSize: 5
            })
            done()

        it 'should normalize null options and set the default `poolSize` of 5', (done) ->
            config = { otherKey: 'x' }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 5 })
            done()

        it 'should properly merge the `server` key and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    server: x: 1
            _buildOptions(config).should.be.deepEqual({
                server:
                    poolSize: 5
                    x: 1
            })
            done()

        it 'should not override the `poolSize` if only set in `server`', (done) ->
            config =
                options:
                    server:
                        x: 1
                        poolSize: 4
            _buildOptions(config).should.be.deepEqual({
                server:
                    poolSize: 4
                    x: 1
            })
            done()

        it '[compat] should normalize null options and set the custom `poolSize`', (done) ->
            config = { otherKey: 'x', poolSize: 7 }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 7 })
            done()

        it '[compat] should support `poolSize` with null options', (done) ->
            config = { otherKey: 'x', poolSize: 2 }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 2 })
            done()

        it '[compat] should override the `poolSize` if provided as a separate option', (done) ->
            config = {
                options:
                    server:
                        x: 1
                        poolSize: 2
                poolSize: 4
            }
            _buildOptions(config).should.be.deepEqual({
                server:
                    x: 1
                    poolSize: 4
            })
            done()