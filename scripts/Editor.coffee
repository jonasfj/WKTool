
@Editor ?= {}

_editor = null

Init ->
  _editor = CodeMirror document.getElementById("editor"),
    mode:           "WCCS"
    lineNumbers:    true
    tabSize:        2
    lineWrapping:   true
  _editor.setValue("")
  # Mode buttons events
  $('#model-lang > .btn').click ->
    setMode $(this).html()

setMode = (mode) ->
  _editor.setOption 'mode', mode
  $('#model-lang > .btn').removeClass 'disabled'
  $('#model-lang > .btn').each ->
    if $(this).html() is mode
      $(this).addClass 'disabled'

Editor.height = (h) -> _editor?.setSize("auto", h)


Editor.load = (json = {definition: '', language: 'WCCS'}) ->
  _editor.setValue  json.definition
  setMode           json.language

Editor.save = ->
  definition:     _editor.getValue()
  language:       $('#model-lang > .btn.disabled').html()