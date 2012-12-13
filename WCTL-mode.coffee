syntax =
  number:     [/[0-9]+/]
  atom:       ["True", "False"]
  def:        [/[a-z]+/]
  operator:   ["||", "&&", "E", "A", "!"]
  qualifier:  ["U", "X"]
  property:   ["[", "]"]
  bracket:    ["(", ")"]

CodeMirror.defineMode "WCTL", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for key, patterns of syntax
      for pattern in patterns
        if stream.match(pattern, true, false)
          return key
    stream.next() # Eat next character to avoid looping
    return "error"