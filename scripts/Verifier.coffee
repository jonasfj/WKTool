
@Verifier ?= {}

_currentRow = null

statuses =
  unknown:      'icon-question-sign'
  satisfied:    'icon-ok'
  unsatisfied:  'icon-remove'
  working:      'icon-refresh'


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
    setEncoding $(this).data('encoding')
    saveCurrentRow()
  $('#edit-prop-engine > .btn').click ->
    setEngine $(this).data('engine')
    saveCurrentRow()
  _editor.on 'change', ->
    if _refreshParserTimeout?
      clearTimeout _refreshParserTimeout
    _refreshParserTimeout = setTimeout testParse, 500
  $('#property-error-close').click -> $('#property-error').fadeOut()
  ddl_strategies = $('#search-strategy')
  strats = (name for name, factory of Strategies).sort()
  for strat in strats
    ddl_strategies.append $('<option>').val(strat).text(strat)
  # Tooltip for check stats label
  $('#stats-check-label').tooltip
    trigger:      'hover'
    title:         ->
      if $('#stats-check').prop('checked')
        return "Disable detailed runtime statistics, this may improve execution time"
      else
        return "Enable detailed runtime statistics, this may affect execution time"

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
    Utils.track 'UI', 'property-parse-failed', name + ":" + err.message
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
  status:           'unknown'
  state:            ""
  formula:          ""
  engine:           "Local"
  encoding:         "MinMax"
  time:             "-"
  stats:            null
  strategy:         DefaultStrategy
  expensive_stats:  true

# Add property
addProp = (prop = defaultProp()) ->
  Utils.track 'UI', 'add-property'
  row = $('<tr>')
  row.append $('<td>').append $('<div>').addClass statuses[prop.status]
  row.append $('<td>').html(prop.state)
  p = $('<td>').addClass "formula"
  CodeMirror.runMode prop.formula, 'WCTL', p[0]
  row.append p
  row.append $('<td>').addClass("time").html prop.time
  closeBtn = $('<button title="Delete" class="close"> &times;</td>')
  closeBtn.click -> removeRow(row)
  row.append $('<td>').html closeBtn
  $('#properties > tbody').append row
  row.data 'property', prop
  row.click ->
    updateEditor $(this)
  return row

removeRow = (row) ->
  prop = row.data('property')
  if prop.worker?
    killRowProcess row
  $("#edit-form").show(0)
  $("#stats-view").hide(0)
  if _currentRow? and row.is _currentRow
    _currentRow = null
  row.remove()

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
          if prop.strategy == $('#search-strategy').val()
            changeStatus = false
  if changeStatus
    prop.status = 'unknown'
    if prop.worker?
      killRowProcess _currentRow
  prop.state = $("#edit-prop-init-state").val()
  prop.formula = _editor.getValue()
  prop.encoding = getEncoding()
  prop.engine = getEngine()
  prop.expensive_stats = $('#stats-check').prop('checked')
  prop.strategy = $('#search-strategy').val()
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
  if prop.status is 'working' or prop.stats?
    $("#edit-form").hide(0)
    $("#stats-view").show(0)
  else
    $("#edit-form").show(0)
    $("#stats-view").hide(0)
  if prop.stats?
    if prop.stats.result
      title = 'Formula is Satisfiable'
    else
      title = 'Formula is Unsatisfiable'
    $('#stats-view h3').html(title)
    tbody = $('#stats-view tbody')
    parent = tbody.parent()
    tbody.detach()
    tbody.empty()
    for key, value of prop.stats when key not in ['result', 'Time', 'TimeAsInt']
      val = value
      if typeof value is 'object'
        val = value.value
      th = $('<th>').html(key)
      td = $('<td>')
      tbody.append $('<tr>').append(th).append(td)
      # Runtime statistics graph
      if value.sparklines?
        options = 
          width:      '150px'
          height:     '22px'
        if value.options?
          for k, v of value.options
            options[k] = v
        td.append $('<div>').addClass('sparkline').sparkline value.sparklines, options
        td.append(" ")
      if val?
        td.append(val)
    parent.append tbody
    $('#kill-process').addClass 'hidden'
    $('#edit-prop').removeClass 'hidden'
  else if prop.status is 'working'
    $('#stats-view h3').html "Verification in Progress..."
    $('#stats-view tbody').empty()
    $('#kill-process').removeClass 'hidden'
    $('#edit-prop').addClass 'hidden'
  _dontSaveAtTheMoment = true
  $('#stats-check').prop('checked', prop.expensive_stats)
  $("#edit-prop-init-state").val(prop.state)
  $('#search-strategy').val(prop.strategy)
  _editor.setValue prop.formula
  setEncoding prop.encoding
  setEngine prop.engine
  _dontSaveAtTheMoment = false
  $.sparkline_display_visible()

Init ->
  $('#edit-prop').click ->
    if _currentRow?
      prop = _currentRow.data('property')
      prop.stats = null
      updateEditor(_currentRow)

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
# Encoding
setEncoding = (encoding) ->
  $('#edit-prop-encoding > .btn').removeClass 'disabled'
  $('#edit-prop-encoding > .btn').each ->
    if $(this).data('encoding') is encoding
      $(this).addClass 'disabled'

getEncoding = -> $('#edit-prop-encoding > .btn.disabled').data('encoding')
# Engine
setEngine = (engine) ->
  $('#edit-prop-engine > .btn').removeClass 'disabled'
  $('#edit-prop-engine > .btn').each ->
    if $(this).data('engine') is engine
      $(this).addClass 'disabled'
  if engine is 'Local'
    $('#search-strategy').fadeIn(200)
  else
    $('#search-strategy').fadeOut(200)

getEngine = -> $('#edit-prop-engine > .btn.disabled').data('engine')

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
    Utils.track 'verify', 'killed'

startVerification = ->
  saveCurrentRow()
  row = _currentRow
  prop = row.data('property')
  prop.status = 'working'
  prop.worker = new Worker('scripts/VerificationWorker.js');
  # Update time
  start = new Date().getTime()
  updateTime = ->
    elapsed = (new Date()).getTime() - start
    formatted = elapsed + " ms"
    row.find('.time').html formatted
    return formatted
  prop.update_interval = setInterval updateTime, 150
  # Onmessage
  prop.worker.onmessage = (e) ->
    prop = row.data('property')
    clearInterval(prop.update_interval)
    prop.time = updateTime()
    prop.update_interval = null
    prop.worker.terminate()
    prop.worker = null
    if e.data.result
      prop.status = 'satisfied'
    else
      prop.status = 'unsatisfied'
    Utils.track 'verify', 'finished', prop.status, e.data.TimeAsInt
    prop.stats = e.data
    prop.time  = e.data.Time
    row.find('.time').html prop.time
    row.children("td").eq(0).find("div").removeClass().addClass(statuses[prop.status])
    if _currentRow? and row.is _currentRow
      updateEditor row
  # Error handling
  prop.worker.onerror = (error) ->
    prop = row.data('property')
    clearInterval(prop.update_interval)
    prop.time = updateTime()
    Utils.track 'verify', 'failed-error', error, prop.time
    prop.update_interval = null
    prop.status = 'unknown'
    prop.worker.terminate()
    prop.worker = null
    row.children("td").eq(0).find("div").removeClass().addClass(statuses[prop.status])
    if _currentRow? and row.is _currentRow
      updateEditor row
    ShowMessage error.message
  strategy = null
  if prop.engine is 'Local'
    strategy = prop.strategy
    Utils.track 'verify', 'with-strategy', strategy
  # Post message to worker
  prop.worker.postMessage
    mode:             Editor.mode()
    model:            Editor.model()
    state:            prop.state
    property:         prop.formula
    engine:           prop.engine
    encoding:         prop.encoding
    strategy:         strategy
    expensive_stats:  prop.expensive_stats
  Utils.track 'verify', 'with-engine', prop.engine
  Utils.track 'verify', 'with-encoding', prop.encoding
  Utils.track 'verify', 'in-mode', Editor.mode()
  Utils.track 'verify-with', prop.encoding, prop.engine
  updateEditor _currentRow
