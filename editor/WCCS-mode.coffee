syntax =
  number:     [/[0-9]+/]
  atom:       ["True", "False"]
  def:        [":="]
  operator:   ["|", "+", ":", "\\", ";", "!"]
  qualifier:  ["U", "X"]
  property:   ["<", ",", ">"]
  bracket:    ["{", "}"]

CodeMirror.defineMode "WCCS", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for key, patterns of syntax
      for pattern in patterns
        if stream.match(pattern, true, false)
          return key
    stream.next() # Eat next character to avoid looping
    return "error"