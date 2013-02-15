
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


class Context
  constructor: ->
    @nullProcess = new NullProcess(@)
    @nextId = 0
    @processes = {}
    @constantProcesses = {}
    @initProcess = null
  defineProcess: (name, P) =>
    @initProcess ?= P
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
  getNullProcess: => @nullProcess
  getConstantProcess: (name) =>
    return @constantProcesses[name] ?= new ConstantProcess(name, @)
  getWKS: =>
    return @initProcess._stableState ?= new WKSStableState(@initProcess)
  parallelWeights: (w1, w2) => w1 + w2

class Process
  constructor: ->
  stringify: -> throw new Error "Must be implemented in subclass"
  succ: -> throw new Error "Must be implemented in subclass"

# Action
class ActionProcess extends Process
  constructor: (@a, @w, @P, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "<#{@a},#{@w}>.#{@P.stringify()}"
  succ: => [{action: @a, weight: @w, target: @P}]


class InputActionProcess extends Process
  constructor: (@a, @w, @P, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "<#{@a},#{@w}>.#{@P.stringify()}"
  succ: => []
  input: (a) =>
    if a?
      if a is @a
        return [@P]
    else
      return [@a]

io_vert = (a) ->
  if a[a.length - 1] is '!'
    return a[0...a.length - 1]
  return a + '!'

# Parallel 
class ParallelProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "(#{@P.stringify()} | #{@Q.stringify()})"
  succ: =>
    sc = []
    Ps = @P.succ()
    Qs = @Q.succ()
    for {action, weight, target} in Ps
      sc.push {action, weight, target: @ctx.getParallelProcess(target, @Q)}
      match = io_vert action
      for q in Qs when q.action is match
        sc.push {
          action,
          weight:   @ctx.parallelWeights(weight, q.weight),
          target:   @ctx.getParallelProcess(target, q.target)
        }
    for {action, weight, target} in Qs
      sc.push {action, weight, target: @ctx.getParallelProcess(@P, target)}
    return sc

# Choice
class ChoiceProcess extends Process
  constructor: (@P, @Q, @ctx) ->
    @id = @ctx.nextId++
  stringify: => "(#{@P.stringify()} + #{@Q.stringify()})"
  succ: =>
    return [@P.succ()..., @Q.succ()...]

# Null Process
class NullProcess extends Process
  constructor: (@ctx) ->
    @id = @ctx.nextId++
  stringify: => 'null'
  succ: => []

class ConstantProcess extends Process
  constructor: (@name, @ctx) ->
    @id = @ctx.nextId++
  stringify: => @name
  succ: => @ctx.getProcesses(@name).succ()

#### WKS Wrapper for WLTS representation of WCCS

class WKSUnstableState
  constructor: (@action, @P) ->
  next: =>
    return [{weight: 0, target: @P._stableState ?= new WKSStableState(@P)}]
  props:  => [@action]


class WKSStableState
  constructor: (@P) ->
  next: =>
    retval = []
    @P._unstableStates ?= {}
    for {action, weight, target} in @P.succ()
      retval.push {
        weight,
        target: @P._unstableStates[action] ?= new WKSUnstableState(a, @P)
      }
    return retval
  props: => ['stable']

#### WCTL for WCCS to WCTL for WKS translation

translateWCTL = (formula) ->
  return translateBool      formula     if formula instanceof WCTL.BoolExpr
  return translateAtomic    formula     if formula instanceof WCTL.AtomicExpr
  return translateOperator  formula     if formula instanceof WCTL.OperatorExpr
  return translateUntil     formula     if formula instanceof WCTL.UntilExpr
  return translateNext      formula     if formula instanceof WCTL.NextExpr
  throw new Error("Can't translate formula " + formula.stringify())

###
Okay, lad os prøve at lave reglerne fra bunden... ie. start med bool, atomic, until
og så tester vi dem på nogle rimeligt komplekse ting og philosofere over om de virker :)



bool:
  true      =>      true
  false     =>      true

atomic:
  'a'       =>      'a' or 'stable'

  (s)-(a,w)-> ==> (s')-w->(a)

     
  Note: man kan ikke gå fra unstable til unstable eller fra stable til stable
  så i untill vil man ikke nå til slut konditionen...

Next:
  EX 'a'    =>      EX EX 'a' or 'stable'



###

translateBool     = (expr) -> expr
translateAtomic   = (expr) ->
  e1 = new WCTL.AtomicExpr('stable')
  e2 = new WCTL.NextExpr(WCTL.quant.E, expr, 0)
  return new WCTL.OperatorExpr(WCTL.Operator.AND, e1, e2)
translateOperator = (expr) ->
  return new WCTL.OperatorExpr(
    expr.operator,
    translateWCTL expr.expr1,
    translateWCTL expr.expr2
  )
translateUntil    = (expr) ->
translateNext     = (expr) ->
  ex = new WCTL.NextExpr(expr.quant)

WCCS.translateWCTL = translateWCTL

