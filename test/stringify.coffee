
{ equal } = require 'assertive'

CSON = require '../'
cson = (obj, visitor, space = 2) -> CSON.stringify obj, visitor, space

describe 'CSON.stringify', ->
  it 'handles null', ->
    equal 'null', cson null

  it 'handles boolean values', ->
    equal 'true',  cson true
    equal 'false', cson false

  it 'handles the empty object', ->
    equal '{}', cson {}

  it 'handles the empty array', ->
    equal '[]', cson []

  it 'handles numbers', ->
    equal '0.42',    cson 0.42
    equal '42',      cson 42
    equal '1.2e+90', cson 1.2e+90

  it 'handles single-line strings', ->
    equal '"hello!"', cson 'hello!'

  it 'handles multi-line strings', ->
    equal """
      '''
        I am your average multi-line string,
        and I have a sneaky \\''' in here, too
      '''
    """, cson """
      I am your average multi-line string,
      and I have a sneaky ''' in here, too
    """

  it 'handles arrays', ->
    equal '''
      [
        [
          1
        ]
        null
        []
        {
          a: "str"
        }
        {}
      ]
    ''', cson [ [1], null, [], a: 'str', {} ]

  it 'handles objects', ->
    equal '''
      "": "empty"
      "non\\nidentifier": true
      default: false
      nested:
        string: "too"
      array: [
        {}
        []
      ]
    ''', cson {
      '': 'empty'
      "non\nidentifier": true
      default: false
      nested: {
        string: 'too'
      }
      array: [
        {}
        []
      ]
    }

  it 'handles NaN and +/-Infinity like JSON.stringify does', ->
    equal 'null', cson NaN
    equal 'null', cson +Infinity
    equal 'null', cson -Infinity

  it 'handles undefined like JSON.stringify does', ->
    equal undefined, cson undefined

  it 'handles functions like JSON.stringify does', ->
    equal undefined, cson ->

  it 'works just like JSON.stringify when asking for no indentation', ->
    equal '{"zeroed":0}', cson zeroed: 0, null, 0
    equal '{"empty":""}', cson empty: '', null, ''

  it 'accepts no more than ten indentation steps, just like JSON.stringify', ->
    equal '''
      x:
                "don't": "be silly, will'ya?"
    ''', cson { x: { "don't": "be silly, will'ya?" } }, null, Infinity

  it 'lets people that really want to indent with tabs', ->
    equal '''
      x:
      \t\t"super-tabby": true
    ''', cson { x: { 'super-tabby': yes } }, null, '\t\t'

  it 'handles indentation by NaN', ->
    equal '[1]', cson([ 1 ], null, NaN)

  it 'handles indentation by floating point numbers', ->
    equal '[\n   1\n]', cson([ 1 ], null, 3.9)

  it 'is bug compatible with JSON.stringify for non-whitespace indention', ->
    equal '''
      x:
      ecma-262strange: true
    ''', cson { x: { strange: yes } }, null, 'ecma-262'

  it 'handles visitor functions', ->
    equal '''
      keep: 1
    ''', cson {filter: 'me', keep: 1}, (k, v) -> v unless typeof v is 'string'
