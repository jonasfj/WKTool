
@Editor ?= {}

_editor = null
_refreshParserTimeout = null

Init ->
  _editor = CodeMirror document.getElementById("editor"),
    mode:           "WCCS"
    lineNumbers:    true
    tabSize:        2
    lineWrapping:   true
    matchBrackets:  true
  _editor.setValue("")
  # Mode buttons events
  $('#model-lang > .btn').click ->
    Editor.mode $(this).html()
  _editor.on 'change', ->
    if _refreshParserTimeout?
      clearTimeout _refreshParserTimeout
    _refreshParserTimeout = setTimeout updateModel, 500
  
_errWidget = null
_lastLine = null
_lastMessage = null
_lastColumn = null
_lastName = null
updateModel = ->
  _refreshParserTimeout = null
  msgbox = $("#editor-message")
  has_parse_error = false
  has_nonparse_error = false
  try
    wks = window["#{Editor.mode()}Parser"].parse Editor.model()
    # Empty strings returns arrays
    if not (wks instanceof Array)
      Verifier.populateStates wks.getExplicitStateNames()
      wks.resolve()
  catch err
    if 'line' of err and 'name' of err and 'message' of err and 'column' of err
      has_parse_error = true
      if (not _errWidget?) or _lastLine != err.line or _lastMessage != err.message or _lastColumn != err.column or _lastName != err.name
        _errWidget?.clear()
        _lastLine = err.message
        _lastMessage = err.message
        _lastColumn = err.column
        _lastName = err.name
        widget = $('<div>').addClass 'error-widget alert'
        widget.append $("<button class='close'>&times;</button>").click -> 
          _errWidget?.clear()
          _errWidget = null
        widget.append $('<strong>').html "#{err.name}, Line #{err.line}, Column #{err.column}: "
        widget.append $('<span>').html err.message
        _errWidget = _editor.addLineWidget err.line - 1, widget[0]
        Utils.track 'UI', 'editor-test-parse-failed', err.name + ":" + err.message
    else
      has_nonparse_error = true
      msgbox.find('.message').html(err.message)  
  if not has_parse_error
    _errWidget?.clear()
    _errWidget = null
    _errWidget = null
    _lastLine = null
    _lastMessage = null
    _lastColumn = null
    _lastName = null
  if has_nonparse_error
    msgbox.fadeIn()
  else
    msgbox.fadeOut()

Editor.height = (h) -> _editor?.setSize("auto", h)

Editor.mode = (mode) ->
  if mode?
    _editor.setOption 'mode', mode
    $('#model-lang > .btn').removeClass 'disabled'
    $('#model-lang > .btn').each ->
      if $(this).html() is mode
        $(this).addClass 'disabled'
    Utils.track 'UI', 'switch-editor-mode', mode
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

