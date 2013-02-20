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
    height = $(window).height() - $('.navbar').height() - 60
    Editor.height   height / 3
    Verifier.height height * 2 / 3

# Load from JSON
load = (json) ->
  $('#project-name').val  json.name
  Editor.load             json.model
  Verifier.load           json.properties

# Save current document to json
save = ->
  name:         $('#project-name').val()
  model:        Editor.save()
  properties:   Verifier.save()

Init ->
  max_untitled = updateLoadMenu()
  $('#save-menu').click saveToLocalStorage
  # Create untitled project title
  $('#project-name').val "Untitled Project #{max_untitled + 1}"

updateLoadMenu = ->
  # Clear contents
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
  # Append "Load from file" option
  link = $('<a>').html("Load from file").click loadFromFile
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

# Keep loaded project name around
# We only alert about overwriting if it was changed!
_loadedProjectName = null

saveToLocalStorage = ->
  name = $('#project-name').val()
  if _loadedProjectName isnt name
    if localStorage.getItem("project/#{name}")?
      $('.overwrite-name').html name
      $('#overwrite-warning').modal()
  saveWithOverwriteToLocalStorage()

Init ->
  $('#overwrite-button').click saveWithOverwriteToLocalStorage

saveWithOverwriteToLocalStorage = ->
  name = $('#project-name').val()
  localStorage.setItem "project/#{name}", JSON.stringify save()
  _loadedProjectName = name
  updateLoadMenu()
  ShowMessage "Saved \"#{name}\" to LocalStorage"

loadMenuItemClick = ->
  name = $(this).data 'project-name'
  json = localStorage.getItem "project/#{name}"
  if json?
    load JSON.parse json
    _loadedProjectName = name
    ShowMessage "Loaded \"#{name}\" from LocalStorage"
  else
    ShowMessage "Failed to load \"#{name}\" from LocalStorage"
    updateLoadMenu()

loadFromFile = ->


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


_showMessageTimeout = null
ShowMessage = (msg) ->
  $('#message-box').html(msg).fadeIn(500)
  if _showMessageTimeout?
    clearTimeout _showMessageTimeout
  _showMessageTimeout = setTimeout (-> $('#message-box').fadeOut(500)), 2000