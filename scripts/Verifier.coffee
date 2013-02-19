
@Verifier ?= {}

status =
  unknown:      'icon-question-sign'
  satisfied:    'icon-ok'
  unsatisfied:  'icon-remove'
  working:      'icon-refresh'

Verifier.height = (h) ->
  $('#property-list').height  h
  $('#edit-property').height  h

Init ->
  $('#add-property').click ->
    addProp()
  $('#edit-prop-engine > .btn').click ->
    setEngine $(this).html()
  $("#edit-prop-save").click ->
    console.log "TODO: save"
  $("#edit-prop-cancel").click ->
    updateEditor null

addProp = (prop = {state: "", formula: ""}) ->
  row = $('<tr>')
  row.append $('<td>').append $('<div>').addClass status.unknown
  row.append $('<td>').html(prop.state)
  p = $('<td>')
  CodeMirror.runMode prop.formula, 'WCTL', p[0]
  row.append p
  $('#properties > tbody:last').append row
  row.data 'property', prop
  row.click ->
    updateEditor $(this)

_currentRow = null
updateEditor = (row) ->
  if _currentRow?
    #TODO Save
    prop = _currentRow.data('property')
    $("#edit-prop-init-state").val(prop.state)
    $("#edit-prop-formula").val(prop.formula)
  _currentRow = row
  $('#properties > tbody > tr').removeClass 'well'
  _currentRow?.addClass 'well'

Verifier.load = (props = []) ->
  for prop in props
    addProp(prop)

Verifier.save = ->
  props = []
  $('#properties > tbody tr').each ->
    props.push $(this).data 'property'
  return props

setEngine = (engine) ->
  $('#edit-prop-engine > .btn').removeClass 'disabled'
  $('#edit-prop-engine > .btn').each ->
    if $(this).html() is engine
      $(this).addClass 'disabled'

getEngine = -> $('#edit-prop-engine > .btn.disabled').html()