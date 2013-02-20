
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
  _editor.on 'change', ->
    _expliciteStateNames = null

setMode = (mode) ->
  _editor.setOption 'mode', mode
  $('#model-lang > .btn').removeClass 'disabled'
  $('#model-lang > .btn').each ->
    if $(this).html() is mode
      $(this).addClass 'disabled'

getMode = -> $('#model-lang > .btn.disabled').html()

Editor.height = (h) -> _editor?.setSize("auto", h)


Editor.load = (json = {definition: '', language: 'WCCS'}) ->
  _editor.setValue  json.definition
  setMode           json.language

Editor.save = ->
  definition:     _editor.getValue()
  language:       getMode()

Editor.model = (m) ->
  if m?
    _editor.setValue m
  return _editor.getValue()

# List states we know to exists explicitely
# For a WKS this is all states, but for a WCCS we have many implicite states
_expliciteStateNames = null
Editor.expliciteStateNames = ->
  if not _expliciteStateNames?
    wks = @["#{getMode()}Parser"].parse Editor.model()
    _expliciteStateNames = wks.getExpliciteStateNames()
  return _expliciteStateNames


