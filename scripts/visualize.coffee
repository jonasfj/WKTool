_inits = []
@Init = (c) -> _inits.push c
$ ->
  for c in _inits
    c()


window.onmessage = (e) ->
  if e.origin isnt WKToolOrigin
    return
  if e.data.type is 'visualize-model-message'
    if typeof e.data.mode is 'string' and typeof e.data.model is 'string'
      parseModel e.data.model, e.data.mode

Init ->
  window.parent.postMessage(type: 'request-model-message', WKToolOrigin)
  $('.close-button').click ->
    window.parent.postMessage(type: 'close-visualization-message', WKToolOrigin)

_mode = null
parseModel = (model, mode) ->
  try
    wks = window["#{mode}Parser"].parse model
    # Empty strings returns arrays
    if not (wks instanceof Array)
      wks.resolve()
    else
      wks = null
  catch err
    wks = null
  if not wks?
    window.parent.postMessage(
        type:     'visualization-errr-message'
        message:  "Failed to parse model!"
      , WKToolOrigin)
  _mode = mode
  loadModel wks

_expandInitially = false
loadModel = (wks) ->
  for name in wks.getExplicitStateNames()
    $('#initial-state').append $('<option>').html(name).val(name)
  $('#expand-all').prop('checked', false)
  $('#expand-all').click ->
    $('#expand-all-warning').fadeToggle()
  $('#render-button').removeClass('disabled').click ->
    statename = $('#initial-state').val()
    state = wks.getStateByName(statename)
    if state?
      _expandInitially = $('#expand-all').prop('checked')
      renderModel(wks, state, statename)
    else
      window.parent.postMessage(
          type:     'visualization-errr-message'
          message:  "\"#{statename}\" is not a valid state"
        , WKToolOrigin)

_graph = null
_canvas = null
_ctx = null
_selectedNode = null
renderModel = (wks, state, statename) ->
  @_graph = _graph = arbor.ParticleSystem
      repulsion:    1000  # the force repelling nodes from each other
      stiffness:    600   # the rigidity of the edges
      friction:     0.5   # the amount of damping in the system
      gravity:      true  # an additional force attracting nodes to the origin
      fps:          30    # frames per second
      dt:           0.02  # timestep to use for stepping the simulation
      precision:    0.6   # accuracy vs. speed in force calculations
  # Created renderer
  _canvas = $("canvas")
  _ctx = _canvas[0].getContext("2d")
  _graph.renderer = 
    init: ->
    redraw: renderGraph
  _graph.screenPadding(80)
  $(window).resize ->
    w = $(window).width()
    h = $(window).height() - $('#render-title').height() - $('#meta-rows').height()
    _graph.screenSize(w, h)
    _canvas.prop 'width',  w
    _canvas.prop 'height', h
    renderGraph()
  # Explorer the WKS from initial state
  selectNode addToGraph state, statename
  # View the rendering, etc...
  $("#initial-state-form").remove()
  $("#statename").text(statename)
  $("#visualization").show()
  _canvas.mousedown(canvasMouseDown)
  _canvas.bind 'mousemove', canvasMouseMove
  $(window).resize()

# Add state to graph
addToGraph = (state, name) ->
  state = state.getThisState()
  name ?= state.name()
  if name?
    if name.length > 10
      name = name[0..8] + ".."
  return state._visualNode ?= _graph.addNode(state.id, {state, name, w: 10, expanded: false})

# Expand state (ie. add all transitions and target states, expanding these recursively)
expandToGraph = (state) ->
  n1 = addToGraph state
  # Check if this state has already been handled
  if n1.data.expanded
    return
  n1.data.expanded = true
  state.next (weight, target, action = null) ->
    n2 = addToGraph target
    #TODO Handle self loops
    #TODO Handle cases with more than 1 edge from source to target
    e1 = _graph.addEdge(n1, n2, {bend: false})
    if e1?
      for e2 in _graph.getEdges(n2, n1)
        e2.data.bend = true
        e1.data.bend = true
    if _expandInitially
      expandToGraph target
  return

renderGraph = ->
  # Draw white background
  _ctx.fillStyle = "white"
  _ctx.fillRect(0, 0, _canvas.prop('width'), _canvas.prop('height'))
  
  # Draw edges
  _ctx.strokeStyle = "#bbb"
  _ctx.lineWidth = 1
  _graph.eachEdge (edge, p1, p2) ->
    _ctx.beginPath()
    _ctx.moveTo(p1.x, p1.y)
    if edge.data.bend
      dx = p2.x - p1.x
      dy = p2.y - p1.y
      cx = p1.x + dx / 2 - dy / 4
      cy = p1.y + dy / 2 + dx / 4
      _ctx.quadraticCurveTo(cx, cy, p2.x, p2.y);
    else
      _ctx.lineTo(p2.x, p2.y)
    _ctx.stroke()
  
  # Draw nodes
  _ctx.fillStyle = "#bbb"
  _ctx.font = "12px 'Open Sans'"
  _ctx.textAlign = "center"
  _graph.eachNode (node, p) ->
    name = node.data.name
    w = 10
    h = 20
    if name?
      w = _ctx.measureText(name).width + 10
      if node is _selectedNode
        _ctx.fillStyle = "#888"
      _ctx.roundRect(p.x - w / 2, p.y - h / 2, w, h, 4)
      _ctx.fill()
      _ctx.fillStyle = "white"
      _ctx.fillText(name, p.x, p.y + 4)
      _ctx.fillStyle = "#bbb"
      node.data.w = w
    else
      r = 8
      _ctx.beginPath()
      _ctx.arc(p.x, p.y, r, 0, 2 * Math.PI, false)
      _ctx.closePath()
      if node is _selectedNode
        _ctx.fillStyle = "#888"
        _ctx.fill()
        _ctx.fillStyle = "#bbb"
      else if not node.data.expanded
        _ctx.fillStyle = "#32CD32"
        _ctx.fill()
        _ctx.fillStyle = "#bbb"
      else
        _ctx.fill()
      node.data.w = r * 2

_dragging = false
canvasMouseDown = (e) ->
  pos = _canvas.offset()
  mp  = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
  res = _graph.nearest(mp)
  if res? and res.distance < res.node.data.w / 2 + 5
    selectNode res.node
    _selectedNode.fixed = true
    $(window).bind 'mouseup', windowMouseUp
    _dragging = true
  e.originalEvent.preventDefault()

canvasMouseMove = (e) ->
  pos = _canvas.offset()
  mp  = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
  if _dragging
    _selectedNode.p = _graph.fromScreen(mp)
    _canvas.css 'cursor', 'move'
  else
    res = _graph.nearest(mp)
    if res? and res.distance < res.node.data.w / 2 + 5
      _canvas.css 'cursor', 'pointer'
    else
      _canvas.css 'cursor', 'default'

windowMouseUp = (e) ->
  _dragging = false
  _selectedNode.fixed = false
  _selectedNode.tempMass = 1000
  $(window).unbind 'mouseup', windowMouseUp

# Information about selected node
selectNode = (node) ->
  if node is _selectedNode
    return
  _selectedNode = node
  state = _selectedNode.data.state
  expandToGraph state
  CodeMirror.runMode state.stringify(), _mode, $('#current-state')[0]
  $('#current-props').text(state.props().join(', '))
  targets = $('#targets')
  parent = targets.parent()
  targets.detach()
  targets.empty()
  state.next (weight, target, action = null) ->
    tr = $('<tr>')
    tr.append $('<td>').addClass("weight").text(weight)
    tr.append $('<td>').addClass("action").text(action)
    td = $('<td>').addClass("state")
    CodeMirror.runMode target.stringify(), _mode, td[0]
    tr.append td
    targets.append tr
    tr.click ->
      selectNode addToGraph target
  parent.append targets
  renderGraph()

#### Auxiliary Canvas Methods for rectangles with rounded corners
# From http://stackoverflow.com/questions/1255512/how-to-draw-a-rounded-rectangle-on-html-canvas
CanvasRenderingContext2D::roundRect = (x, y, w, h, r) ->
  if w < 2 * r
    r = w / 2
  if h < 2 * r
    r = h / 2
  @beginPath()
  if r < 1
    @rect(x, y, w, h)
  else
    this.moveTo(x + r, y)
    this.arcTo(x + w, y, x + w, y + h, r)
    this.arcTo(x + w, y + h, x, y + h, r)
    this.arcTo(x, y + h, x, y, r)
    this.arcTo(x, y, x + w, y, r)
  @closePath()
  return

if window.opera?
  CanvasRenderingContext2D::roundRect = (x, y, w, h, r) ->
    if w < 2 * r
      r = w / 2
    if h < 2 * r
      r = h / 2
    @beginPath()
    if r < 1
      @rect(x, y, w, h)
    else
      @moveTo(x + r, y)
      @arcTo(x + r, y, x, y + r, r)
      @lineTo(x, y + h - r)
      @arcTo(x, y + h - r, x + r, y + h, r)
      @lineTo(x + w - r, y + h)
      @arcTo(x + w - r, y + h, x + w, y + h - r, r)
      @lineTo(x + w, y + r)
      @arcTo(x + w, y + r, x + w - r, y, r)
    @closePath()
    return