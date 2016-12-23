'use strict';

var parser = require('./parser');
var fastParser = require('./parser_fast');

function parse(cson, reviver, fast) {
  var p = fast ? fastParser : parser;
  var obj = p.parse(cson);
  if (reviver) obj = JSON.parse(JSON.stringify(obj), reviver);
  return obj;
}

function parseFast(cson, reviver) {
  return parse(cson, reviver, true);
}

parse.fast = parseFast;

module.exports = parse;
