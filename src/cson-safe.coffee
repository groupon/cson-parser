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

csr = require 'coffee-script-redux'
stringify = require './stringify'
CS = csr.Nodes

find = (arr, testFn) ->
  for element in arr
    return element if testFn element
  return null

nodeTypeString = (csNode) ->
  csNode.toBasicObject().type

syntaxErrorMessage = (csNode, msg) ->
  "Syntax error on line #{csNode.line}, column #{csNode.column}: #{msg}"

nodeTransforms = [
  [ CS.Program, (node) ->
    {body} = node
    if !body || !body.statements || body.statements.length != 1
      throw new SyntaxError syntaxErrorMessage(node, 'One top level value expected')

    transformNode body.statements[0]
  ]
  [ CS.ObjectInitialiser, (node) ->
    node.members.reduce(
      (outObject, {key, expression}) ->
        keyName = transformKey key
        value = transformNode expression
        outObject[keyName] = value; outObject
      {}
    )
  ]
  [ CS.ArrayInitialiser, (node) ->
    node.members.map transformNode
  ]
  [ CS.Null, -> null ]
  [ CS.UnaryNegateOp, (node) ->
    -(transformNode node.expression)
  ]
  [ CS.MultiplyOp, (node) ->
    transformNode(node.left) * transformNode(node.right)
  ]
  [ CS.PlusOp, (node) ->
    transformNode(node.left) + transformNode(node.right)
  ]
  [ CS.DivideOp, (node) ->
    transformNode(node.left) / transformNode(node.right)
  ]
  [ CS.SubtractOp, (node) ->
    transformNode(node.left) - transformNode(node.right)
  ]
  [ CS.RemOp, (node) ->
    transformNode(node.left) % transformNode(node.right)
  ]
  [ CS.BitAndOp, (node) ->
    transformNode(node.left) & transformNode(node.right)
  ]
  [ CS.BitOrOp, (node) ->
    transformNode(node.left) | transformNode(node.right)
  ]
  [ CS.BitXorOp, (node) ->
    transformNode(node.left) ^ transformNode(node.right)
  ]
  [ CS.BitNotOp, (node) ->
    ~(transformNode node.expression)
  ]
  [ CS.LeftShiftOp, (node) ->
    transformNode(node.left) << transformNode(node.right)
  ]
  [ CS.SignedRightShiftOp, (node) ->
    transformNode(node.left) >> transformNode(node.right)
  ]
  [ CS.UnsignedRightShiftOp, (node) ->
    transformNode(node.left) >>> transformNode(node.right)
  ]
]

LiteralTypes = [ CS.Bool, CS.Float, CS.Int, CS.String ]

LiteralTypes.forEach (LiteralType) ->
  nodeTransforms.unshift [ LiteralType, ({data}) -> data ]

isLiteral = (csNode) ->
  LiteralTypes.some (LiteralType) -> csNode instanceof LiteralType

transformKey = (csNode) ->
  unless csNode instanceof CS.Identifier || isLiteral csNode
    throw new SyntaxError syntaxErrorMessage(csNode, "#{nodeTypeString csNode} used as key")
  csNode.data

transformNode = (csNode) ->
  transform = find nodeTransforms, ([NodeType]) ->
    csNode instanceof NodeType

  unless transform
    throw new SyntaxError syntaxErrorMessage(csNode, "Unexpected #{nodeTypeString csNode}")

  transform[1] csNode

parse = (source, reviver) ->
  if reviver
    throw new Error "The reviver parameter is not implemented yet"

  coffeeAst = csr.parse source.toString(), bare: true, raw: true
  transformNode coffeeAst

module.exports = CSON = { stringify, parse }
