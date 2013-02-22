_nId = 0
nextId = -> _nId++

# A vertex/configuration in the DG
class Configuration
  constructor: (@state, @formula) ->
    @value = null
    @deps  = []
    @id    = nextId()
  stringify: -> "[#{state.name()}, #{@formula.stringify()}]"

# A hyper-edge in the DG
class HyperEdge
  constructor: (@source, @targets) ->
  stringify: ->
    if @targets.length isnt 0
      tlist = (t.stringify() for t in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"
  
class @NaiveEngine
  constructor: (@formula, @initState) ->
  #LiuSmolka-Local
  local: ->
    state = @initState
    v0 = @getConf(state, @formula)
    queue = []
    if v0.value is null
      v0.value = false
      succ = v0.formula.naiveExpand(v0, @)
      if succ?
        queue.push succ...
    while queue.length isnt 0
      e = queue.pop()
      isTrue = true
      for target in e.targets
        if(target.value is true)
          continue
        isTrue = false
        if(target.value is false)
          target.deps.push e        if e not in target.deps
          break
        if(target.value is null)
          target.value = false
          target.deps.push e
          succ = target.formula.naiveExpand(target, @)
          if succ?
            queue.push succ...
          break
      if isTrue and not e.source.value
        e.source.value = true
        for edge in e.source.deps when edge not in queue
          queue.push edge
    return v0.value
  
  # Naive global algorithm
  global: ->
    state = @initState
    c0 = @getConf(state, @formula)
    confs = [c0]
    fresh = [c0]
    while fresh.length isnt 0
      c = fresh.pop()
      c.succ = c.formula.naiveExpand(c, @) or []
      for e in c.succ
        for s in e.targets
          if s not in confs
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

  getEdge: (source, targets) ->
    return new HyperEdge(source, targets)

  getConf: (state, formula) ->
    sH = state.confs ?= {}
    return sH[formula.id] ?= new Configuration(state, formula)

# Hyper-edges for 'true' formula
WCTL.BoolExpr::naiveExpand        = (conf, ctx) ->
  if conf.formula.value
    return [ctx.getEdge(conf, [])]
  return null

# Hyper-edges for atomic label formula
WCTL.AtomicExpr::naiveExpand      = (conf, ctx) ->
  if conf.formula.negated
    if not conf.state.hasProp(conf.formula.prop)
      return [ctx.getEdge(conf, [])]
  else if not conf.formula.negated and conf.state.hasProp(conf.formula.prop)
    return [ctx.getEdge(conf, [])]
  return null

# Hyper-edges for logical operator
WCTL.OperatorExpr::naiveExpand    = (conf, ctx) ->
  if conf.formula.operator is WCTL.operator.AND
    return [ctx.getEdge(conf, [
      ctx.getConf(conf.state, conf.formula.expr1),
      ctx.getConf(conf.state, conf.formula.expr2)
    ])]
  if conf.formula.operator is WCTL.operator.OR
    return [
      ctx.getEdge(conf, [ctx.getConf(conf.state, conf.formula.expr1)]),
      ctx.getEdge(conf, [ctx.getConf(conf.state, conf.formula.expr2)])
    ]
  throw "Operator must be either AND or OR"

# Hyper-edges for bounded until operator
WCTL.UntilExpr::naiveExpand       = (conf, ctx) ->
  edges = []
  state = conf.state
  {quant, expr1, expr2, bound} = conf.formula
  if bound < 0
    return edges
  edges.push ctx.getEdge(conf, [ctx.getConf(state, expr2)])

  if quant is WCTL.quant.E
    for {weight, target} in state.next()
      edges.push ctx.getEdge(conf, [
          ctx.getConf(state, expr1),
          ctx.getConf(target, conf.formula.reduce(weight))
        ]
      )
  if quant is WCTL.quant.A
    succ = state.next()
    if succ.length > 0
      c1 = ctx.getConf(state, expr1)
      cn = (ctx.getConf(target, conf.formula.reduce(weight)) for {weight, target} in succ)
      edges.push ctx.getEdge(conf, [c1, cn...])
  return edges

# Hyper-edges for bounded next operator
WCTL.NextExpr::naiveExpand        = (conf, ctx) ->
    edges = []
    state = conf.state
    {quant, expr, bound} = conf.formula
    if bound < 0
      return edges
    if quant is WCTL.quant.E
      for {weight: w, target: t} in state.next() when w <= bound
        edges.push ctx.getEdge(conf, [ctx.getConf(t, expr)])
    if quant is WCTL.quant.A
        allNext = []
        for {weight, target} in state.next() when weight <= bound
          allNext.push
            weight:   0
            target:   ctx.getConf(target, expr)
        if(allNext.length > 0)
          edges.push ctx.getEdge(conf, allNext)
    return edges

# Comparison Operator
WCTL.ComparisonExpr::naiveExpand  = (conf, ctx) ->  
  if conf.formula.cmpOp(conf.formula.expr1.evaluate(conf.state), conf.formula.expr2.evaluate(conf.state))
    return [ctx.getEdge(conf, [])]
  return null

