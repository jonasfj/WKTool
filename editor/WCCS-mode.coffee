syntax = [
  ['atom',       ["0"]]
  # Channels
  ['channel',    [
                    /\<[ \n\r\t]*[A-z][A-z0-9_-]*!?[ \n\r\t]*(,[ \n\r\t]*[0-9]+)?[ \n\r\t]*\>/,
                    /\{[ \n\r\t]*([A-z][A-z0-9_-]*[ \n\r\t]*,)*[ \n\r\t]*([A-z][A-z0-9_-]*)?[ \n\r\t]*\}/
                 ]]
  # Properties/labels
  ['property',   [/[A-z][A-z0-9_-]*:/]]
  ['number',     [/[0-9]+/]]
  ['comment',    [/#.*/]]
  ['def',        [/[A-z][A-z0-9_-]*/]]
  ['operator',   [":=", "|", "+", ":", "\\", ";", "!", ",", ".", "->"]]
  ['bracket',    ["{", "}", "(", ")", "[", "]"]]
]

CodeMirror.defineMode "WCCS", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for rule in syntax
      for pattern in rule[1]
        if stream.match(pattern, true, false)
          return rule[0]
    stream.next() # Eat next character to avoid looping
    return "error"