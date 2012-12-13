_nId = 0
nextId = -> _nId++

# A vertex/configuration in the DG
class Configuration
  constructor: (@state, @formula, @name) ->
    @value = null
    @deps  = []
    @id    = nextId()
  stringify: => "[#{@name}, #{@formula.stringify()}]"

# A hyper-edge in the DG
class HyperEdge
  constructor: (@source, @targets) ->
  stringify: =>
    if @targets.length isnt 0
      tlist = (t.stringify() for t in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"
  
class @NaiveEngine
  constructor: (@wks, @formula) ->
    @configurations = {}
    @edges          = {}
  #LiuSmolka-Local
  local: (state) =>
    v0 = @getConf(state, @formula)
    queue = []
    if v0.value is null
      v0.value = false
      queue.push @expand(v0)...
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
          queue.push @expand(target)...
          break
      if isTrue
        e.source.value = true
        for edge in e.source.deps when edge not in queue
          queue.push edge
    return v0.value
  
  # Naive global algorithm
  global: (state) =>
    c0 = @getConf(state, @formula)
    confs = [c0]
    fresh = [c0]
    while fresh.length isnt 0
      c = fresh.pop()
      c.succ = @expand(c)
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

  getConf: (state, formula) =>
    if not formula.confs?
      formula.confs = []
    if not formula.confs[state]?
      formula.confs[state] = new Configuration(state, formula, @wks.names[state])
    return formula.confs[state]
    #key = "#{state}_#{formula.stringify()}"
    #if not @configurations[key]?
    #  @configurations[key] = new Configuration(state, formula, @wks.names[state])
    #return @configurations[key]

  expand: (conf) =>
    e = @expandBool(conf)          if conf.formula instanceof WCTL.BoolExpr
    e = @expandAtomic(conf)        if conf.formula instanceof WCTL.AtomicExpr
    e = @expandOperator(conf)      if conf.formula instanceof WCTL.OperatorExpr
    e = @expandUntil(conf)         if conf.formula instanceof WCTL.UntilExpr
    e = @expandNext(conf)          if conf.formula instanceof WCTL.NextExpr
    return e

  # Hyper-edges for 'true' formula
  expandBool: (conf) =>
    if conf.formula.value
      return [@getEdge(conf, [])]
    return []

  # Hyper-edges for atomic label formula
  expandAtomic: (conf) =>
    if conf.formula.negated
      if conf.formula.prop not in @wks.props[conf.state]
        return [@getEdge(conf, [])]
    else if not conf.formula.negated and conf.formula.prop in @wks.props[conf.state]
      return [@getEdge(conf, [])]
    return []

  # Hyper-edges for logical operator
  expandOperator: (conf) =>
    if conf.formula.operator is WCTL.operator.AND
      return [@getEdge(conf, [
        @getConf(conf.state, conf.formula.expr1),
        @getConf(conf.state, conf.formula.expr2)
      ])]
    if conf.formula.operator is WCTL.operator.OR
      return [
        @getEdge(conf, [@getConf(conf.state, conf.formula.expr1)]),
        @getEdge(conf, [@getConf(conf.state, conf.formula.expr2)])
      ]
    throw "Operator must be either AND or OR"

  # Hyper-edges for bounded until operator
  expandUntil: (conf) =>
    edges = []
    state = conf.state
    {quant, expr1, expr2, bound} = conf.formula
    if bound < 0
      return edges
    edges.push @getEdge(conf, [@getConf(state, expr2)])

    if quant is WCTL.quant.E
      for {weight, target} in @wks.next[state]
        edges.push @getEdge(conf, [
            @getConf(state, expr1),
            @getConf(target, conf.formula.reduce(weight))
          ]
        )
    if quant is WCTL.quant.A
      c1 = @getConf(state, expr1)
      cn = (@getConf(t, conf.formula.reduce(w)) for {weight: w, target: t} in @wks.next[state])
      edges.push @getEdge(conf, [c1, cn...])
    return edges

  # Hyper-edges for bounded next operator
  expandNext: (conf) =>
    edges = []
    state = conf.state
    {quant, expr, bound} = conf.formula
    if bound < 0
      return edges
    if quant is WCTL.quant.E
      for {weight: w, target: t} in @wks.next[state] when w <= bound
        edges.push @getEdge(conf, [@getConf(t, expr)])
    if quant is WCTL.quant.A
        # Check if all successors have enough weight and if there are any successors
        allNext = (({w,t} for {weight:w, target:t} in @wks.next[state] when w <= bound))
        
        if(allNext.length == @wks.next[state].length and @wks.next[state].length > 0)
          edges.push @getEdge(conf,
              (@getConf(t, expr) for {weight: w, target: t} in @wks.next[state])
          )
    return edges

