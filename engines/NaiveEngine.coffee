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

_nb_hyps = 0
# A hyper-edge in the DG
class HyperEdge
  constructor: (@source, @targets) ->
    _nb_hyps++
    @in_queue = true
  stringify: ->
    if @targets.length isnt 0
      tlist = (t.stringify() for t in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"
  
class @NaiveEngine
  constructor: (@formula, @initState) ->
    @nb_confs = 0
  #LiuSmolka-Local
  local: (exp_stats, queue) ->
    _nb_hyps = 0
    state = @initState
    v0 = @getConf(state, @formula)
    @queue = queue = new queue()
    if v0.value is null
      v0.value = false
      v0.formula.naiveExpand(v0, @)
    iterations = 0
    max_queue = 1
    queue_sizes = []
    queue_size_interval = 1
    queue_size_count = 1
    queue_size_i = 0
    while not queue.empty()
      # Keep some stats
      if exp_stats
        queue_size = queue.size()
        if max_queue < queue_size
          max_queue = queue_size
        queue_size_count -= 1
        if queue_size_count is 0
          queue_sizes[queue_size_i++] = queue_size
          if queue_size_i > 100
            queue_size_i = 0
            for i in [0...100] by 5
              queue_sizes[queue_size_i++] = queue_sizes[i]
            queue_size_interval *= 5
          queue_size_count = queue_size_interval
      iterations++
      # Do the actual iteration
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
        for edge in e.source.deps
          queue.push_dep edge
        if e.source is v0
          break
    retval =
      result:           v0.value is true
      'Hyper-edges':    _nb_hyps
      'Configurations': @nb_confs
      'Iterations':     iterations
    if exp_stats
      retval['Queue size'] =
        sparklines:   queue_sizes[0...queue_size_i]
        value:        ", max " + max_queue
        options:
          chartRangeMin:  0
          tooltipFormat:  "{{y}} edges in queue in the {{x}}'th iteration"
    return retval
  
  # Naive global algorithm
  global: (exp_stats) ->
    _nb_hyps = 0
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
    changes = 1
    # Change statistics 
    cstat_table = []
    cstat_interval = 1
    cstat_count = 1
    cstat_i = 0
    iterations = 0
    while changes > 0 and c0.value is false
      changes = 0
      for c in confs
        if c.value
          continue
        for e in c.succ
          val = true
          for s in e.targets
            val = val and s.value
          if val
            changes += 1
            c.value = val
            break
      # Keep some stats
      if exp_stats
        cstat_count -= 1
        if cstat_count is 0
          cstat_table[cstat_i++] = changes
          if cstat_i > 100
            cstat_i = 0
            for i in [0...100] by 5
              cstat_table[cstat_i++] = cstat_table[i]
            cstat_interval *= 5
          cstat_count = cstat_interval
      iterations++
    retval =
      result:           c0.value is true
      'Hyper-edges':    _nb_hyps
      'Configurations': @nb_confs
      'Iterations':     iterations
    if exp_stats
      opts = 
        chartRangeMin:  0
        tooltipFormat:  "iteration with {{value}} changes"
      if cstat_interval is 1
        opts['type'] = 'bar'
      retval['Changes / Iteration'] =
        sparklines:   cstat_table[0...cstat_i]
        options:      opts
    return retval

  getConf: (state, formula) ->
    sH = state.confs ?= {}
    val = sH[formula.id]
    if not val?
      @nb_confs++
      sH[formula.id] = val = new Configuration(state, formula)
    return val

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
WCTL.UntilUpperExpr::naiveExpand       = (conf, ctx) ->
  state = conf.state
  {quant, expr1, expr2, bound} = conf.formula
  if bound < 0
    return
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

WCTL.WeakUntilExpr::naiveExpand = ->
  throw new Error "Weak until with lower bounds not supported by this engine"

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

WCTL.NotExpr::naiveExpand = ->
  throw new Error "Negation operator not supported by this engine"

# Comparison Operator
WCTL.ComparisonExpr::naiveExpand  = (conf, ctx) ->  
  v1 = @expr1.evaluate(conf.state)
  v2 = @expr2.evaluate(conf.state)
  if @cmpOp(v1, v2)
    ctx.queue.push new HyperEdge(conf, [])
  return

