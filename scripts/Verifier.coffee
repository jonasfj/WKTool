
@Verifier ?= {}

_currentRow = null

statuses =
  unknown:      'icon-question-sign'
  satisfied:    'icon-ok'
  unsatisfied:  'icon-remove'
  working:      'icon-refresh'

Verifier.height = (h) ->
  $('#property-list').height  h
  $('#edit-property').height  h

_editor = null
_refreshParserTimeout = null
Init ->
  _editor = CodeMirror document.getElementById("edit-prop-formula"),
    mode:           "WCTL"
    lineNumbers:    false
    tabSize:        2
    lineWrapping:   true
  _editor.setValue("")
  $('#add-property').click -> addProp().click()
  $('#edit-prop-encoding > .btn').click ->
    setEncoding $(this).html()
    saveCurrentRow()
  $('#edit-prop-engine > .btn').click ->
    setEngine $(this).html()
    saveCurrentRow()
  _editor.on 'change', ->
    if _refreshParserTimeout?
      clearTimeout _refreshParserTimeout
    _refreshParserTimeout = setTimeout testParse, 500
  $('#property-error-close').click -> $('#property-error').fadeOut()

testParse = ->
  _refreshParserTimeout = null
  msgbox = $('#property-error')
  has_error = false
  try
    value = _editor.getValue()
    if value? and not /^[ \t\n\r]*$/.test value
      WCTLParser.parse value
  catch err
    has_error = true
    name = err.name || "Error"
    $('#property-error-name').html name + ": "
    $('#property-error-message').html err.message
  if has_error
    msgbox.fadeIn()
  else
    msgbox.fadeOut()

Verifier.populateStates = (states) ->
  cur_state = $("#edit-prop-init-state").val()
  if cur_state isnt '' and cur_state? and cur_state not in states
    states.push cur_state
  dropdown = $('#edit-prop-init-state')
  dropdown.empty()
  for state in states.sort()
    dropdown.append $('<option>').val(state).text(state)
  $("#edit-prop-init-state").val(cur_state)

# Default property
defaultProp = ->
  status:   'unknown'
  state:    ""
  formula:  ""
  engine:   "Local"
  encoding: "Symbolic"
  time:     "-"

addProp = (prop = defaultProp()) ->
  row = $('<tr>')
  row.append $('<td>').append $('<div>').addClass statuses[prop.status]
  row.append $('<td>').html(prop.state)
  p = $('<td>').addClass "formula"
  CodeMirror.runMode prop.formula, 'WCTL', p[0]
  row.append p
  row.append $('<td>').addClass("time").html prop.time
  row.append $('<td>').html $('<button title="Delete" class="close"> &times;</td>').click ->
    if _currentRow? and row.is _currentRow
      _currentRow = null
    row.tooltip('destroy')
    row.remove()
  $('#properties > tbody').append row
  row.data 'property', prop
  row.click ->
    updateEditor $(this)
  return row


Init ->
  _editor.on 'change', saveCurrentRow
  $('#edit-prop-init-state').change saveCurrentRow

_dontSaveAtTheMoment = false
saveCurrentRow = ->
  if _dontSaveAtTheMoment
    return
  if not _currentRow?
    _currentRow = addProp()
  prop = _currentRow.data('property')
  # Save data
  changeStatus = true
  if prop.state == $("#edit-prop-init-state").val()
    if prop.formula == _editor.getValue()
      if prop.encoding == getEncoding()
        if prop.engine == getEngine()
          changeStatus = false
  if changeStatus
    prop.status = 'unknown'
    if prop.worker?
      killRowProcess _currentRow
  prop.state = $("#edit-prop-init-state").val()
  prop.formula = _editor.getValue()
  prop.encoding = getEncoding()
  prop.engine = getEngine()
  # Update GUI
  cells = _currentRow.children("td")
  cells.eq(0).find("div").removeClass().addClass(statuses[prop.status])
  cells.eq(1).html(prop.state)
  cells.eq(2).empty()
  CodeMirror.runMode prop.formula, 'WCTL', cells.eq(2)[0]

updateEditor = (row) ->
  if _currentRow?
    saveCurrentRow()
  # Select the row
  $('#properties > tbody > tr').removeClass()
  _currentRow = row
  _currentRow.addClass 'well'
  prop = _currentRow.data('property')
  if prop.status is 'working'
    $("#edit-form").hide(0)
    $("#stop-process").show(0)
  else
    $("#edit-form").show(0)
    $("#stop-process").hide(0)
  _dontSaveAtTheMoment = true
  $("#edit-prop-init-state").val(prop.state)
  _editor.setValue prop.formula
  setEncoding prop.encoding
  setEngine prop.engine
  _dontSaveAtTheMoment = false

Verifier.load = (props = []) ->
  $('#properties > tbody').each ->
    $(this).tooltip('destroy')
  $('#properties > tbody').empty()
  _currentRow = null
  last = null
  defaults = defaultProp()
  for prop in props
    for k, v of defaults
      prop[k] ?= v
    last = addProp(prop)
  last?.click()

Verifier.save = ->
  saveCurrentRow()
  # Get keys that we need to store
  keys = (k for k,v of defaultProp() when k isnt 'status')
  props = []
  $('#properties > tbody tr').each ->
    prop = $(this).data 'property'
    p = {}
    for k in keys
      p[k] = prop[k]
    if prop.status is 'working'
      p.status = 'unknown'
    else
      p.status = prop.status
    props.push p
  return props

setEncoding = (encoding) ->
  $('#edit-prop-encoding > .btn').removeClass 'disabled'
  $('#edit-prop-encoding > .btn').each ->
    if $(this).html() is encoding
      $(this).addClass 'disabled'

getEncoding = -> $('#edit-prop-encoding > .btn.disabled').html()

setEngine = (engine) ->
  $('#edit-prop-engine > .btn').removeClass 'disabled'
  $('#edit-prop-engine > .btn').each ->
    if $(this).html() is engine
      $(this).addClass 'disabled'

getEngine = -> $('#edit-prop-engine > .btn.disabled').html()

Init ->
  $('#edit-prop-run').click startVerification
  $('#kill-process').click ->
    prop = _currentRow.data('property')
    prop.status = 'unknown'
    killRowProcess _currentRow
    updateEditor _currentRow

killRowProcess = (row) ->
  prop = row.data('property')
  if prop.update_interval?
    clearInterval(prop.update_interval)
    prop.update_interval = null
  if prop.worker?
    prop.worker.terminate()
    prop.worker = null
    ShowMessage "Verification of property \"#{prop.formula}\" terminated."

startVerification = ->
  saveCurrentRow()
  row = _currentRow
  prop = row.data('property')
  prop.status = 'working'
  prop.worker = new Worker('scripts/VerificationWorker.js');
  start = new Date().getTime()
  updateTime = ->
    elapsed = (new Date()).getTime() - start
    formatted = (Math.round(elapsed / 100) / 10) + "s"
    row.find('.time').html formatted
    return formatted
  prop.update_interval = setInterval updateTime, 150
  prop.worker.onmessage = (e) ->
    prop = row.data('property')
    clearInterval(prop.update_interval)
    prop.time = updateTime()
    prop.update_interval = null
    prop.worker.terminate()
    prop.worker = null
    if e.data is true
      prop.status = 'satisfied'
    else
      prop.status = 'unsatisfied'
    row.children("td").eq(0).find("div").removeClass().addClass(statuses[prop.status])
    if _currentRow? and row.is _currentRow
      updateEditor row
  prop.worker.onerror = (error) ->
    prop = row.data('property')
    clearInterval(prop.update_interval)
    prop.time = updateTime()
    prop.update_interval = null
    prop.status = 'unknown'
    prop.worker.terminate()
    prop.worker = null
    row.children("td").eq(0).find("div").removeClass().addClass(statuses[prop.status])
    if _currentRow? and row.is _currentRow
      updateEditor row
    ShowMessage "Error in verification of \"#{prop.formula}\""
    console.log error
  prop.worker.postMessage
    mode:       Editor.mode()
    model:      Editor.model()
    state:      prop.state
    property:   prop.formula
    engine:     prop.engine
    encoding:   prop.encoding
  updateEditor _currentRow
