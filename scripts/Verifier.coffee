
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
  row = $('#properties > tbody:last').append('<tr>')
  row.append('<td>').append('<div>').addClass status.unknown
  row.append('<td>').html(state)
  row.append('<td>')

Verifier.load = (props = []) ->
  for prop in props
    addProp(prop)

Verifier.save = -> {}
