
CSON = require '../'
assert = require 'assertive'

compilesTo = (source, expected) ->
  assert.deepEqual expected, CSON.parse(source)

describe 'CSON.parse', ->
  it 'parses an empty object', ->
    compilesTo '{}', {}

  it 'parses boolean values', ->
    compilesTo 'true', true
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
    err = assert.throws ->
      CSON.parse 'undefined'

    assert.equal 'Syntax error on line 1, column 1: Unexpected Undefined', err.message

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
      'Some long\nstring'
    )

  it 'does not allow using assignments', ->
    err = assert.throws ->
      CSON.parse 'a = 3'
    assert.equal 'Syntax error on line 1, column 1: Unexpected AssignOp', err.message

    err = assert.throws ->
      CSON.parse 'a ?= 3'
    assert.equal 'Syntax error on line 1, column 1: Unexpected CompoundAssignOp', err.message

  it 'does not allow referencing variables', ->
    err = assert.throws ->
      CSON.parse 'a: foo'
    assert.equal 'Syntax error on line 1, column 4: Unexpected Identifier', err.message

    err = assert.throws ->
      CSON.parse 'a: process.env.NODE_ENV'
    assert.equal 'Syntax error on line 1, column 4: Unexpected MemberAccessOp', err.message

  it 'does not allow Infinity or -Infinity', ->
    err = assert.throws ->
      CSON.parse 'a: Infinity'
    assert.equal 'Syntax error on line 1, column 4: Unexpected Identifier', err.message

    err = assert.throws ->
      CSON.parse 'a: -Infinity'
    assert.equal 'Syntax error on line 1, column 5: Unexpected Identifier', err.message

  it 'does allow simple mathematical operations', ->
    compilesTo '(2 + 3) * 4', ((2 + 3) * 4)
    compilesTo '2 + 3 * 4', (2 + 3 * 4)
    compilesTo 'fetchIntervalMs: 1000 * 60 * 5', fetchIntervalMs: (1000 * 60 * 5)
    compilesTo '2 / 4', (2 / 4)
    compilesTo '5 - 1', (5 - 1)
    compilesTo '3 % 2', (3 % 2)

  it 'allows bit operations', ->
    compilesTo '5 & 6', (5 & 6)
    compilesTo '1 | 2', (1 | 2)
    compilesTo '~0', (~0)
    compilesTo '3 ^ 5', (3 ^ 5)
    compilesTo '1 << 3', (1 << 3)
    compilesTo '8 >> 3', (8 >> 3)
    compilesTo '-9 >>> 2', (-9 >>> 2)

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
