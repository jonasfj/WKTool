syntax = [
  ['keywords',   ["digraph","label"]]
  ['property',   [/\{[ \n\r\t]*([A-Za-z][A-Za-z0-9_]*[ \n\r\t]*,)*[ \n\r\t]*([A-Za-z][A-Za-z0-9_]*)?[ \n\r\t]*\}/]]
  ['number',     [/[0-9]+/]]
  ['fat-comment',[/####.*/]]
  ['comment',    [/#.*/]]
  ['variable',   [/[A-Za-z][A-Za-z0-9_]*/]]
  ['operator',   ["=", ";", "\"", "A", "!","->",","]]
  ['bracket',    ["[", "]", "{", "}", "(", ")"]]
]

CodeMirror.defineMode "WKS", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for rule in syntax
      for pattern in rule[1]
        if stream.match(pattern, true, false)
          return rule[0]
    stream.next() # Eat next character to avoid looping
    return "error"