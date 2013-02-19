
@Editor ?= {}

_editor = null
_system = null

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
    _explicitStateNames = null
  _editor.on 'blur', ->
    msgbox = $("#editor-message")
    msgbox.hide()
    try
      _system = @["#{getMode()}Parser"].parse Editor.model()
    catch err
      msgbox.show().find('.message').html(err.message)

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

# List states that we know to exist explicitly
# For a WKS this is every state, but for a WCCS there are many implicit states
_explicitStateNames = null
Editor.explicitStateNames = ->
  if not _explicitStateNames?
    wks = @["#{getMode()}Parser"].parse Editor.model()
    _explicitStateNames = wks.getExplicitStateNames()
  return _explicitStateNames


