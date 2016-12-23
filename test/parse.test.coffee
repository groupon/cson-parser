
CSON = require '../'
assert = require 'assertive'
os = require 'os'

compilesTo = (source, expected) ->
  assert.deepEqual expected, CSON.parse(source)

describe 'CSON.parse', ->
  it 'parses an empty object', ->
    compilesTo '{}', {}

  it 'parses boolean values', ->
    compilesTo 'true', true
    compilesTo 'yes', true
    compilesTo 'on', true
    compilesTo 'false', false
    compilesTo 'no', false
    compilesTo 'off', false

  it 'parses numbers', ->
    compilesTo '0.42', 0.42
    compilesTo '42', 42
    compilesTo '1.2e+4', 1.2e+4

  it 'parses arrays', ->
    compilesTo '[ 1, 2, a: "str" ]', [ 1, 2, a: 'str' ]
    compilesTo(
      """
      [
        1
        2
        a: 'str'
      ]
      """
      [ 1, 2, a: 'str' ]
    )

  it 'parses null', ->
    compilesTo 'null', null

  it 'does not allow undefined', ->
    assert.throws -> CSON.parse 'undefined'

  it 'allows line comments', ->
    compilesTo 'true # line comment', true

  it 'allows multi-line comments', ->
    compilesTo(
      """
      a:
        ###
        This is a comment
        spanning multiple lines
        ###
        c: 3
      """
      { a: { c: 3 } }
    )

  it 'allows multi-line strings', ->
    compilesTo(
      """
      \"""Some long
      string
      \"""
      """
      "Some long#{os.EOL}string"
    )

  it 'does not allow using assignments', ->
    assert.throws -> CSON.parse 'a = 3'
    assert.throws -> CSON.parse 'a ?= 3'

  it 'does not allow referencing variables', ->
    assert.throws -> CSON.parse 'a: foo'
    assert.throws -> CSON.parse 'a: process.env.NODE_ENV'

  it 'does not allow Infinity or -Infinity', ->
    assert.throws -> CSON.parse 'a: Infinity'
    assert.throws -> CSON.parse 'a: -Infinity'

  it 'does allow simple mathematical operations', ->
    compilesTo '(2 + 3) * 4', ((2 + 3) * 4)
    compilesTo '2 + 3 * 4', (2 + 3 * 4)
    compilesTo 'fetchIntervalMs: 1000 * 60 * 5', fetchIntervalMs: (1000 * 60 * 5)
    compilesTo '2 / 4', (2 / 4)
    compilesTo '5 - 1', (5 - 1)

  it 'allows hard tabs in strings', ->
    compilesTo 'a: "x\ty"', a: 'x\ty'

  it 'parses nested objects', ->
    compilesTo(
      """
      a:
        b: c: false
        "d": 44
        3: "t"
      e: 'str'
      """
      { a: { b: { c: false }, d: 44, 3: 't' }, e: 'str' }
    )

  it 'parses nested objects in arrays', ->
    compilesTo(
      """
      o:
        [
                  a: 'x'
                  b: 'y'
                  c:
                      d: 'z'
            ,
                  a: 'x'
                  b: 'y'
        ]
      """
      o: [
        { a: 'x', b: 'y', c: { d: 'z' } }
        { a: 'x', b: 'y' }
      ]
    )

  describe 'reviver functions', ->
    calls = expected = source = reviver = null
    beforeEach ->
      calls = []
      reviver = (key, value) ->
        # Test: called on parent object
        @x = 'magic' if key == '4'

        calls.push key
        if typeof value == 'number' then value * 2
        else value

      source = JSON.stringify {
        "1": 1, "2": 2,"3": {"4": 4, "5": {"6": 6}}
      }
      expected =
        1: 2
        2: 4
        3: { x: 'magic', 4: 8, 5: { 6: 12 } }

    it 'supports them', ->
      assert.deepEqual(
        expected, CSON.parse(source, reviver)
      )
      # See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
      assert.deepEqual calls, [ '1', '2', '4', '6', '5', '3', '' ]

    it 'works just like JSON.parse', ->
      assert.deepEqual(
        expected, JSON.parse(source, reviver)
      )
      # See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
      assert.deepEqual calls, [ '1', '2', '4', '6', '5', '3', '' ]
