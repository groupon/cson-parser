# There are multiple ways to express the same thing in CSON, so trying to
# make `CSON.stringify(CSON.parse(str)) == str` work is doomed to fail
# but we can at least make output look a lot nicer than JSON.stringify's.
module.exports = (obj, visitor, indent) ->
  return undefined if typeof obj in ['undefined', 'function']
  return JSON.stringify obj, visitor, indent if indent in [0, '']

  # pick an indent style much as JSON.stringify does, but limited to cson legals
  indent = switch typeof indent
    when 'string' then indent.slice 0, 10

    when 'number'
      n = Math.min indent, 10
      n = 1 unless n in [1..10] # do not bail on NaN and similar
      Array(n + 1).join ' '

    else '  '

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
