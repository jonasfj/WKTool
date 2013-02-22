_nId = 0
nextId = -> _nId++

# A vertex/configuration in the SDG
class Configuration
  constructor: (@state, @formula) ->
    @value = null
    @deps  = []
    @id    = nextId()
  stringify: -> "[#{@state.name()}, #{@formula.stringify()}]"
  dep: (edge) ->
    @deps.push edge if edge not in @deps

# A hyper-edge in the SDG
class HyperEdge
  constructor: (@source, @targets) ->
  stringify: ->
    if @targets.length isnt 0
      tlist = ("#{weight},#{target.stringify()}" for {weight, target} in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"

# A cover-edge in the SDG
class CoverEdge
  constructor: (@source, @k, @target) ->
  stringify: -> "#{@source.stringify()} -#{@k}-> #{@target.stringify()}"

class @SymbolicEngine
  constructor: (@formula, @initState) ->
  local: ->
    state = @initState
    v0 = @getConf(state, @formula)
    queue = []
    push_deps = (conf) ->
      for edge in conf.deps when edge not in queue
        queue.push edge
    if v0.value is null
      v0.value = Infinity
      succ = v0.formula.symbolicExpand(v0, @)
      if succ?
        queue.push succ...
    while queue.length isnt 0
      e = queue.shift()
      if e instanceof HyperEdge
        e_max = null
        e_bot = null
        val   = 0
        for {weight, target} in e.targets
          if target.value is Infinity
            target.dep e
            e_max = e_bot = null
            break
          else if target.value is null
            e_bot = target
          else if e_max is null or e_max < target.value
            e_max = target
          if val < weight + target.value
            val = weight + target.value
        if e_bot?
          e_bot.value = Infinity
          e_bot.dep e
          succ = e_bot.formula.symbolicExpand(e_bot, @)
          if succ?
            queue.push succ...
        else if e_max? or e.targets.length is 0
          if val < e.source.value
            push_deps e.source
            e.source.value = val
          if e.source.value > 0
            e_max.dep e
      if e instanceof CoverEdge
        if e.target.value is null
          e.target.value = Infinity
          e.target.dep e
          succ = e.target.formula.symbolicExpand(e.target, @)
          if succ?
            queue.push succ...
        else if e.target.value < e.k
          if e.source.value isnt 0
            e.source.value = 0
            push_deps e.source
        else
          e.target.dep e
    return v0.value

  # symbolic global algorithm
  global: ->
    state = @initState
    c0 = @getConf(state, @formula)
    confs = [c0]
    fresh = [c0]
    while fresh.length isnt 0
      c = fresh.pop()
      c.succ = c.formula.symbolicExpand(c, @) or []
      for e in c.succ
        if e instanceof HyperEdge
          for {weight, target} in e.targets
            if target not in confs
              confs.push(target)
              fresh.push(target)
        if e instanceof CoverEdge
          if e.target not in confs
            confs.push(e.target)
            fresh.push(e.target)
      c.value = Infinity
    changed = true
    while changed
      changed = false
      for c in confs
        if c.value is 0
          continue
        for e in c.succ
          if e instanceof HyperEdge
            max = 0
            for {weight, target} in e.targets
              if weight + target.value > max
                max = weight + target.value
            if max < c.value
              changed = true
              c.value = max
          if e instanceof CoverEdge
            if e.target.value < e.k
              changed = true
              c.value = 0
    return c0.value

  # Gets a cover-edge
  getCoverEdge: (source, k, target) ->
    return new CoverEdge(source, k, target)
  # Gets a hyper-edge
  getHyperEdge: (source, targets) ->
    return new HyperEdge(source, targets)
  # Gets a configuration
  getConf: (state, formula) ->
    state.confs ?= {}
    val = state.confs[formula.id]
    if not val?
      state.confs[formula.id] = val = new Configuration(state, formula)
    return val

# Hyper-edges for 'true' formula
WCTL.BoolExpr::symbolicExpand       = (conf, ctx) ->
  if conf.formula.value
    return [ctx.getHyperEdge(conf, [])]
  return null

# Hyper-edges for atomic label formula
WCTL.AtomicExpr::symbolicExpand     = (conf, ctx) ->
  if conf.formula.negated
    if not conf.state.hasProp(conf.formula.prop)
      return [ctx.getHyperEdge(conf, [])]
  else if not conf.formula.negated and conf.state.hasProp(conf.formula.prop)
    return [ctx.getHyperEdge(conf, [])]
  return null

# Hyper-edges for logical operator
WCTL.OperatorExpr::symbolicExpand   = (conf, ctx) ->
  if conf.formula.operator is WCTL.operator.AND
    return [ctx.getHyperEdge(conf, [
      {weight: 0, target: ctx.getConf(conf.state, conf.formula.expr1)},
      {weight: 0, target: ctx.getConf(conf.state, conf.formula.expr2)}
    ])]
  if conf.formula.operator is WCTL.operator.OR
    return [
      ctx.getHyperEdge(conf, [{weight: 0, target: ctx.getConf(conf.state, conf.formula.expr1)}]),
      ctx.getHyperEdge(conf, [{weight: 0, target: ctx.getConf(conf.state, conf.formula.expr2)}])
    ]
  throw "Operator must be either AND or OR"

# Hyper-edges for bounded until operator
WCTL.UntilExpr::symbolicExpand      = (conf, ctx) ->
  state = conf.state
  {quant, expr1, expr2, bound} = conf.formula
  if bound isnt '?'
    return [ctx.getCoverEdge(
      conf,
      bound + 1,
      ctx.getConf(state, conf.formula.abstract())
    )]
  # If abstract state
  edges = [
    ctx.getHyperEdge(conf, [{weight: 0, target: ctx.getConf(state, expr2)}])
  ]
  if quant is WCTL.quant.E
    for {weight, target} in state.next()
      edges.push ctx.getHyperEdge(conf, [
          {weight:      0,  target: ctx.getConf(state, expr1)},
          {weight,          target: ctx.getConf(target, conf.formula)}
        ]
      )
  if quant is WCTL.quant.A
    succ = state.next()
    if succ.length > 0
      c1 = {weight: 0, target: ctx.getConf(state, expr1)}
      cn = []
      for {weight, target} in succ
        cn.push {weight, target: ctx.getConf(target, conf.formula)}
      edges.push ctx.getHyperEdge(conf, [c1, cn...])
  return edges

# Hyper-edges for bounded next operator
WCTL.NextExpr::symbolicExpand       = (conf, ctx) ->
  edges = []
  state = conf.state
  if @quant is WCTL.quant.E
    for {weight: w, target: t} in state.next() when w <= @bound
      edges.push ctx.getHyperEdge(conf, [{weight: 0, target: ctx.getConf(t, @expr)}])
  else if @quant is WCTL.quant.A
      # Check if all successors have enough weight and if there are any successors
      allNext = []
      for {weight, target} in state.next() when weight <= @bound
        allNext.push
          weight:     0
          target:     ctx.getConf(target, @expr)
      if(allNext.length > 0)
        edges.push ctx.getHyperEdge(conf, allNext)
  else
    throw "Unknown quantifier #{WCTL.quant.E}"
  return edges

# Comparison Operator
WCTL.ComparisonExpr::symbolicExpand = (conf, ctx) ->
  v1 = @expr1.evaluate(conf.state)
  v2 = @expr2.evaluate(conf.state)
  if @cmpOp(v1, v2)
    return [ctx.getHyperEdge(conf, [])]
  return null

