_inits = []
@Init = (c) -> _inits.push c
$ ->
  for c in _inits
    c()
  $(window).resize()


Init ->
  $('#examples a').click ->
    console.log $(this).html()
  # TODO Make this resizeable...
  $(window).resize ->
    height = $(window).height() - $('.navbar').height() - 40
    Editor.height   height / 3
    Verifier.height height * 2 / 3


# Load from JSON
load = (json) ->
  $('#project-name').val  json.name
  Editor.load             json.model
  Verifier.load           json.properties

# Save current document to blob
save = ->
  return new Blob [
      JSON.stringify
        name:         $('#project-name').val()
        model:        Editor.save()
        properties:   Verifier.save()
    ]
