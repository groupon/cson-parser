'use strict';

const assert = require('assert');

const CSON = require('..');

function cson(obj, visitor, space) {
  if (space == null) {
    space = 2;
  }

  return CSON.stringify(obj, visitor, space);
}

describe('CSON.stringify', () => {
  it('handles null', () => assert.strictEqual(cson(null), 'null'));

  it('handles boolean values', () => {
    assert.strictEqual(cson(true), 'true');
    assert.strictEqual(cson(false), 'false');
  });

  it('handles the empty object', () => assert.strictEqual(cson({}), '{}'));

  it('handles the empty array', () => assert.strictEqual(cson([]), '[]'));

  it('handles numbers', () => {
    assert.strictEqual(cson(0.42), '0.42');
    assert.strictEqual(cson(42), '42');
    assert.strictEqual(cson(1.2e90), '1.2e+90');
  });

  it('handles single-line strings', () =>
    assert.strictEqual(cson('hello!'), "'hello!'"));

  it('handles multi-line strings', () =>
    assert.strictEqual(
      cson(`\
I am your average multi-line string,
and I have a sneaky ''' in here, too\
`),
      `\
'''
  I am your average multi-line string,
  and I have a sneaky \\''' in here, too
'''\
`
    ));

  it('handles multi-line strings with quad quotes', () =>
    assert.strictEqual(
      cson(`\
I am your average multi-line string,
and I have a sneaky '''' in here, too\
`),
      `\
'''
  I am your average multi-line string,
  and I have a sneaky \\''\\'' in here, too
'''\
`
    ));

  it('handles multi-line strings (with 0 indentation)', () =>
    assert.strictEqual(
      cson(
        `\
I am your average multi-line string,
and I have a sneaky ''' in here, too\
`,
        null,
        0
      ),
      `\
"I am your average multi-line string,\\nand I have a sneaky ''' in here, too"\
`
    ));

  it('handles multi-line strings w/ backslash', () => {
    const test = '\\\n\\';
    const expected = "'''\n  \\\\\n  \\\\\n'''";
    assert.strictEqual(CSON.parse(cson(test)), test);
    assert.strictEqual(cson(test), expected);
  });

  it('handles arrays', () =>
    assert.strictEqual(
      cson([[1], null, [], { a: 'str' }, {}]),
      `\
[
  [
    1
  ]
  null
  []
  {
    a: 'str'
  }
  {}
]\
`
    ));

  it('handles arrays (with 0 indentation)', () =>
    assert.strictEqual(
      cson([[1], null, [], { a: 'str' }, {}], null, 0),
      `\
[[1],null,[],{a:'str'},{}]\
`
    ));

  it('handles objects', () =>
    assert.strictEqual(
      cson({
        '': 'empty',
        'non\nidentifier': true,
        default: false,
        emptyObject: {},
        nested: {
          string: 'too',
        },
        array: [{}, []],
      }),
      `\
'': 'empty'
'non\\nidentifier': true
default: false
emptyObject: {}
nested:
  string: 'too'
array: [
  {}
  []
]\
`
    ));

  it('handles objects (with 0 indentation)', () =>
    assert.strictEqual(
      cson(
        {
          '': 'empty',
          'non\nidentifier': true,
          default: false,
          nested: {
            string: 'too',
          },
          array: [{}, []],
        },
        null,
        0
      ),
      `\
'':'empty','non\\nidentifier':true,default:false,nested:{string:'too'},array:[{},[]]\
`
    ));

  it('handles NaN and +/-Infinity like JSON.stringify does', () => {
    assert.strictEqual(cson(NaN), 'null');
    assert.strictEqual(cson(+Infinity), 'null');
    assert.strictEqual(cson(-Infinity), 'null');
  });

  it('handles undefined like JSON.stringify does', () =>
    assert.strictEqual(cson(undefined), undefined));

  it('handles functions like JSON.stringify does', () =>
    assert.strictEqual(
      cson(() => {}),
      undefined
    ));

  it('accepts no more than ten indentation steps, just like JSON.stringify', () =>
    assert.strictEqual(
      cson({ x: { "don't": "be silly, will'ya?" } }, null, Infinity),
      `\
x:
          "don't": "be silly, will'ya?"\
`
    ));

  it('lets people that really want to indent with tabs', () =>
    assert.strictEqual(
      cson({ x: { 'super-tabby': true } }, null, '\t\t'),
      `\
x:
\t\t'super-tabby': true\
`
    ));

  it('handles indentation by NaN', () =>
    assert.strictEqual(cson([1], null, NaN), '[1]'));

  it('handles indentation by floating point numbers', () =>
    assert.strictEqual(cson([1], null, 3.9), '[\n   1\n]'));

  it('is bug compatible with JSON.stringify for non-whitespace indention', () =>
    assert.strictEqual(
      cson({ x: { strange: true } }, null, 'ecma-262'),
      `\
x:
ecma-262strange: true\
`
    ));

  it('handles visitor functions', () =>
    assert.strictEqual(
      // eslint-disable-next-line consistent-return
      cson({ filter: 'me', keep: 1 }, (k, v) => {
        if (typeof v !== 'string') {
          return v;
        }
      }),
      `\
keep: 1\
`
    ));
});
