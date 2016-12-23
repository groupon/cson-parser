{
  // ported from https://goo.gl/md9zUA
  var HEREDOC_INDENT = /\n+([^\n\S]*)(?=\S)/g;
  var LEADING_BLANK_LINE  = /^[^\n\S]*\n/;
  var TRAILING_BLANK_LINE = /\n[^\n\S]*$/;
  function processMultiLine(doc) {
    var attempt, indent = null, indentRegex, match;
    while (match = HEREDOC_INDENT.exec(doc)) {
      attempt = match[1];
      if (indent === null ||
          (attempt.length && attempt.length < indent.length))
        indent = attempt;
    }
    if (indent)
      indentRegex = new RegExp('\n' + indent, 'g');
    if (indentRegex) doc = doc.replace(indentRegex, '\n');
    return doc.replace(LEADING_BLANK_LINE, '')
              .replace(TRAILING_BLANK_LINE, '');
  }

  function SubObj(kvs) { this.kvs = kvs; }
  SubObj.prototype.toObject = function () {
    return this.kvs.reduce(function (obj, kv) {
      obj[kv.key] = (kv.value instanceof SubObj)
                  ? kv.value.toObject() : kv.value;
      return obj;
    }, {});
  };

  function fixObjNesting(tree, error, parents) {
    if (!parents) {
      parents = [{
        key: 'ROOT', value: tree, loc: { start: { column: 0 } }
      }];
    }
    var kv, col;
    var kvs = tree.kvs.slice(0);
    for (var i = 0; i < kvs.length; i++) {
      kv = kvs[i];
      col = kv.loc.start.column;
      if (col <= parents[0].loc.start.column) {
        for (var j = 0;
             parents[j] && col <= parents[j].loc.start.column;
             j++) { }
        if (j > parents.length) {
          return error(
            new Error('assertion failure: excessive exdent!?'),
            kv.loc
          );
        }
        var pkvs = parents[j].value.kvs;
        for (j = 0;
             j < pkvs.length
               && pkvs[j].loc.start.line < kv.loc.start.line;
             j++) { }
        pkvs.splice(j, 0, kv);
        tree.kvs =
          tree.kvs.filter(function (x) { return x !== kv; });
      }
      if (kv.value instanceof SubObj)
        fixObjNesting(kv.value, error, [kv].concat(parents));
    }
  }
}

Document
  = MultiLineComment? _ v:Value _ { return v }

Value
  = ( NonObjValue / Object )

NonObjValue
  = ( Array / Bool / Null / String / MathExpr )

Comment
  = '\n' MultiLineComment
  / SingleLineComment

MultiLineComment "multi-line comment"
  = [ \t\r]* '###'
    ( [^#] / '#' !'##' )*
    '###' [ \t\r]* ( !. / &'\n' )

SingleLineComment "line comment"
  = '#' !'##' [^\n]*

SubObj
  = ExplicitObj
  / SubImplicitObj

Object "object"
  = ExplicitObj
  / ImplicitObj

ExplicitObj "explicit object"
  = '{' _ o:ImplicitObj? _ '}' { return o || {} }

ImplicitObj "implicit object"
  = so:SubImplicitObj
    {
      fixObjNesting(so, error);
      return so.toObject();
    }

SubImplicitObj "nested implicit object"
  = first:KeyVal
    rest:(
      ( _ ',' _ / newLine [ \t]* )
      kv:KeyVal
      { return kv }
    )*
    { return new SubObj([first].concat(rest)) }

KeyVal
  = k:( String / Key )
    _ ':' _ v:( NonObjValue / SubObj )
    { return { key: k, value: v, loc: location() }; }

Key "key" = $ [a-zA-Z0-9_]+

Array "array"
  = '[' _ a:(
       first:Value
       rest:(( _ ',' / newLine ) _ v:Value { return v })*
       { return [first].concat(rest) }
     )? _ ']'
     { return a || [] }

Bool "bool"
  = ( 'true' / 'false' / 'yes' / 'no' / 'on' / 'off' )
    { var t = text(); return (t === 'true' || t === 'yes' || t === 'on') }

Number "number"
  = neg:( '-' _ )?
    int:( '0' / [1-9] [0-9]* )
    dec:( '.' [0-9]+ )?
    exp:( 'e'i [+-]? [0-9]+ )?
    { return Number(text()) }

Null "null"
  = 'null' { return null; }

String "string"
  = MultiLineString
  / ( '"' c:( [^"\\] / EscapedChar )* '"' { return c.join('') } )
  / ( "'" c:( [^'\\] / EscapedChar )* "'" { return c.join('') } )

MultiLineString
  = s:( "'''" ( [^'\\] / EscapedChar / $("'" !"''") )* "'''"
      / '"""' ( [^"\\] / EscapedChar / $('"' !'""') )* '"""'
      ) { return processMultiLine(s[1].join('')) }

EscapedChar
  = '\\' c:( 'u' HexDigit HexDigit HexDigit HexDigit / . )
    {
      if (typeof c === 'string') {
        return {
          b: '\b', f: '\f', r: '\r', t: '\t', n: '\n'
        }[c] || c;
      }
      return String.fromCharCode(
        parseInt(c.slice(1).join(''), 16)
      );
    }

_ "whitespace"
  = ( Comment / [ \t\n\r] )*

newLine "newline"
  = ( ( Comment / [ \t\r] )* '\n' )+

HexDigit = [0-9a-f]i

MathExpr
  = head:MathTerm tail:( _ [+-] _ MathTerm )*
    {
      return tail.reduce(function (res, n) {
        return n[1] === '+' ? res + n[3] : res - n[3]
      }, head)
    }

MathTerm
  = head:MathFactor tail:( _ [*/] _ MathFactor )*
    {
      return tail.reduce(function (res, n) {
        return n[1] === '*' ? res * n[3] : res / n[3]
      }, head)
    }

MathFactor
  = '(' _ x:MathExpr _ ')' { return x }
  / Number
