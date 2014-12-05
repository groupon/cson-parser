###
Copyright (c) 2014, Groupon, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

Neither the name of GROUPON nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

{nodes} = require 'coffee-script'

defaultReviver = (key, value) -> value

nodeTypeString = (csNode) ->
  csNode.constructor.name

syntaxErrorMessage = (csNode, msg) ->
  {
    first_line: lineIdx
    first_column: columnIdx
  } = csNode.locationData
  line = lineIdx + 1 if lineIdx?
  column = columnIdx + 1 if columnIdx?
  "Syntax error on line #{line}, column #{column}: #{msg}"

# See:
# http://www.ecma-international.org/ecma-262/5.1/#sec-15.12.2
parse = (source, reviver = defaultReviver) ->
  nodeTransforms =
    Block: (node) ->
      {expressions} = node
      if !expressions || expressions.length != 1
        throw new SyntaxError syntaxErrorMessage(node, 'One top level value expected')

      transformNode expressions[0]

    Value: (node) ->
      transformNode node.base

    Bool: (node) ->
      node.val == 'true'

    Null: -> null

    Literal: (node) ->
      {value} = node
      try
        if value[0] == "'"
          eval value # we trust the lexer here
        else
          JSON.parse value
      catch err
        throw new SyntaxError syntaxErrorMessage(node, err.message)

    Arr: (node) ->
      node.objects.map transformNode

    Obj: (node) ->
      node.properties.reduce(
        (outObject, property) ->
          {variable, value} = property
          return outObject unless variable
          keyName = transformKey variable
          value = transformNode value
          outObject[keyName] =
            reviver.call outObject, keyName, value
          outObject
        {}
      )

    Op: (node) ->
      if node.second?
        left = transformNode node.first
        right = transformNode node.second
        switch node.operator
          when '-' then left - right
          when '+' then left + right
          when '*' then left * right
          when '/' then left / right
          when '%' then left % right
          when '&' then left & right
          when '|' then left | right
          when '^' then left ^ right
          when '<<' then left << right
          when '>>>' then left >>> right
          when '>>' then left >> right
          else
            throw new SyntaxError syntaxErrorMessage(
              node, "Unknown binary operator #{node.operator}"
            )
      else
        switch node.operator
          when '-' then -transformNode(node.first)
          when '~' then ~transformNode(node.first)
          else
            throw new SyntaxError syntaxErrorMessage(
              node, "Unknown unary operator #{node.operator}"
            )

    Parens: (node) ->
      {expressions} = node.body
      if !expressions || expressions.length != 1
        throw new SyntaxError syntaxErrorMessage(
          node, 'Parenthesis may only contain one expression'
        )

      transformNode expressions[0]

  isLiteral = (csNode) ->
    LiteralTypes.some (LiteralType) -> csNode instanceof LiteralType

  transformKey = (csNode) ->
    type = nodeTypeString csNode
    switch type
      when 'Value'
        {value} = csNode.base
        switch value[0]
          when '\'' then eval value # we trust the lexer here
          when '"' then JSON.parse value
          else value

      else
        throw new SyntaxError syntaxErrorMessage(csNode, "#{type} used as key")

  transformNode = (csNode) ->
    type = nodeTypeString csNode
    transform = nodeTransforms[type]

    unless transform
      throw new SyntaxError syntaxErrorMessage(csNode, "Unexpected #{type}")

    transform csNode

  if typeof reviver != 'function'
    throw new TypeError "reviver has to be a function"

  coffeeAst = nodes source.toString 'utf8'
  parsed = transformNode(coffeeAst)
  return parsed if reviver == defaultReviver
  contextObj = {}
  contextObj[''] = parsed
  reviver.call contextObj, '', parsed

module.exports = parse
