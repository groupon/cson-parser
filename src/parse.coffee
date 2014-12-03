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
