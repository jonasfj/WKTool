# Class for WCCS expressions
@WCCS = {}

class @WCCS.Context
  constructor: ->
    @nullProcess = new NullProcess(@)
    @nextId = 0
    @processes = {}
    @constantProcesses = {}
    @initProcess = null
  resolve: ->
    for name, P of @processes
      P.resolve()
  getExplicitStateNames: -> (name for name, P of @processes)
  getStateByName: (name) ->
    return @processes[name]
  setInitProcess: (P) ->
    @initProcess = P
  initState: => @initProcess
  defineProcess: (name, P) ->
    @processes[name] = P
  getProcess: (name) ->
    return @processes[name]
  getActionProcess: (a, w, P) ->
    P._actionHash ?= {}
    tb = P._actionHash
    hash = "#{a}-#{w}"
    val = tb[hash]
    if not val?
      tb[hash] = val = new ActionProcess(a, w, P, @)
    return val
  getParallelProcess: (P, Q) ->
    if P.id < Q.id
      tmp = P
      P = Q
      Q = tmp
    ph = P._parallelHash ?= {}
    return ph[Q.id] ?= new ParallelProcess(P, Q, @)
  getChoiceProcess: (P, Q) ->
    if P.id < Q.id
      tmp = P
      P = Q
      Q = tmp 
    ch = P._choiceHash ?= {}
    return ch[Q.id] ?= new ChoiceProcess(P, Q, @)
  getLabeledProcess: (prop, P) ->
    lh = P._labelHash ?= {}
    return lh[prop] ?= new LabeledProcess(prop, P, @)
  getRestrictionProcess: (actions, P, actions_filled = null) ->
    rh = P._restrictionHash ?= {}
    return rh[actions.join(",")] ?= new RestrictionProcess(actions, P, @, actions_filled)
  getRenamingProcess: (action_map, prop_map, P, action_map_filled = null, inv_prop_map = null) ->
    rh = P._renameHash ?= {}
    map = (k + "->" + v for k, v of action_map)
    map.push (k + "=>" + v for k, v of prop_map)...
    return rh[map.join(',')] ?= new RenamingProcess(action_map, prop_map, P, @, action_map_filled, inv_prop_map)
  getNullProcess: -> @nullProcess
  getConstantProcess: (name) ->
    return @constantProcesses[name] ?= new ConstantProcess(name, @)
  parallelWeights: (w1, w2) -> Math.max(w1, w2)

# Abstract process class
class Process
  constructor: ->
  stringify: -> throw new Error "Must be implemented in subclass"
  next: -> throw new Error "Must be implemented in subclass"
  # Atomic props
  props: -> throw new Error "Must be implemented in subclass"
  # Check if P has a property
  hasProp: -> throw new Error "Must be implemented in subclass"
  # Count number of occurences of property
  countProp: -> throw new Error "Must be implemented in subclass"
  resolve: -> throw new Error "Must be implemented in subclass"
  name: -> null
  getThisState: -> @

# Labeled process x:P
class LabeledProcess extends Process
  constructor: (@prop, @P, @ctx) ->
    @id = @ctx.nextId++
  stringify: -> "#{@prop}:#{@P.stringify()}"
  next: (cb) -> @P.next(cb)
  props: ->
    props = @P.props()
    props.push @prop
    return props
  hasProp: (p) -> p is @prop or @P.hasProp(p)
  countProp: (p) ->
    c = @P.countProp p
    if p is @prop
      c += 1
    return c
  resolve: ->
    @P.resolve()

# Process prefixed with action <a,w>.P
class ActionProcess extends Process
  constructor: (@a, @w, @P, @ctx) ->
    @id = @ctx.nextId++
  stringify: -> "<#{@a},#{@w}>.#{@P.stringify()}"
  next: (cb) ->
    cb(@w, @P, @a)
  props: -> []
  hasProp: -> false
  countProp: -> return 0
  resolve: ->
    @P.resolve()

is_broadcast = (a) -> a[a.length - 2] is '!' and a[a.length - 1] is '!'

# Invert action wrt. being input or output
io_invert = (a) ->
  if a[a.length - 1] is '!'
    return a[0...a.length - 1]
  return a + '!'

# Parallel 
class ParallelProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: -> "(#{@P.stringify()} | #{@Q.stringify()})"
  next: (cb) ->
    nProc = @ctx.nullProcess
    if not @cached_next?
      @cached_next = []
      Ps = []
      @P.next (w, t, a) =>
        if t is nProc
          @cached_next.push w, @Q, a
        else
          @cached_next.push w, @ctx.getParallelProcess(t, @Q), a
        Ps.push w, t, a
      @Q.next (w, t, a) =>
        if t is nProc
          @cached_next.push(w, @P, a)
        else
          @cached_next.push(w, @ctx.getParallelProcess(t, @P), a)
        m = io_invert a
        for i in [0...Ps.length] by 3
          if Ps[i + 2] is m
            p = Ps[i + 1]
            if t is nProc
              p = p
            else if p is nProc
              p = t
            else
              p = @ctx.getParallelProcess(t, p)
            @cached_next.push(@ctx.parallelWeights(w, Ps[i]), p, 'tau')
    for i in [0...@cached_next.length] by 3
      cb(@cached_next[i], @cached_next[i+1], @cached_next[i+2])
    return
  props: -> [@P.props()..., @Q.props()...]
  hasProp: (p) -> @P.hasProp(p) or @Q.hasProp(p)
  countProp: (p) -> @P.countProp(p) + @Q.countProp(p)
  resolve: ->
    @P.resolve()
    @Q.resolve()

# Restricted process P\\{actions...}
class RestrictionProcess extends Process
  constructor: (@actions, @P, @ctx, @actions_filled = null) ->
    @id = @ctx.nextId++
    if not @actions_filled?
      @actions_filled = []
      for a in @actions
        if a not in @actions_filled
          @actions_filled.push a
          @actions_filled.push a + '!'
  stringify: -> "#{@P.stringify()}\\{#{@actions.join(', ')}}"
  next: (cb) ->
    if not @cached_next?
      @cached_next = []
      @P.next (w, t, a) =>
        if a not in @actions_filled
          t = @ctx.getRestrictionProcess(@actions, t, @actions_filled)
          @cached_next.push(w, t, a)
    for i in [0...@cached_next.length] by 3
      cb(@cached_next[i], @cached_next[i+1], @cached_next[i+2])
    return
  props: -> @P.props()
  hasProp: (p) -> @P.hasProp(p)
  countProp: (p) -> @P.countProp(p)
  resolve: ->
    @P.resolve()

# Choice P+Q
class ChoiceProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: -> "(#{@P.stringify()} + #{@Q.stringify()})"
  next: (cb) ->
    @P.next cb
    @Q.next cb
    return
  props: -> [@P.props()..., @Q.props()...]
  hasProp: (p) -> @P.hasProp(p) or @Q.hasProp(p)
  countProp: (p) -> @P.countProp(p) + @Q.countProp(p)
  resolve: ->
    @P.resolve()
    @Q.resolve()

# Null Process
class NullProcess extends Process
  constructor: (@ctx) ->
    @id = @ctx.nextId++
  stringify: -> '0'
  next: ->
  props: -> []
  hasProp: (p) -> false
  countProp: -> 0
  resolve: ->

# Process Name definition
class ConstantProcess extends Process
  constructor: (@_name, @ctx) ->
    @id = @ctx.nextId++
    @P = null
  stringify: -> @_name
  next: (cb) -> @P.next cb
  props: -> @P.props()
  hasProp: (p) -> @P.hasProp(p)
  countProp: (p) -> @P.countProp(p)
  resolve: ->
    @P = @ctx.getProcess(@_name)
    if not (@P?)
      err = new Error "Process constant \"#{@_name}\" isn't defined"
      err.name = "TypeError"
      err.line  = @line
      err.column = @column
      throw err
  name: -> @_name
  getThisState: -> @P

class RenamingProcess extends Process
  constructor: (@act_map, @prop_map, @P, @ctx, @act_map_filled = null, @inv_prop_map = null) ->
    @id = @ctx.nextId++
    if not @act_map_filled?
      @act_map_filled = {} # Filled out with output actions, ie. postfixed "!"
      for k, v of @act_map
        @act_map_filled[k] = v
        @act_map_filled[k + '!'] = v + '!'
    if not @inv_prop_map?
      @inv_prop_map = {}  # inverse property map
      for k, v of @prop_map
        @inv_prop_map[v] = k
        @inv_prop_map[k] = false
  stringify: ->
    map = (k + " -> " + v for k, v of @act_map)
    map.push (k + " => " + v for k, v of @prop_map)...
    return "(#{@P.stringify()}) [#{map.join(', ')}]"
  next: (cb) ->
    if not @cached_next?
      @cached_next = []
      @P.next (w, t, a) =>
        a = @act_map_filled[a] or a
        t = @ctx.getRenamingProcess(@act_map, @prop_map, t, @act_map_filled, @inv_prop_map)
        @cached_next.push(w, t, a)
    for i in [0...@cached_next.length] by 3
      cb(@cached_next[i], @cached_next[i+1], @cached_next[i+2])
    return
  props: ->
    props = []
    for p in @P.props()
      props.push = @prop_map[p] or p
    return props
  hasProp: (p) ->
    ip = @inv_prop_map[p]
    if ip isnt false
      return @P.hasProp(ip or p)
    return false
  countProp: (p) ->
    ip = @inv_prop_map[p]
    if ip isnt false
      return @P.countProp(ip or p)
    return 0
  resolve: -> @P.resolve()
