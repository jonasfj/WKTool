
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
    console.log "save row" + _currentRow.data('property')
  _currentRow = row

Verifier.load = (props = []) ->
  for prop in props
    addProp(prop)

Verifier.save = ->
  props = []
  $('#properties > tbody tr').each ->
    props.push $(this).data 'property'
  return props
