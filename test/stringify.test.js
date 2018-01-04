'use strict';

const equal = require('assertive').equal;

const CSON = require('../');

function cson(obj, visitor, space) {
  if (space == null) {
    space = 2;
  }

  return CSON.stringify(obj, visitor, space);
}

describe('CSON.stringify', function() {
  it('handles null', () => equal('null', cson(null)));

  it('handles boolean values', function() {
    equal('true', cson(true));
    return equal('false', cson(false));
  });

  it('handles the empty object', () => equal('{}', cson({})));

  it('handles the empty array', () => equal('[]', cson([])));

  it('handles numbers', function() {
    equal('0.42', cson(0.42));
    equal('42', cson(42));
    return equal('1.2e+90', cson(1.2e90));
  });

  it('handles single-line strings', () => equal("'hello!'", cson('hello!')));

  it('handles multi-line strings', () =>
    equal(
      `\
'''
  I am your average multi-line string,
  and I have a sneaky \\''' in here, too
'''\
`,
      cson(`\
I am your average multi-line string,
and I have a sneaky ''' in here, too\
`)
    ));

  it('handles multi-line strings (with 0 indentation)', () =>
    equal(
      `\
"I am your average multi-line string,\\nand I have a sneaky ''' in here, too"\
`,
      cson(
        `\
I am your average multi-line string,
and I have a sneaky ''' in here, too\
`,
        null,
        0
      )
    ));

  it('handles multi-line strings w/ backslash', function() {
    const test = '\\\n\\';
    const expected = "'''\n  \\\\\n  \\\\\n'''";
    equal(test, CSON.parse(cson(test)));
    return equal(expected, cson(test));
  });

  it('handles arrays', () =>
    equal(
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
`,
      cson([[1], null, [], { a: 'str' }, {}])
    ));

  it('handles arrays (with 0 indentation)', () =>
    equal(
      `\
[[1],null,[],{a:'str'},{}]\
`,
      cson([[1], null, [], { a: 'str' }, {}], null, 0)
    ));

  it('handles objects', () =>
    equal(
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
`,
      cson({
        '': 'empty',
        'non\nidentifier': true,
        default: false,
        emptyObject: {},
        nested: {
          string: 'too',
        },
        array: [{}, []],
      })
    ));

  it('handles objects (with 0 indentation)', () =>
    equal(
      `\
'':'empty','non\\nidentifier':true,default:false,nested:{string:'too'},array:[{},[]]\
`,
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
      )
    ));

  it('handles NaN and +/-Infinity like JSON.stringify does', function() {
    equal('null', cson(NaN));
    equal('null', cson(+Infinity));
    return equal('null', cson(-Infinity));
  });

  it('handles undefined like JSON.stringify does', () =>
    equal(undefined, cson(undefined)));

  it('handles functions like JSON.stringify does', () =>
    equal(undefined, cson(function() {})));

  it('accepts no more than ten indentation steps, just like JSON.stringify', () =>
    equal(
      `\
x:
          "don't": "be silly, will'ya?"\
`,
      cson({ x: { "don't": "be silly, will'ya?" } }, null, Infinity)
    ));

  it('lets people that really want to indent with tabs', () =>
    equal(
      `\
x:
\t\t'super-tabby': true\
`,
      cson({ x: { 'super-tabby': true } }, null, '\t\t')
    ));

  it('handles indentation by NaN', () => equal('[1]', cson([1], null, NaN)));

  it('handles indentation by floating point numbers', () =>
    equal('[\n   1\n]', cson([1], null, 3.9)));

  it('is bug compatible with JSON.stringify for non-whitespace indention', () =>
    equal(
      `\
x:
ecma-262strange: true\
`,
      cson({ x: { strange: true } }, null, 'ecma-262')
    ));

  it('handles visitor functions', () =>
    equal(
      `\
keep: 1\
`,
      cson({ filter: 'me', keep: 1 }, function(k, v) {
        if (typeof v !== 'string') {
          return v;
        }
      })
    ));
});
