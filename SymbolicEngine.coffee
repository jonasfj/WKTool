_nId = 0
nextId = -> _nId++

# A vertex/configuration in the SDG
class Configuration
  constructor: (@state, @formula, @name) ->
    @value = null
    @deps  = []
    @id    = nextId()
  stringify: => "[#{@name}, #{@formula.stringify()}]"
  dep: (edge) =>
    @deps.push edge if edge not in @deps

# A hyper-edge in the SDG
class HyperEdge
  constructor: (@source, @targets) ->
  stringify: =>
    if @targets.length isnt 0
      tlist = ("#{weight},#{target.stringify()}" for {weight, target} in @targets).sort()
      "#{@source.stringify()} -> #{tlist.join(', ')}"
    else
      "#{@source.stringify()} -> Ø"

# A cover-edge in the SDG
class CoverEdge
  constructor: (@source, @k, @target) ->
  stringify: => "#{@source.stringify()} -#{@k}-> #{@target.stringify()}"

class @SymbolicEngine
  constructor: (@wks, @formula) ->
    @configurations = {}
    @hyperEdges     = {}
    @coverEdges     = {}
  local: (state) =>
    v0 = @getConf(state, @formula)
    queue = []
    push_deps = (conf) ->
      for edge in conf.deps when edge not in queue
        queue.push edge
    if v0.value is null
      v0.value = Infinity
      queue.push @expand(v0)...
    while queue.length isnt 0
      e = queue.pop()
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
          queue.push @expand(e_bot)...
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
          queue.push @expand(e.target)...
        else if e.target.value <= e.k
          if e.source.value isnt 0
            e.source.value = 0
            push_deps e.source
        else
          e.target.dep e
    return v0.value

  # symbolic global algorithm
  global: (state) =>
    c0 = @getConf(state, @formula)
    confs = [c0]
    fresh = [c0]
    while fresh.length isnt 0
      c = fresh.pop()
      c.succ = @expand(c)
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
            if e.target.value <= e.k
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
      return [@getHyperEdge(conf, [])]
    return []

  # Hyper-edges for atomic label formula
  expandAtomic: (conf) =>
    if conf.formula.negated
      if conf.formula.prop not in @wks.props[conf.state]
        return [@getHyperEdge(conf, [])]
    else if not conf.formula.negated and conf.formula.prop in @wks.props[conf.state]
      return [@getHyperEdge(conf, [])]
    return []

  # Hyper-edges for logical operator
  expandOperator: (conf) =>
    if conf.formula.operator is WCTL.operator.AND
      return [@getHyperEdge(conf, [
        {weight: 0, target: @getConf(conf.state, conf.formula.expr1)},
        {weight: 0, target: @getConf(conf.state, conf.formula.expr2)}
      ])]
    if conf.formula.operator is WCTL.operator.OR
      return [
        @getHyperEdge(conf, [{weight: 0, target: @getConf(conf.state, conf.formula.expr1)}]),
        @getHyperEdge(conf, [{weight: 0, target: @getConf(conf.state, conf.formula.expr2)}])
      ]
    throw "Operator must be either AND or OR"

  # Hyper-edges for bounded until operator
  expandUntil: (conf) =>
    state = conf.state
    {quant, expr1, expr2, bound} = conf.formula
    if bound isnt '?'
      return [@getCoverEdge(
        conf,
        bound,
        @getConf(state, conf.formula.abstract())
      )]
    # If abstract state
    edges = [
      @getHyperEdge(conf, [{weight: 0, target: @getConf(state, expr2)}])
    ]
    if quant is WCTL.quant.E
      for {weight, target} in @wks.next[state]
        edges.push @getHyperEdge(conf, [
            {weight:      0,  target: @getConf(state, expr1)},
            {weight: weight,  target: @getConf(target, conf.formula)}
          ]
        )
    if quant is WCTL.quant.A
      c1 = {weight: 0, target: @getConf(state, expr1)}
      cn = []
      for {weight: w, target: t} in @wks.next[state]
        cn.push {weight: w, target: @getConf(t, conf.formula)}
      edges.push @getHyperEdge(conf, [c1, cn...])
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
        edges.push @getHyperEdge(conf, [{weight: 0, target: @getConf(t, expr)}])
    if quant is WCTL.quant.A
        # Check if all successors have enough weight and if there are any successors
        allNext = (({w,t} for {weight:w, target:t} in @wks.next[state] when w <= bound))
        
        if(allNext.length == @wks.next[state].length and @wks.next[state].length > 0)
          edges.push @getHyperEdge(conf,
              ({weight: 0, target: @getConf(t, expr)} for {weight: w, target: t} in @wks.next[state])
          )
    return edges

