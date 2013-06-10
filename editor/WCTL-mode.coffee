syntax = [
  ['atom',       ["True","true","TRUE", "False", "false", "FALSE"]]
  ['weight',     [/\[[ \n\r\t]*(<=|<|>|>=)[ \n\r\t]*([0-9]*[ \n\r\t]*)\]/]]
  ['number',     [/[0-9]+/]]
  ['fat-comment',[/####.*/]]
  ['comment',    [/#.*/]]
  ['operator',   ["||", "&&", "EG", "EF", "E", "AG", "AF", "A", "U", "W", "X", ">=", ">", "<=", "<", "!=", "==", "!", "+", "*", "-", "/", "^"]]
  ['bracket',    ["(", ")"]]
  ['property',   [/[A-Za-z][A-Za-z0-9_]*/]]
]

CodeMirror.defineMode "WCTL", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for rule in syntax
      for pattern in rule[1]
        if stream.match(pattern, true, false)
          return rule[0]
    stream.next() # Eat next character to avoid looping
    return "error"