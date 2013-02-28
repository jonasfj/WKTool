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
    for e in @deps
      if e is edge
        return
    @deps.push edge

# A hyper-edge in the SDG
_nb_hyps = 0
class HyperEdge
  constructor: (@source, @targets) ->
    _nb_hyps++
    @in_queue = true
  stringify: ->
    if @targets.length isnt 0
      tlist = []
      for i in [0...@targets.length] by 2
        weight = @targets[i]
        target = @targets[i+1]
        tlist.push "#{weight},#{target.stringify()}"
      "#{@source.stringify()} -> #{tlist.sort().join(', ')}"
    else
      "#{@source.stringify()} -> Ø"


_nb_covers = 0
# A cover-edge in the SDG
class CoverEdge
  constructor: (@source, @k, @target) ->
    _nb_covers++
  stringify: -> "#{@source.stringify()} -#{@k}-> #{@target.stringify()}"

class @SymbolicEngine
  constructor: (@formula, @initState) ->
    @nb_confs = 0
  local: (queue) ->
    _nb_hyps = _nb_covers = 0
    state = @initState
    v0 = @getConf(state, @formula)
    @queue = queue
    if v0.value is null
      v0.value = Infinity
      v0.formula.symbolicExpand(v0, @)
    iterations = 0
    while not queue.empty()
      iterations++
      e = queue.pop()
      e.in_queue = false
      if e instanceof HyperEdge
        e_max = null
        e_bot = null
        val   = 0
        for i in [0...e.targets.length] by 2
          weight = e.targets[i]
          target = e.targets[i+1]
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
          e_bot.formula.symbolicExpand(e_bot, @)
        else if e_max? or e.targets.length is 0
          if val < e.source.value
            for edge in e.source.deps
              queue.push_dep edge
            e.source.value = val
          if e.source.value > 0
            e_max.dep e
      if e instanceof CoverEdge
        if e.target.value is null
          e.target.value = Infinity
          e.target.dep e
          e.target.formula.symbolicExpand(e.target, @)
        else if e.target.value < e.k
          if e.source.value isnt 0
            e.source.value = 0
            for edge in e.source.deps
              queue.push_dep edge
        else
          e.target.dep e
    return {
      result:           v0.value is 0
      'Cover-edges':    _nb_covers
      'Hyper-edges':    _nb_hyps
      'Configurations': @nb_confs
      'Iterations':     iterations
    }

  # symbolic global algorithm
  global: ->
    _nb_hyps = _nb_covers = 0
    @global_init()
    return @global_propagate()
    
  global_init: ->
    state = @initState
    @g_c0 = @getConf(state, @formula)
    @g_confs = [@g_c0]
    @g_fresh = [@g_c0]
    while @g_fresh.length isnt 0
      c = @g_fresh.pop()
      @queue = []
      c.formula.symbolicExpand(c, @)
      c.succ = @queue
      @queue = null
      for e in c.succ
        if e instanceof HyperEdge
          for i in [0...e.targets.length] by 2
            weight = e.targets[i]
            target = e.targets[i+1]
            if not target.explored?
              target.explored = true
              @g_confs.push(target)
              @g_fresh.push(target)
        if e instanceof CoverEdge
          if not e.target.explored?
            e.target.explored = true
            @g_confs.push(e.target)
            @g_fresh.push(e.target)
      c.value = Infinity
    return

  global_propagate: ->
    changed = true
    iterations = 0
    while changed
      iterations++
      changed = false
      for c in @g_confs
        if c.value is 0
          continue
        for e in c.succ
          if e instanceof HyperEdge
            max = 0
            for i in [0...e.targets.length] by 2
              weight = e.targets[i]
              target = e.targets[i+1]
              if weight + target.value > max
                max = weight + target.value
            if max < c.value
              changed = true
              c.value = max
          if e instanceof CoverEdge
            if e.target.value < e.k
              changed = true
              c.value = 0
    return {
      result:           @g_c0.value is 0
      'Cover-edges':    _nb_covers
      'Hyper-edges':    _nb_hyps
      'Configurations': @nb_confs
      'Iterations':     iterations
    }

  # Gets a configuration
  getConf: (state, formula) ->
    state.confs ?= {}
    val = state.confs[formula.id]
    if not val?
      @nb_confs++
      state.confs[formula.id] = val = new Configuration(state, formula)
    return val

# Hyper-edges for 'true' formula
WCTL.BoolExpr::symbolicExpand       = (conf, ctx) ->
  if conf.formula.value
    ctx.queue.push new HyperEdge(conf, [])
  return

# Hyper-edges for atomic label formula
WCTL.AtomicExpr::symbolicExpand     = (conf, ctx) ->
  if conf.formula.negated
    if not conf.state.hasProp(conf.formula.prop)
      ctx.queue.push new HyperEdge(conf, [])
  else if not conf.formula.negated and conf.state.hasProp(conf.formula.prop)
    ctx.queue.push new HyperEdge(conf, [])
  return

# Hyper-edges for logical operator
WCTL.OperatorExpr::symbolicExpand   = (conf, ctx) ->
  if conf.formula.operator is WCTL.operator.AND
    ctx.queue.push new HyperEdge(conf, [
      0, ctx.getConf(conf.state, conf.formula.expr1),
      0, ctx.getConf(conf.state, conf.formula.expr2)
    ])
  else if conf.formula.operator is WCTL.operator.OR
    ctx.queue.push(
      new HyperEdge(conf, [0, ctx.getConf(conf.state, conf.formula.expr1)]),
      new HyperEdge(conf, [0, ctx.getConf(conf.state, conf.formula.expr2)])
    )
  else
    throw "Operator must be either AND or OR"
  return

# Hyper-edges for bounded until operator
WCTL.UntilExpr::symbolicExpand      = (conf, ctx) ->
  state = conf.state
  {quant, expr1, expr2, bound} = conf.formula
  if bound isnt '?'
    ctx.queue.push new CoverEdge(
      conf,
      bound + 1,
      ctx.getConf(state, conf.formula.abstract())
    )
    return
  ctx.queue.push new HyperEdge(conf, [0, ctx.getConf(state, expr2)])
  if quant is WCTL.quant.E
    state.next (weight, target) ->
      ctx.queue.push new HyperEdge(conf, [
               0,  ctx.getConf(state, expr1),
          weight,  ctx.getConf(target, conf.formula)
        ]
      )
  else if quant is WCTL.quant.A
    branches = []
    state.next (weight, target) ->
      branches.push weight, ctx.getConf(target, conf.formula)
    if branches.length > 0
      branches.push(0, ctx.getConf(state, expr1))
      ctx.queue.push new HyperEdge(conf, branches)
  else
    throw "Unknown quantifier #{quant}"
  return

# Hyper-edges for bounded next operator
WCTL.NextExpr::symbolicExpand       = (conf, ctx) ->
  state = conf.state
  if @quant is WCTL.quant.E
    state.next (weight, target) =>
      if weight <= @bound
        ctx.queue.push new HyperEdge(conf, [0, ctx.getConf(target, @expr)])
  else if @quant is WCTL.quant.A
    branches = []
    state.next (weight, target) =>
      if weight <= @bound
        branches.push 0, ctx.getConf(target, @expr)
    if branches.length > 0
      ctx.queue.push new HyperEdge(conf, branches)
  else
    throw "Unknown quantifier #{WCTL.quant.E}"
  return

# Comparison Operator
WCTL.ComparisonExpr::symbolicExpand = (conf, ctx) ->
  v1 = @expr1.evaluate(conf.state)
  v2 = @expr2.evaluate(conf.state)
  if @cmpOp(v1, v2)
    ctx.queue.push new HyperEdge(conf, [])
  return

