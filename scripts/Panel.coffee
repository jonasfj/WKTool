_layout = null
_layoutState = null


_inits = []
@Init = (c) -> _inits.push c
$ ->
  for c in _inits
    c()
  options = 
    applyDefaultStyles:   false
    onresize:             -> Editor.height $('#editor').height() - 30
    maxSize:              "80%"
    fxSpeed:              "slow"
  # Restore session before creating the panes
  # so that when panes are created, they can be created with initial state
  # this avoid weird animation when pane is initially closed
  restoreSession()
  # Pane state in load() used by restoreSession() is stored in _layoutState as dictionary,
  # if _layout wasn't created at the time load() was called.
  # Read it and convert to initial settings for the pane
  if _layoutState?
    options['south__initClosed']  = _layoutState.closed
    options['south__size']        = _layoutState.size
  $(window).resize()
  _layout = $('#splitter').layout(options)
  Editor.height $('#editor').height() - 30

Init ->
  $(window).resize ->
    $('#splitter').height $(window).height() - $('.navbar').height() - 20
  
# Load from JSON
load = (json = {}) ->
  max_untitled = updateLoadMenu()
  $('#project-name').val  json.name or "Untitled Project #{max_untitled + 1}"
  Editor.load             json.model
  Verifier.load           json.properties
  if json.pane?
    if not _layout?
      # Handle case where _layout isn't created yet, this is first load case
      # We store state in _layoutState
      _layoutState =
        size:   json.pane.size
        closed: json.pane.closed
    else
      if json.pane.closed
        _layout.close 'south'
      else
        _layout.open 'south'
      _layout.sizePane('south', json.pane.size or 350)
  else
    if not _layout?
      _layoutState =
        size:   350
        closed: false
    else
      _layout.sizePane('south', 350)

# Save current document to json
save = ->
  name:         $('#project-name').val()
  model:        Editor.save()
  properties:   Verifier.save()
  pane:
    closed:       _layout.state.south.isClosed
    size:         _layout.state.south.size

Init ->
  updateLoadMenu()
  $('#save-menu').click ->
    saveToLocalStorage()
    Utils.track 'UI', 'menu-click', 'save-to-localstorage'

updateLoadMenu = ->
  # Clear contents
  examples = $('#examples-menu').detach()
  $('#load-menu').empty()
  $('#delete-menu-items').empty()
  # Read from localStorage
  max_untitled = 0    # Largest untitled project
  entries      = []   # Entries to add (sort first though)
  del_entries  = []   # Entries for the delete menu
  for i in [0...localStorage.length]
    match = /^project\/([^]*)$/.exec localStorage.key(i)
    if match?
      name = match[1]
      # Add divider if first hit
      if add_divider
        add_divider = false
        
      # Add entry to load item
      entry = $('<a>')
      entry.html(name)
      entry.data('project-name', name)
      entry.click loadMenuItemClick
      entries.push entry
      
      # Add entry to delete menu
      entry = $('<a>')
      entry.html(name)
      entry.data('project-name', name)
      entry.click deleteMenuItemClick
      del_entries.push entry

      # Count number of untitled projects
      match = /Untitled Project ([1-9][0-9]*)/.exec name
      if match?
        max_untitled = Math.max max_untitled, match[1]
  
  # Sort entries by project name
  ordering = (a, b) -> 
    if a.data('project-name') > b.data('project-name')
      return 1
    return -1
  entries.sort      ordering
  del_entries.sort  ordering
  
  # Append entries to load menu
  for entry in entries
    $('#load-menu').append $('<li>').append entry
  # Append divider (if needed)
  if entries.length > 0
    $('#load-menu').append $('<li>').addClass 'divider'
  # Append "Empty project" option
  link = $('<a>').html("Empty project").click ->
    loadEmptyProject()
    Utils.track 'UI', 'menu-click', 'load-empty-project'
  $('#load-menu').append $('<li>').append link
  # Append "Load example"
  $('#load-menu').append examples
  # Append "Load from file" option
  link = $('<a>').html("Load from file").click loadFromFileMenuItemClick
  $('#load-menu').append $('<li>').append link
  
  # Append entries to delete menu
  for entry in del_entries
    $('#delete-menu-items').append $('<li>').append entry
  # Enable or disable delete menu
  if del_entries.length > 0
    $('#delete-menu').removeClass 'disabled'
  else
    $('#delete-menu').addClass 'disabled'
  
  return max_untitled

loadEmptyProject = ->
  load()

# Keep loaded project name around
# We only alert about overwriting if it was changed!
_loadedProjectName = null

saveToLocalStorage = ->
  name = $('#project-name').val()
  if _loadedProjectName isnt name
    if localStorage.getItem("project/#{name}")?
      $('.overwrite-name').html name
      $('#overwrite-warning').modal()
      Utils.track 'UI', 'overwrite-localstorage-warning', name
  saveWithOverwriteToLocalStorage()

Init ->
  $('#overwrite-button').click saveWithOverwriteToLocalStorage

saveWithOverwriteToLocalStorage = ->
  name = $('#project-name').val()
  localStorage.setItem "project/#{name}", JSON.stringify save()
  _loadedProjectName = name
  updateLoadMenu()
  ShowMessage "Saved \"#{name}\" to LocalStorage"
  Utils.track 'UI', 'save-to-localstorage', name

loadMenuItemClick = ->
  name = $(this).data 'project-name'
  json = localStorage.getItem "project/#{name}"
  if json?
    load JSON.parse json
    _loadedProjectName = name
    ShowMessage "Loaded \"#{name}\" from LocalStorage"
    Utils.track 'UI', 'loaded-from-localstorage', name
  else
    ShowMessage "Failed to load \"#{name}\" from LocalStorage"
    updateLoadMenu()
    Utils.track 'UI', 'error', "Failed to load #{name} from localStorage"
  Utils.track 'UI', 'menu-click', 'load-from-localstorage'

# Show file browser using #file-browser
loadFromFileMenuItemClick = ->
  $('#file-browser').click()
  Utils.track 'UI', 'menu-click', 'load-from-file'

# Open file, when loaded using #file-browser
Init ->
  $('#file-browser').change ->
    file = this.files[0]
    if file?
      reader = new FileReader()
      reader.onload = ->
        load JSON.parse reader.result
        ShowMessage "Loaded \"#{$('#project-name').val()}\" from \"#{file.name}\""
        Utils.track 'UI', 'loaded-from-file', $('#project-name').val()
      reader.readAsText file


deleteMenuItemClick = ->
  name = $(this).data 'project-name'
  if localStorage.getItem("project/#{name}")?
    removeFromStorage = ->
      $('#delete-button').off 'click.removeFromStorage'
      localStorage.removeItem("project/#{name}")
      updateLoadMenu()
      ShowMessage "Removed \"#{name}\" from LocalStorage"
    $('.delete-name').html name
    $('#delete-button').on 'click.removeFromStorage', removeFromStorage
    $('#delete-warning').modal()
  else
    ShowMessage "Failed to delete \"#{name}\" from LocalStorage"
    updateLoadMenu()
    Utils.track 'UI', 'error', 'failed to delete from localstorage'
  Utils.track 'UI', 'menu-click', 'delete-menu-item'


_showMessageTimeout = null
@ShowMessage = (msg) ->
  $('#message-box').html(msg).fadeIn(500)
  if _showMessageTimeout?
    clearTimeout _showMessageTimeout
  _showMessageTimeout = setTimeout (-> $('#message-box').fadeOut(500)), 2000

# Create blob url to download file on-the-fly
Init ->
  _lastBlobUrl = null
  $('#download-file').mousedown ->
    if _lastBlobUrl?
      URL.revokeObjectURL _lastBlobUrl
    _lastBlobUrl = URL.createObjectURL new Blob([JSON.stringify save()])
    $('#download-file')[0].href = _lastBlobUrl
    $('#download-file')[0].download = $('#project-name').val() + '.wkp'
    Utils.track 'UI', 'menu-click', 'export-file'


Init ->
  $('#examples a').click ->
    loadExample $(this).html()
    Utils.track 'UI', 'menu-click', 'load-example'
  # Load scalable examples
  models = (name for name, factory of ScalableModels).sort()
  $('#examples').append $('<div>').addClass 'divider'
  for model in models
    link = $('<a>')
    link.html(model)
    link.data('model', model)
    link.click loadScalableModelMenuItemClick
    $('#examples').append $('<li>').append link
  $('#load-scalable-model-button').click loadScalableModelDialogFinished

loadScalableModelMenuItemClick = ->
  model_name = $(this).data('model')
  model = ScalableModels[model_name]
  # Create body with input fields for parameters
  body = $('#scalable-model-dialog .modal-body')
  body.empty()
  for param, i in model.parameters
    init_val = model.defaults[i]
    p   = $('<p>').html(param)
    div = $('<div>').addClass 'input-prepend'
    div.append $('<span>').addClass('add-on').html('Enter number:')
    div.append $('<input />').attr(type: 'text').val(init_val).data('index', i)
    body.append p
    body.append div
  $('.scalable-model-name').html(model_name)
  $('#scalable-model-dialog').data('model', model_name)
  $('#scalable-model-dialog').modal()
  Utils.track 'UI', 'menu-click', 'load-scalable-model'


loadScalableModelDialogFinished = ->
  model_name = $('#scalable-model-dialog').data('model')
  model = ScalableModels[model_name]
  
  params = []
  $("#scalable-model-dialog .modal-body input").each ->
    if not params?
      return
    val   = $(this).val()
    ival  = parseInt val
    if typeof ival isnt 'number' and ival % 1 is 0
      ShowMessage "Model Instantiation Failed \"#{val}\" isn't a number!"
      params = null
      Utils.track 'UI', 'failed-scalable-model-instantiation', model_name
      return
    params[$(this).data('index')] = ival
    Utils.track 'scalable-models', model_name, model.parameters[$(this).data('index')], ival
  if not params?
    return
  
  m = model.factory(params...)
  if m?
    load m
    ShowMessage "Instantiated and Loaded \"#{model_name}\""
    Utils.track 'UI', 'loaded-scalable-model', model_name

# Load from example
loadExample = (name) ->
  $.ajax
    url:        "examples/#{name}.wkp"
    dataType:   'json'
    success: (data) ->
      load data
      ShowMessage "Loaded the \"#{name}\" example!"
      Utils.track 'UI', 'loaded-example', name
    error: ->
      ShowMessage "Failed to load the \"#{name}\" example!"
      Utils.track 'UI', 'error', "Failed to load example #{name}"

restoreSession = ->
  name = localStorage.getItem "last-loaded-project-name"
  session = localStorage.getItem "last-session"
  if name? and session?
    _loadedProjectName = JSON.parse name
    load JSON.parse session
  else
    loadEmptyProject()

# Save current session on unload
$(window).unload ->
  localStorage.setItem "last-loaded-project-name", JSON.stringify _loadedProjectName
  localStorage.setItem "last-session", JSON.stringify save()

#### Visualization
Init ->
  layer = $('#visualization-layer')
  frame = $('#visualization-layer iframe')
  overwriteFrame = false
  layer.click ->
    overwriteFrame = true
    layer.fadeOut ->
      if overwriteFrame
        frame.prop('src', "")
  $('#visualize').click ->
    layer.fadeIn()
    overwriteFrame = false
    frame.prop 'src', "visualize.html"
    Utils.track 'UI', 'menu-click', 'visualize'

window.onmessage = (e) ->
  if e.origin isnt Utils.origin()
    return
  if e.data.type is 'request-model-message'
    e.source.postMessage(
        type:       'visualize-model-message'
        model:      Editor.model()
        mode:       Editor.mode()
      , Utils.origin())
  if e.data.type is 'close-visualization-message'
    $('#visualization-layer').click()
  if e.data.type is 'visualization-error-message'
    $('#visualization-layer').click()
    if typeof e.data.message is 'string'
      ShowMessage e.data.message
  if e.data.type is 'close-help-message'
    $('#help-layer').click()

#### Visualization
Init ->
  layer = $('#help-layer')
  frame = $('#help-layer iframe')
  layer.click ->
    layer.fadeOut ->
      frame.prop('src', "")
  $('#show-help').click ->
    layer.fadeIn()
    frame.prop 'src', "help.html"
    Utils.track 'UI', 'menu-click', 'help'

# Hack that removes task graph fetching code from ScalableModels
@fetchTaskGraph = (file) ->
  req = new XMLHttpRequest()
  req.open 'GET', Utils.origin() + file, false
  req.send null
  data = null
  if req.status is 200
    data = req.responseText
  return data