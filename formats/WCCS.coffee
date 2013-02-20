
# TODO List for WCCS Implementation
#
# High Priority
#   + WCCS -> WLTS (Synchronization)
#     (Note WLTS is internal to WCCS.coffee, not an exposed interface)
#   + WLTS -> WKS
#   + WKSParser adoption of new WKS interface
#   + Delete old WKS interface (still present in WKS.coffee
#   + Adopt SymbolicEngine to new WKS encoding
#       + Take initial state as input
#       + Use State.next() as list of {weight, target}
#       + Use state.props() as list of properties
#       + Handle blocking WKS states in forall-until and forall-next
#   + Adopt NaiveEngine to new WKS encoding
#       + Use State.next() as list of {weight, target}
#       + Use state.props() as list of properties
#       + Handle blocking WKS states in forall-until and forall-next
#   - Query translation to work on WKS representation of WCCS
#
# Low Priority
#   - Test with console client (WKTool.coffee)
#   - Update UI
#      - Input of WCCS model
#      - Codemirror for WCCS
#   - Perhaps restriction process (force tau)
#
# Andet vi mangler?

# Class for WCCS expressions
@WCCS = {}


class @WCCS.Context
  constructor: ->
    @nullProcess = new NullProcess(@)
    @nextId = 0
    @processes = {}
    @constantProcesses = {}
    @initProcess = null
  getExpliciteStateNames: => (name for name, P of @processes)
  setInitProcess: (P) =>
    @initProcess = P
  initState: => @initProcess
  defineProcess: (name, P) =>
    @processes[name] = P
  getProcess: (name) =>
    return @processes[name]
  getActionProcess: (a, w, P) =>
    P._actionHash ?= {}
    tb = P._actionHash
    hash = "#{a}-#{w}"
    val = tb[hash]
    if not val?
      tb[hash] = val = new ActionProcess(a, w, P, @)
    return val
  getParallelProcess: (P, Q) =>
    if P.id < Q.id
      tmp = P
      P = Q
      Q = tmp
    ph = P._parallelHash ?= {}
    return ph[Q.id] ?= new ParallelProcess(P, Q, @)
  getChoiceProcess: (P, Q) =>
    if P.id < Q.id
      tmp = P
      P = Q
      Q = tmp
    ch = P._choiceHash ?= {}
    return ch[Q.id] ?= new ChoiceProcess(P, Q, @)
  getLabeledProcess: (prop, P) =>
    lh = P._labelHash ?= {}
    return lh[prop] ?= new LabeledProcess(prop, P)
  getRestrictionProcess: (actions, P) =>
    rh = P._restrictionHash ?= {}
    return rh[actions.join(",")] ?= new RestrictionProcess(actions, P)
  getNullProcess: => @nullProcess
  getConstantProcess: (name) =>
    return @constantProcesses[name] ?= new ConstantProcess(name, @)
  getWKS: =>
    return @initProcess._stableState ?= new WKSStableState(@initProcess)
  parallelWeights: (w1, w2) => w1 + w2

# Abstract process class
class Process
  constructor: ->
  stringify: -> throw new Error "Must be implemented in subclass"
  next: -> throw new Error "Must be implemented in subclass"
  # Atomic props
  props: -> throw new Error "Must be implemented in subclass"
  # Check if P has a property
  hasProp: -> throw new Error "Must be implemented in subclass"

# Labeled process x:P
class LabeledProcess extends Process
  constructor: (@prop, @P) ->
  stringify: => "#{@prop}:#{@P.stringify()}"
  next: => @P.next()
  props: => [@prop]
  hasProp: (p) => p is @prop

# Process prefixed with action <a,w>.P
class ActionProcess extends Process
  constructor: (@a, @w, @P, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "<#{@a},#{@w}>.#{@P.stringify()}"
  next: => [{action: @a, weight: @w, target: @P}]
  props: => []
  hasProp: => false

# Invert action wrt. being input or output
io_vert = (a) ->
  if a[a.length - 1] is '!'
    return a[0...a.length - 1]
  return a + '!'

# Parallel 
class ParallelProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "(#{@P.stringify()} | #{@Q.stringify()})"
  next: =>
    sc = []
    Ps = @P.next()
    Qs = @Q.next()
    for {action, weight, target} in Ps
      sc.push {action, weight, target: @ctx.getParallelProcess(target, @Q)}
      match = io_vert action
      for q in Qs when q.action is match
        sc.push
          action:   'tau'
          weight:   @ctx.parallelWeights(weight, q.weight)
          target:   @ctx.getParallelProcess(target, q.target)
    for {action, weight, target} in Qs
      sc.push {action, weight, target: @ctx.getParallelProcess(@P, target)}
    return sc
  props: => [@P.props()..., @Q.props()...]
  hasProp: (p) => @P.hasProp(p) or @Q.hasProp(p)

# Restricted process P\\{actions...}
class RestrictionProcess extends Process
  constructor: (@actions, @P) ->
    @_actions = []
    for a in @actions
      if a not in @_actions
        @_actions.push a
      a = io_vert a
      if a not in @_actions
        @_actions.push a
  stringify: => "#{@P.stringify()}\\{#{@actions.join(', ')}}"
  next: => @P.next().filter ({action}) => action not in @_actions
  props: => @P.props()
  hasProp: (p) => @P.hasProp(p)

# Choice P+Q
class ChoiceProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "(#{@P.stringify()} + #{@Q.stringify()})"
  next: => [@P.next()..., @Q.next()...]
  props: => [@P.props()..., @Q.props()...]
  hasProp: (p) => @P.hasProp(p) or @Q.hasProp(p)

# Null Process
class NullProcess extends Process
  constructor: (@ctx) ->
    @id = @ctx.nextId++
  stringify: => '0'
  next: => []
  props: => []
  hasProp: (p) => false

# Process Name definition
class ConstantProcess extends Process
  constructor: (@name, @ctx) ->
    @id = @ctx.nextId++
  stringify: => @name
  next: => @ctx.getProcess(@name).next()
  props: => @ctx.getProcess(@name).props()
  hasProp: (p) => @ctx.getProcess(@name).hasProp(p)
