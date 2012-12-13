syntax =
  number:     [/[0-9]+/]
  comment:    [/\/\/.*/]
  atom:       ["True", "False"]
  def:        [/[a-zA-Z][a-zA-Z0-9]*/]
  operator:   ["=", ";", "\"", "A", "!","->",","]
  qualifier:  ["digraph", "label"]
  property:   ["[", "]"]
  bracket:    ["(", ")", "{", "}"]

CodeMirror.defineMode "WKS", ->
  token:      (stream, state) ->
    stream.eatSpace()
    for key, patterns of syntax
      for pattern in patterns
        if stream.match(pattern, true, false)
          return key
    stream.next() # Eat next character to avoid looping
    return "error"