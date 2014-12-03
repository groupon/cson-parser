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
module.exports = (obj, visitor, indent) ->
  return undefined if typeof obj in ['undefined', 'function']

  # pick an indent style much as JSON.stringify does, but limited to cson legals
  indent = switch typeof indent
    when 'string' then indent.slice 0, 10

    when 'number'
      n = Math.min indent, 10
      n = 0 unless n in [1..10] # do not bail on NaN and similar
      Array(n + 1).join ' '

    else 0

  return JSON.stringify obj, visitor, indent unless indent

  indentLine = (line) -> indent + line

  indentLines = (str) ->
    str and str.split('\n').map(indentLine).join('\n')

  newlineWrap = (str) ->
    str and "\n#{ str }\n"

  jsIdentifierRE = /^[a-z_$][a-z0-9_$]*$/i
  tripleQuotesRE = new RegExp "'''", 'g' # some syntax hilighters hate on /'''/g

  # have the native JSON serializer do visitor transforms & normalization for us
  obj = JSON.parse JSON.stringify obj, visitor

  do serialize = (obj) ->
    switch typeof obj
      when 'boolean' then obj + ''

      when 'number'
        if isFinite obj
          obj + ''
        else # NaN, Infinity and -Infinity
          'null'

      when 'string'
        if obj.indexOf('\n') is -1
          JSON.stringify obj
        else
          string = obj.replace tripleQuotesRE, "\\'''"
          string = newlineWrap indentLines string
          "'''#{ string }'''"

      when 'object'
        if obj is null
          'null'

        else if Array.isArray obj
          array = obj.map(serialize).join '\n'
          array = newlineWrap indentLines array
          "[#{ array }]"

        else
          keypairs = for key, val of obj
            key = JSON.stringify key unless key.match jsIdentifierRE
            val = serialize val
            "#{ key }: #{ val }"

          object = keypairs.join '\n'
          object = newlineWrap indentLines object
          "{#{ object }}"
