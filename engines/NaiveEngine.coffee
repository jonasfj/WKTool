_nId = 0
nextId = -> _nId++

# A vertex/configuration in the DG
class Configuration
  constructor: (@state, @formula) ->
    @value = null
    @deps  = []
    @id    = nextId()
  stringify: -> "[#{state.name()}, #{@formula.stringify()}]"
  dep: (edge) ->
    for e in @deps
      if e is edge
        return
    @deps.push edge
    return

# A hyper-edge in the DG
class HyperEdge
  constructor: (@source, @targets) ->
    @in_queue = true
  stringify: ->
    if @targets.length isnt 0
      tlist = (t.stringify() for t in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"
  
class @NaiveEngine
  constructor: (@formula, @initState) ->
  #LiuSmolka-Local
  local: (queue = []) ->
    state = @initState
    v0 = @getConf(state, @formula)
    @queue = queue
    if v0.value is null
      v0.value = false
      v0.formula.naiveExpand(v0, @)
    while queue.length isnt 0
      e = queue.pop()
      e.in_queue = false
      isTrue = true
      for target in e.targets
        if(target.value is true)
          continue
        isTrue = false
        if(target.value is false)
          target.dep e
          break
        if(target.value is null)
          target.value = false
          target.dep e
          target.formula.naiveExpand(target, @)
          break
      if isTrue and not e.source.value
        e.source.value = true
        for edge in e.source.deps when not edge.in_queue
          queue.push edge
          edge.in_queue = true
    return v0.value
  
  # Naive global algorithm
  global: ->
    state = @initState
    c0 = @getConf(state, @formula)
    confs = [c0]
    fresh = [c0]
    while fresh.length isnt 0
      c = fresh.pop()
      @queue = []
      c.formula.naiveExpand(c, @)
      c.succ = @queue
      @queue = null
      for e in c.succ
        for s in e.targets
          if not s.explored?
            s.explored = true
            confs.push(s)
            fresh.push(s)
      c.value = false
    changed = true
    while changed
      changed = false
      for c in confs
        if c.value
          continue
        for e in c.succ
          val = true
          for s in e.targets
            val = val and s.value
          if val
            changed = true
            c.value = val
            break
    return c0.value

  getConf: (state, formula) ->
    sH = state.confs ?= {}
    return sH[formula.id] ?= new Configuration(state, formula)

# Hyper-edges for 'true' formula
WCTL.BoolExpr::naiveExpand        = (conf, ctx) ->
  if conf.formula.value
    ctx.queue.push new HyperEdge(conf, [])
  return

# Hyper-edges for atomic label formula
WCTL.AtomicExpr::naiveExpand      = (conf, ctx) ->
  if conf.formula.negated
    if not conf.state.hasProp(conf.formula.prop)
      ctx.queue.push new HyperEdge(conf, [])
  else if not conf.formula.negated and conf.state.hasProp(conf.formula.prop)
    ctx.queue.push new HyperEdge(conf, [])
  return

# Hyper-edges for logical operator
WCTL.OperatorExpr::naiveExpand    = (conf, ctx) ->
  if conf.formula.operator is WCTL.operator.AND
    ctx.queue.push new HyperEdge(conf, [
      ctx.getConf(conf.state, conf.formula.expr1),
      ctx.getConf(conf.state, conf.formula.expr2)
    ])
  else if conf.formula.operator is WCTL.operator.OR
    ctx.queue.push(
      new HyperEdge(conf, [ctx.getConf(conf.state, conf.formula.expr1)]),
      new HyperEdge(conf, [ctx.getConf(conf.state, conf.formula.expr2)])
    )
  else
    throw "Operator must be either AND or OR"
  return
  
# Hyper-edges for bounded until operator
WCTL.UntilExpr::naiveExpand       = (conf, ctx) ->
  state = conf.state
  {quant, expr1, expr2, bound} = conf.formula
  if bound < 0
    return edges
  ctx.queue.push new HyperEdge(conf, [ctx.getConf(state, expr2)])

  if quant is WCTL.quant.E
    state.next (weight, target) ->
      ctx.queue.push new HyperEdge(conf, [
          ctx.getConf(state, expr1),
          ctx.getConf(target, conf.formula.reduce(weight))
        ]
      )
  else if quant is WCTL.quant.A
    branches = []
    state.next (weight, target) ->
      branches.push ctx.getConf(target, conf.formula.reduce(weight))
    if branches.length > 0
      branches.push ctx.getConf(state, expr1)
      ctx.queue.push new HyperEdge(conf, branches)
  else
    throw "Unknown quantifier #{quant}"
  return

# Hyper-edges for bounded next operator
WCTL.NextExpr::naiveExpand        = (conf, ctx) ->
    state = conf.state
    {quant, expr, bound} = conf.formula
    if bound < 0
      return
    if quant is WCTL.quant.E
      state.next (w, t) ->
        if w <= bound
          ctx.queue.push new HyperEdge(conf, [ctx.getConf(t, expr)])
    else if quant is WCTL.quant.A
        branches = []
        state.next (weight, target) ->
          if weight <= bound
            branches.push ctx.getConf(target, expr)
        if branches.length > 0
          ctx.queue.push new HyperEdge(conf, branches)
    else
      throw "Unknown quantifier #{quant}"
    return

# Comparison Operator
WCTL.ComparisonExpr::naiveExpand  = (conf, ctx) ->  
  v1 = @expr1.evaluate(conf.state)
  v2 = @expr2.evaluate(conf.state)
  if @cmpOp(v1, v2)
    ctx.queue.push new HyperEdge(conf, [])
  return

