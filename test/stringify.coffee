
assert = require 'assertive'

CSON = require '../'

describe 'CSON.stringify', ->
  it 'works just like JSON.stringify', ->
    assert.equal '{"a":"b"}', CSON.stringify(a: 'b')
