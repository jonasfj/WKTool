
@Editor ?= {}

_editor = null
_refreshParserTimeout = null

Init ->
  _editor = CodeMirror document.getElementById("editor"),
    mode:           "WCCS"
    lineNumbers:    true
    tabSize:        2
    lineWrapping:   true
  _editor.setValue("")
  # Mode buttons events
  $('#model-lang > .btn').click ->
    Editor.mode $(this).html()
  _editor.on 'change', ->
    if _refreshParserTimeout?
      clearTimeout _refreshParserTimeout
    _refreshParserTimeout = setTimeout updateModel, 500

updateModel = ->
  _refreshParserTimeout = null
  msgbox = $("#editor-message")
  msgbox.hide()
  try
    wks = window["#{Editor.mode()}Parser"].parse Editor.model()
    # Empty strings returns arrays
    if not (wks instanceof Array)
      Verifier.populateStates wks.getExplicitStateNames()
  catch err
    msgbox.show().find('.message').html(err.message)  

Editor.height = (h) -> _editor?.setSize("auto", h)

Editor.mode = (mode) ->
  if mode?
    _editor.setOption 'mode', mode
    $('#model-lang > .btn').removeClass 'disabled'
    $('#model-lang > .btn').each ->
      if $(this).html() is mode
        $(this).addClass 'disabled'
  else
    return $('#model-lang > .btn.disabled').html()

Editor.load = (json = {definition: '', language: 'WCCS'}) ->
  _editor.setValue  json.definition
  Editor.mode       json.language
  updateModel()

Editor.save = ->
  definition:     _editor.getValue()
  language:       Editor.mode()

Editor.model = (m) ->
  if m?
    _editor.setValue m
  return _editor.getValue()

