###

Various interfaces:

Global objects we create:
  Editor
  Verifier

Editor.load(json)           // Loads from json
Editor.save()               returns json

Verifier.load(json)         // Loads from json
Verifier.save()             returns json

Everything is glued together from Panel.coffee
###


$ ->
  $('#examples a').click ->
    console.log $(this).html()

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

