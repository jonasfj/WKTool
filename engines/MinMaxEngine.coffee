# A min/max node
class Node
  constructor: (@state, @assertion, @formula) ->
    @value = null           # assignment
    @min = true             # type of node min/max
    @strictChildren = null  # required nodes in another equivalence class
    @targets = null         # target set of nodes; either connected with weighted or ternary edge
    @deps = []              # dependency set of the node
    @queue_number = 0
  dep: (node) ->
    @deps.push node         if node not in @deps

# Weighted edge in the MMG
class WeightedEdge
  constructor: (@weight, @target) ->
  result: -> @target.value + @weight

# Ternary edge in the MMG
class TernaryEdge
  constructor: (@k, @w1, @w2, @target) ->
  result: ->
    # Check the cover-condition and return appropriate value
    if @target.value < @k
      return @w1
    return @w2

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

  local: (exp_stats, queueFactory) ->
    v0 = getNode(@initState, true, @formula)
    stack = []
    queue = new queueFactory()
    v0.formula.mmExpand(v0)
    queue.push v0
    stack.push(queue)

    # Keep track of the queue depth
    queue = null
    queue_number = 0
    # Enqueue node if its queue number is smaller
    enqueue = (n) ->
      if n.queue_number < queue_number
        queue.push n
        n.queue_number = queue_number
      return

    while stack.length > 0
      queue = stack.pop()
      queue_number += 1
      while not queue.empty()
        node = queue.pop()
        node.queue_number -= 1
        old_value = node.value
        if node.strictChildren isnt null # if node depends on another equivalence class
          child = node.strictChildren.pop()
          if node.strictChildren.length == 0
            node.strictChildren = null
          enqueue node
          stack.push(queue)
          queue = new queueFactory()
          if child.value is null
            child.formula.mmExpand(child)
          enqueue child
          continue
        if node.min # if min-node
          node.value = Infinity
          for edge in node.targets or []
            target = edge.target
            if target.value is null
              target.formula.mmExpand(target)
              enqueue target
            target.dep node
            result = edge.result()
            if result < node.value
              node.value = result
        else # if max-node
          v_max = -Infinity   # Greatest value (null if none)
          e_max = null        # Greatest edge (i.e. edge offering greatest value)
          for edge in node.targets or []
            if edge.target.value isnt null and edge.result() is Infinity
              v_max = Infinity
              e_max = edge
              break
            else if edge.target.value is null
              if v_max < Infinity
                v_max = Infinity
                e_max = edge
                edge.target.formula.mmExpand(edge.target)
                enqueue edge.target
                break
            else
              result = edge.result()
              if e_max is null or result < v_max
                v_max = result
                e_max = edge
          if e_max?
            e_max.target.dep node
          node.value = v_max
        # Push dependencies for node, if node.value was changed
        if old_value isnt node.value 
          for dep in node.deps
            enqueue dep # If value was changed, enqueue
    return {
      result:           v0.value is Infinity
    }


  global: (exp_stats) ->
    throw "Not yet implemented."




# Expansion of a node must the following things:
# - Set the `min` property to true or false
# - Add edges to the `targets` property
# - Set the `value` property to Infinity
# - Set the `strictChildren` property to a list of children in other equivalence classes, or null.

class IntermediateExpr extends WCTL.Expr
  constructor: ->

IntermediateExpr::mmExpand          = (node) ->
  node.value = Infinity
  return

# Expansion of boolean formula 'true/false'
WCTL.BoolExpr::mmExpand             = (node) ->
  node.value = Infinity
  node.min = (@value == node.assertion)
  return

# Expansion of atomic formula; a in AP
WCTL.AtomicExpr::mmExpand           = (node) ->
  node.value = Infinity
  node.min = (node.assertion == ((not @negated) == node.state.hasProp(@prop)))
  return

# Expansion of logical connective; and/or
WCTL.OperatorExpr::mmExpand         = (node) ->
  node.value = Infinity
  c1 = getNode(node.state, node.assertion, @expr1)
  c2 = getNode(node.state, node.assertion, @expr2)
  node.targets = [new WeightedEdge(0, c1), new WeightedEdge(0, c2)]
  node.min = (node.assertion == (@operator == WCTL.operator.AND))
  return

# Expansion of until-expression: Q e1 U[_b] e2
WCTL.UntilExpr::mmExpand            = (node) ->
  state = node.state
  node.min = true
  node.value = Infinity
  
  # If not a symbolic node
  if @bound isnt '?'
    sym_node = getNode(state, false, @abstract())
    sign = node.assertion - (not node.assertion)  # Note to self: We are smart!!!
    node.targets = [new TernaryEdge(@bound, sign * Infinity, sign * -Infinity, sym_node)]
    node.strictChildren = [sym_node] # Decide if we want strict MMGs or regular MMGs, try both...
    return
  # Edge to formula e2
  e2 = new TernaryEdge(0, 0, Infinity, getNode(state, false, @expr2))
  if @quant is WCTL.quant.E # Existential quantification
    node.targets = [e2]
    state.next (weight, target) =>
      ni = new Node(null, null, new IntermediateExpr()) # intermediate node for every successor state
      ni.min = false
      ni.targets = [
        new WeightedEdge(0, getNode(state, false, @expr1)),
        new WeightedEdge(weight, getNode(target, false, @))
      ]
      node.targets.push new WeightedEdge(0, ni)
    return
  else if @quant is WCTL.quant.A # Universal quantification
    ni = new Node(null, null, new IntermediateExpr()) 
    ni.min = false
    ni.targets = [new WeightedEdge(0, getNode(state, false, @expr1))] # Formula e1
    # intermediate max-node connected to every successor state
    state.next (weight, target) =>
      ni.targets.push(new WeightedEdge(weight, getNode(target, false, @)))
    node.targets = [e2, new WeightedEdge(0, ni)]
    return
  else
    throw "Unknown quantifier #{@quant}"
  return

# Expansion of next operator
WCTL.NextExpr::mmExpand             = (node) ->
  state = node.state
  
  node.targets = []
  state.next (weight, target) =>
    if weight <= @bound
      node.targets.push new WeightedEdge(0, getNode(target, node.assertion, @expr))
    return
  if node.targets.length is 0
    node.targets = null
  
  node.min = node.assertion == (@quant is WCTL.quant.A)
  node.value = Infinity
  return

# Comparison Operator
WCTL.ComparisonExpr::mmExpand       = (node) ->
  v1 = @expr1.evaluate(node.state)
  v2 = @expr2.evaluate(node.state)
  node.min = (@cmpOp(v1, v2) == node.assertion)
  node.value = Infinity
  return