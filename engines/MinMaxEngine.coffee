# A min/max node
class Node
  constructor: (@state, @assertion, @formula) ->
    @value = Infinity       # assignment
    @expanded = false       # Expanded
    @min = true             # type of node min/max
    @targets = null         # target set of edges leaving, ie list of weighted and ternary edges
    @deps = []              # dependency set of the node
    @queue_number = 0
    @in_queue = false
  level: -> @formula.level  # Gets the cover-level of the node
  expand: ->                # Expand formula and generate successors
    if not @expanded
      @expanded = true
      @formula.mmExpand(@)
      return true
    return false
  depends: (node) ->        # Dependency set of node
    if node not in @deps
      @deps.push node
    return

Queues = null

# Weighted edge in the MMG
class WeightedEdge
  constructor: (@weight, @target) ->
  result: -> @target.value + @weight
  res: -> @target.value + @weight
  finished: (u) -> (u.level() == @target.level()) or (@target.expanded and Queues[@target.level()].empty())

# Ternary edge in the MMG
class TernaryEdge
  constructor: (@k, @w1, @w2, @target) ->
  res: ->
    # Check the cover-condition and return appropriate value
    if @target.value < @k
      return @w1
    return @w2
  result: ->
    # Check the cover-condition and return appropriate value
    if @target.value < @k
      return @w1
    if @target.expanded and Queues[@target.level()].empty()
      return @w2
    return Math.max(@w1, @w2)
  finished: -> (@target.expanded and Queues[@target.level()].empty()) or @target.value < @k

# Gets a node, given state, assertion and formula
getNode = (state, assertion, formula) ->
  if assertion
    tbl = state.__Tnodes ?= {} # assert true nodes
  else
    tbl = state.__Fnodes ?= {} # assert false nodes
  node = tbl[formula.id]
  # if node does not exist on the state, create and insert into dictionary
  if not node?
    tbl[formula.id] = node = new Node(state, assertion, formula)
  return node 

# MinMax local/global implementation
class @MinMaxEngine
  constructor: (@formula, @initState) ->

  local: (exp_stats, Queue) ->
    Queues = Q = []
    @formula.setLevel 0
    
    v0 = getNode(@initState, true, @formula)
    v0.expand()
    Q[0] = Q0 = new Queue()
    Q0.push_dep v0

    j = 0
    maxj = 1
    while (not Q0.empty()) and v0.value isnt -Infinity
      # Next j, in round-robin
      j = (j + 1) % maxj
      
      Qj = Q[j]
      if not Qj? or Qj.empty()
        continue
      u = Qj.pop()
      u.in_queue = false
      finished = true
      if u.min # min-node
        val = Infinity
        for edge in u.targets or []
          res = edge.result()
          if res < val
            val = edge.result()
          if edge.target.expand()
            l = edge.target.level()
            if maxj < l + 1
              maxj = l + 1
            Ql = Q[l] ?= new Queue()
            Ql.push_dep edge.target
            edge.target.depends u
          finished = finished and edge.finished(u)
      else # max-node
        val = -Infinity
        worst = null
        worst_edge = null
        for edge in u.targets or []
          res = edge.result()
          if res > val
            val = edge.result()
            worst = edge.target
            worst_edge = edge
        if worst?
          if worst.expand()
            l = worst.level()
            if maxj < l + 1
              maxj = l + 1
            Ql = Q[l] ?= new Queue()
            Ql.push_dep worst
          finished = worst_edge.finished(u)
          worst.depends u
      if not finished # re-add source node to queue
        Qj.push_dep u
      if val < u.value
        u.value = val
        for d in u.deps
          l = d.level()
          Q[l].push_dep d
    return {
      result:           v0.value is Infinity
    }

  global: (exp_stats) ->
    @formula.setLevel 0
    maxj = 0
    v0 = getNode(@initState, true, @formula)
    Qs = []
    Qs[0] = [v0]
    W = [v0]
    while W.length isnt 0
      u = W.pop()
      if u.expand()
        for edge in u.targets or []
          W.push edge.target
          l = edge.target.level()
          Qs[l] ?= []
          Qs[l].push edge.target
          if maxj < l
            maxj = l
    for j in [maxj..0]
      Qj = Qs[j]
      finished = true
      while finished
        finished = false
        for u in Qj
          if u.min
            val = Infinity
            for edge in u.targets or []
              v = edge.res()
              if val > v
                val = v
          else
            val = -Infinity
            for edge in u.targets or []
              v = edge.res()
              if val < v
                val = v
          if val < u.value
            u.value = val
            finished = true
        if v0.value is -Infinity
          break
    return {
      result:     v0.value is Infinity
    }


class IntermediateExpr extends WCTL.Expr
  constructor: (@level) ->

IntermediateExpr::mmExpand          = (node) ->
  return

# Expansion of boolean formula 'true/false'
WCTL.BoolExpr::mmExpand             = (node) ->
  node.min = (@value == node.assertion)
  return

# Expansion of atomic formula; a in AP
WCTL.AtomicExpr::mmExpand           = (node) ->
  node.min = (node.assertion == ((not @negated) == node.state.hasProp(@prop)))
  return

# Expansion of logical connective; and/or
WCTL.OperatorExpr::mmExpand         = (node) ->
  c1 = getNode(node.state, node.assertion, @expr1)
  c2 = getNode(node.state, node.assertion, @expr2)
  node.targets = [new WeightedEdge(0, c1), new WeightedEdge(0, c2)]
  node.min = (node.assertion == (@operator == WCTL.operator.AND))
  return

# Expansion of until-expression: Q e1 U[<b] e2
WCTL.UntilUpperExpr::mmExpand            = (node) ->
  state = node.state
  node.min = true
  
  # If not a symbolic node
  if @bound isnt '?'
    sym_node = getNode(state, false, @abstract())
    sign = node.assertion - (not node.assertion)  # Note to self: We are smart!!!
    node.targets = [new TernaryEdge(@bound + 1, sign * Infinity, sign * -Infinity, sym_node)]
    return
  # Edge to formula e2
  e2 = new TernaryEdge(0, 0, Infinity, getNode(state, false, @expr2))
  if @quant is WCTL.quant.E # Existential quantification
    node.targets = [e2]
    state.next (weight, target) =>
      ni = new Node(null, null, new IntermediateExpr(@level)) # intermediate node for every successor state
      ni.min = false
      ni.targets = [
        new WeightedEdge(0, getNode(state, false, @expr1)),
        new WeightedEdge(weight, getNode(target, false, @))
      ]
      node.targets.push new WeightedEdge(0, ni)
    return
  else if @quant is WCTL.quant.A # Universal quantification
    node.targets = [e2]
    children = []
    # intermediate max-node connected to every successor state
    state.next (weight, target) =>
      children.push(new WeightedEdge(weight, getNode(target, false, @)))
      return
    if children.length > 0
      ni = new Node(null, null, new IntermediateExpr(@level)) 
      ni.min = false
      children.push new WeightedEdge(0, getNode(state, false, @expr1))
      ni.targets = children
      node.targets.push new WeightedEdge(0, ni)
    return
  else
    throw "Unknown quantifier #{@quant}"
  return


# Expansion of weak-until-expression: Q e1 U[>b] e2
WCTL.WeakUntilExpr::mmExpand            = (node) ->
  state = node.state
  node.min = false
  
  # If not a symbolic node
  if @bound isnt '?'
    sym_node = getNode(state, true, @abstract())
    sign = (not node.assertion) - node.assertion  # Note to self: We are smart!!!
    node.targets = [new TernaryEdge(@bound + 1, sign * Infinity, sign * -Infinity, sym_node)]
    return
  # Edge to formula e2
  e2 = new TernaryEdge(0, -Infinity, 0, getNode(state, true, @expr2))
  if @quant is WCTL.quant.E # Existential quantification
    node.targets = [e2]
    state.next (weight, target) =>
      ni = new Node(null, null, new IntermediateExpr(@level)) # intermediate node for every successor state
      ni.min = true
      ni.targets = [
        new WeightedEdge(0, getNode(state, true, @expr1)),
        new WeightedEdge(weight, getNode(target, true, @))
      ]
      node.targets.push new WeightedEdge(0, ni)
    return
  else if @quant is WCTL.quant.A # Universal quantification
    node.targets = [e2]
    children = []
    # intermediate max-node connected to every successor state
    state.next (weight, target) =>
      children.push(new WeightedEdge(weight, getNode(target, true, @)))
      return
    if children.length > 0
      ni = new Node(null, null, new IntermediateExpr(@level)) 
      ni.min = true
      children.push new WeightedEdge(0, getNode(state, true, @expr1))
      ni.targets = children
      node.targets.push new WeightedEdge(0, ni)
    return
  else
    throw "Unknown quantifier #{@quant}"
  return


# Expansion of next operator
WCTL.NextExpr::mmExpand             = (node) ->
  state = node.state
  
  node.targets = []
  state.next (weight, target) =>
    if (@re is '<' and weight < @bound) or (@re is '>' and weight > @bound)
      node.targets.push new WeightedEdge(0, getNode(target, node.assertion, @expr))
    return
  if node.targets.length is 0
    node.targets = null
  
  node.min = node.assertion == (@quant is WCTL.quant.A)
  return

# Expansion of not operator
WCTL.NotExpr::mmExpand             = (node) ->
  node.min = true
  node.targets = [
    new WeightedEdge(0, getNode(node.state, not node.assertion, @expr))
  ]
  return

# Comparison Operator
WCTL.ComparisonExpr::mmExpand       = (node) ->
  v1 = @expr1.evaluate(node.state)
  v2 = @expr2.evaluate(node.state)
  node.min = (@cmpOp(v1, v2) == node.assertion)
  return