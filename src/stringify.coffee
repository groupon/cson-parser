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

# There are multiple ways to express the same thing in CSON, so trying to
# make `CSON.stringify(CSON.parse(str)) == str` work is doomed to fail
# but we can at least make output look a lot nicer than JSON.stringify's.
jsIdentifierRE = /^[a-z_$][a-z0-9_$]*$/i
tripleQuotesRE = new RegExp "'''", 'g' # some syntax hilighters hate on /'''/g

SPACES = '          ' # 10 spaces

newlineWrap = (str) ->
  str and "\n#{ str }\n"

isObject = (obj) ->
  typeof obj == 'object' && obj != null && !Array.isArray(obj)

# See:
# http://www.ecma-international.org/ecma-262/5.1/#sec-15.12.3
module.exports = (data, visitor, indent) ->
  return undefined if typeof data in ['undefined', 'function']

  # pick an indent style much as JSON.stringify does
  indent = switch typeof indent
    when 'string' then indent.slice 0, 10

    when 'number'
      n = Math.min 10, Math.floor indent
      n = 0 unless n in [1..10] # do not bail on NaN and similar
      SPACES.slice(0, n)

    else 0

  return JSON.stringify data, visitor, indent unless indent

  indentLine = (line) -> indent + line

  indentLines = (str) ->
    return str if str == ''
    str.split('\n').map(indentLine).join('\n')

  # have the native JSON serializer do visitor transforms & normalization for us
  normalized = JSON.parse JSON.stringify data, visitor

  visitString = (str) ->
    if str.indexOf('\n') == -1
      JSON.stringify str
    else
      string = str.replace tripleQuotesRE, "\\'''"
      "'''#{ newlineWrap indentLines string }'''"

  visitArray = (arr) ->
    items = arr.map (value) ->
      serializedValue = visitNode value
      if isObject value
        "{#{ newlineWrap indentLines serializedValue }}"
      else
        serializedValue

    array = items.join '\n'
    "[#{ newlineWrap indentLines array }]"

  visitObject = (obj) ->
    keypairs = for key, value of obj
      key = JSON.stringify key unless key.match jsIdentifierRE
      serializedValue = visitNode value
      if isObject value
        if serializedValue == ''
          "#{ key }: {}"
        else
          "#{ key }:\n#{ indentLines serializedValue }"
      else
        "#{ key }: #{ serializedValue }"

    keypairs.join '\n'

  visitNode = (node) ->
    switch typeof node
      when 'boolean' then "#{node}"

      when 'number'
        if isFinite node then "#{node}"
        else 'null' # NaN, Infinity and -Infinity

      when 'string' then visitString node

      when 'object'
        if node == null then 'null'
        else if Array.isArray(node) then visitArray(node)
        else visitObject(node)

  out = visitNode normalized
  if out == '' then '{}' # the only thing that serializes to '' is an empty object
  else out
