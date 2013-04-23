_inits = []
@Init = (c) -> _inits.push c
$ ->
  for c in _inits
    c()


window.onmessage = (e) ->
  if e.origin isnt Utils.origin()
    return
  if e.data.type is 'visualize-model-message'
    if typeof e.data.mode is 'string' and typeof e.data.model is 'string'
      parseModel e.data.model, e.data.mode

Init ->
  window.parent.postMessage({type: 'request-model-message'}, Utils.origin())
  $('.close-button').click ->
    window.parent.postMessage({type: 'close-visualization-message'}, Utils.origin())

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
      , Utils.origin())
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
        , Utils.origin())

_graph = null
_canvas = null
_ctx = null
_selectedNode = null
_highlightEdge = null
renderModel = (wks, state, statename) ->
  @_graph = _graph = arbor.ParticleSystem
      repulsion:    1000  # the force repelling nodes from each other
      stiffness:    600   # the rigidity of the edges
      friction:     0.5   # the amount of damping in the system
      gravity:      false # an additional force attracting nodes to the origin
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
  # Explorer the WKS from initial state
  selectNode addToGraph state, statename
  # View the rendering, etc...
  $("#initial-state-form").remove()
  $("#statename").text(statename)
  $("#visualization").show()
  _canvas.mousedown(canvasMouseDown)
  _canvas.bind 'mousemove', canvasMouseMove
  $(window).resize ->
    $('#splitter').height $(window).height() - $('#render-title').height()
  $(window).resize()
  setGraphSize = ->
    w = $(".ui-layout-center").width()
    h = $(".ui-layout-center").height() - 20
    _graph.screenSize(w, h)
    _canvas.prop 'width',  w
    _canvas.prop 'height', h
    renderGraph()
  $('#splitter').layout
    applyDefaultStyles:   false
    onresize:             setGraphSize
    maxSize:              "80%"
    fxSpeed:              "slow"
  $(window).resize()
  setGraphSize()

# Add state to graph
addToGraph = (state, name) ->
  name ?= state.name()
  state = state.getThisState()
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
    edge = _graph.addEdge(n1, n2, {bend: 0})
    if edge?
      # Edges with same or opposite direction
      same = _graph.getEdges(n1, n2)
      oppo = _graph.getEdges(n2, n1)
      # Avoid self-loops
      if n1 isnt n2
        edge.data.bend = same.length
        if oppo.length == 0
          edge.data.bend -= 1
        if same.length == 1 and oppo.length > 0
          for e in oppo
            e.data.bend += 1
    if _expandInitially
      expandToGraph target
  if not _expandInitially
    Utils.track 'visualize', 'expand-state'
  return

_edgedistance = 1
_radius = 8
_arrowlength = 10
_arrowwidth  = 5
_selfloop = 50
renderGraph = ->
  # Draw white background
  _ctx.fillStyle = "white"
  _ctx.fillRect(0, 0, _canvas.prop('width'), _canvas.prop('height'))
  
  # Draw edges
  _ctx.strokeStyle = "#bbb"
  _ctx.fillStyle = "#bbb"
  _ctx.lineWidth = 1
  _graph.eachEdge (edge, p1, p2) ->
    line = p2.subtract p1
    unit = line.normalize()
    # handle self loops
    selfloop = unit.exploded()
    if selfloop
      p2 = p2.subtract arbor.Point(_selfloop, _selfloop)
      line = p2.subtract p1
      unit = line.normalize()
    if edge.source.data.name?
      # If p1 is a rect, make complicated intersection
      fx = Math.abs((edge.source.data.w / 2) / unit.x)
      fy = Math.abs(10 / unit.y)
      factor = Math.min(fx, fy)
      p1 = p1.add unit.multiply (factor + _edgedistance)
    else
      # if p2 is a circle, use _radius
      p1 = p1.add unit.multiply (_radius + _edgedistance)
    if not selfloop
      if edge.target.data.name?
        # If p2 is a rect, make complicated intersection
        fx = Math.abs((edge.target.data.w / 2) / unit.x)
        fy = Math.abs(10 / unit.y)
        factor = Math.min(fx, fy)
        p2 = p2.subtract unit.multiply (factor + _edgedistance)
      else
        # if p2 is a circle, use _radius
        p2 = p2.subtract unit.multiply (_radius + _edgedistance)
    
    if edge is _highlightEdge
      _ctx.strokeStyle = "#888"
      _ctx.fillStyle = "#888"
      _ctx.lineWidth = 2
    line = p2.subtract p1
    norm = line.normal()
    cp = p1.add line.divide(2)
    _ctx.beginPath()
    _ctx.moveTo(p1.x, p1.y)
    if selfloop
      p1.x += 10
      _ctx.moveTo(p1.x - 10, p1.y)
      cp = p1.add arbor.Point(_selfloop, - _selfloop)
      _ctx.bezierCurveTo(p1.x - _selfloop, p1.y - _selfloop, cp.x, cp.y, p1.x, p1.y)
      p2 = p1
    else if edge.data.bend > 0
      cp = cp.add norm.multiply(edge.data.bend / 4)
      _ctx.quadraticCurveTo(cp.x, cp.y, p2.x, p2.y);
    else
      _ctx.lineTo(p2.x, p2.y)
    _ctx.stroke()
    #Draw arrow head
    _ctx.beginPath()
    _ctx.moveTo(p2.x, p2.y)
    unit = (p2.subtract cp).normalize()
    al = p2.subtract unit.multiply(_arrowlength)
    ap = al.add unit.normal().multiply(_arrowwidth)
    _ctx.lineTo(ap.x, ap.y)
    ap = al.add unit.normal().multiply(- _arrowwidth)
    _ctx.lineTo(ap.x, ap.y)
    _ctx.lineTo(p2.x, p2.y)
    _ctx.fill()
    
    if edge is _highlightEdge
      _ctx.strokeStyle = "#bbb"
      _ctx.fillStyle = "#bbb"
      _ctx.lineWidth = 1
  # Draw nodes
  _ctx.fillStyle = "#bbb"
  _ctx.font = "12px 'Open Sans'"
  _ctx.textAlign = "center"
  _graph.eachNode (node, p) ->
    name = node.data.name
    if name?
      w = 10
      h = 20
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
      _ctx.beginPath()
      _ctx.arc(p.x, p.y, _radius, 0, 2 * Math.PI, false)
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
      node.data.w = _radius * 2

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
    Utils.track 'visualize', 'graph-node-clicked'
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
    #TODO Post-pone rendering to on-scroll, ie. when the element becomes visible
    CodeMirror.runMode target.stringify(), _mode, td[0]
    tr.append td
    targets.append tr
    tr.click ->
      _highlightEdge = null
      selectNode addToGraph target
      Utils.track 'visualize', 'target-clicked-in-target-list'
    myEdge = null
    tr.mouseenter ->
      if not myEdge?
        edges = _graph.getEdges addToGraph(state), addToGraph(target)
        if edges.length > 0
          myEdge = edges[0]
      _highlightEdge = myEdge
      renderGraph()
    tr.mouseleave ->
      if myEdge is _highlightEdge
        _highlightEdge = null
        renderGraph()
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