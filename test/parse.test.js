'use strict';

const os = require('os');

const assert = require('assertive');

const CSON = require('../');

function compilesTo(source, expected) {
  assert.deepEqual(expected, CSON.parse(source));
}

describe('CSON.parse', function() {
  it('parses an empty object', () => compilesTo('{}', {}));

  it('parses boolean values', function() {
    compilesTo('true', true);
    compilesTo('yes', true);
    compilesTo('on', true);
    compilesTo('false', false);
    compilesTo('no', false);
    return compilesTo('off', false);
  });

  it('parses numbers', function() {
    compilesTo('0.42', 0.42);
    compilesTo('42', 42);
    return compilesTo('1.2e+4', 1.2e4);
  });

  it('parses arrays', function() {
    compilesTo('[ 1, 2, a: "str" ]', [1, 2, { a: 'str' }]);
    return compilesTo(
      `\
[
  1
  2
  a: 'str'
]\
`,
      [1, 2, { a: 'str' }]
    );
  });

  it('parses null', () => compilesTo('null', null));

  it('does not allow undefined', function() {
    const err = assert.throws(() => CSON.parse('undefined'));

    assert.match(
      /^Syntax error on line 1, column 1: Unexpected Undefined/,
      err.message
    );
  });

  it('allows line comments', () => compilesTo('true # line comment', true));

  it('allows multi-line comments', () =>
    compilesTo(
      `\
a:
  ###
  This is a comment
  spanning multiple lines
  ###
  c: 3\
`,
      { a: { c: 3 } }
    ));

  it('allows multi-line strings', () =>
    compilesTo(
      `\
\"""Some long
string
\"""\
`,
      `Some long${os.EOL}string`
    ));

  it('does not allow using assignments', function() {
    let err = assert.throws(() => CSON.parse('a = 3'));
    assert.equal(
      'Syntax error on line 1, column 1: Unexpected Assign',
      err.message
    );

    err = assert.throws(() => CSON.parse('a ?= 3'));
    assert.equal(
      'Syntax error on line 1, column 1: Unexpected Assign',
      err.message
    );
  });

  it('does not allow referencing variables', function() {
    let err = assert.throws(() => CSON.parse('a: foo'));
    assert.match(
      /Syntax error on line 1, column 4: Unexpected (token o|IdentifierLiteral)/,
      err.message
    );

    err = assert.throws(() => CSON.parse('a: process.env.NODE_ENV'));
    assert.match(
      /Syntax error on line 1, column 4: Unexpected (token p|IdentifierLiteral)/,
      err.message
    );
  });

  it('does not allow Infinity or -Infinity', function() {
    let err = assert.throws(() => CSON.parse('a: Infinity'));
    assert.match(
      /^Syntax error on line 1, column 4: Unexpected (token I|InfinityLiteral)/,
      err.message
    );

    err = assert.throws(() => CSON.parse('a: -Infinity'));
    assert.match(
      /Syntax error on line 1, column 5: Unexpected (token I|InfinityLiteral)/,
      err.message
    );
  });

  it('does allow simple mathematical operations', function() {
    compilesTo('(2 + 3) * 4', (2 + 3) * 4);
    compilesTo('2 + 3 * 4', 2 + 3 * 4);
    compilesTo('fetchIntervalMs: 1000 * 60 * 5', {
      fetchIntervalMs: 1000 * 60 * 5,
    });
    compilesTo('2 / 4', 2 / 4);
    compilesTo('5 - 1', 5 - 1);
    return compilesTo('3 % 2', 3 % 2);
  });

  it('allows bit operations', function() {
    compilesTo('5 & 6', 5 & 6);
    compilesTo('1 | 2', 1 | 2);
    compilesTo('~0', ~0);
    compilesTo('3 ^ 5', 3 ^ 5);
    compilesTo('1 << 3', 1 << 3);
    compilesTo('8 >> 3', 8 >> 3);
    return compilesTo('-9 >>> 2', -9 >>> 2);
  });

  it('allows hard tabs in strings', () =>
    compilesTo('a: "x\ty"', { a: 'x\ty' }));

  it('parses simple regular expressions', () =>
    compilesTo('a: /^[a-d]*/g', { a: /^[a-d]*/g }));

  it('parses complex multi-line regular expressions', () =>
    compilesTo(
      `\
syntax:
  identifier: /\\b[a-z_][a-z_0-9]*\\b/i
  operator: /// ^ (
    ?: [-=]>             # function
     | [-+*/%<>&|^!?=]=  # compound assign / compare
     | >>>=?             # zero-fill right shift
     | ([-+:])           # doubles
     | ([&|<>])          # logic / shift
     | \\?\\.            # soak access
     | \\.{2,3}          # range or splat
  ) ///\
`,
      {
        syntax: {
          identifier: /\b[a-z_][a-z_0-9]*\b/i,
          operator: new RegExp(`^(\
?:[-=]>\
|[-+*/%<>&|^!?=]=\
|>>>=?\
|([-+:])\
|([&|<>])\
|\\?\\.\
|\\.{2,3}\
)`),
        },
      }
    ));

  it('parses nested objects', () =>
    compilesTo(
      `\
a:
  b: c: false
  "d": 44
  3: "t"
e: 'str'\
`,
      { a: { b: { c: false }, d: 44, 3: 't' }, e: 'str' }
    ));

  it('parses nested objects in arrays', () =>
    compilesTo(
      `\
o:
  [
            a: 'x'
            b: 'y'
            c:
                d: 'z'
      ,
            a: 'x'
            b: 'y'
  ]\
`,
      {
        o: [{ a: 'x', b: 'y', c: { d: 'z' } }, { a: 'x', b: 'y' }],
      }
    ));

  describe('reviver functions', function() {
    let expected;
    let source;
    let reviver;

    let calls = (expected = source = reviver = null);
    beforeEach(function() {
      calls = [];
      reviver = function(key, value) {
        // Test: called on parent object
        if (key === '4') {
          this.x = 'magic';
        }

        calls.push(key);
        if (typeof value === 'number') {
          return value * 2;
        } else {
          return value;
        }
      };

      source = JSON.stringify({
        '1': 1,
        '2': 2,
        '3': { '4': 4, '5': { '6': 6 } },
      });
      expected = {
        1: 2,
        2: 4,
        3: { x: 'magic', 4: 8, 5: { 6: 12 } },
      };
    });

    it('supports them', function() {
      assert.deepEqual(expected, CSON.parse(source, reviver));
      // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
      assert.deepEqual(calls, ['1', '2', '4', '6', '5', '3', '']);
    });

    it('works just like JSON.parse', function() {
      assert.deepEqual(expected, JSON.parse(source, reviver));
      // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse
      assert.deepEqual(calls, ['1', '2', '4', '6', '5', '3', '']);
    });
  });
});
