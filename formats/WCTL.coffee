# Class for WCTL formulas.

_nextId = 0

@WCTL = WCTL = {}

# Context is used to cache formulas in dictionaries
class @WCTL.Context
  constructor: ->
    @_atomicNegCache = {}
    @_atomicCache = {}
    @_aatomicCache = {}
    @_aconstantCache = {}
  BoolExpr: (bool) ->
    if bool is true
      return @_boolTrue ?= new WCTL.BoolExpr(true)
    return @_boolFalse ?= new WCTL.BoolExpr(false)
   
  AtomicExpr: (prop, negated = false) ->
    if not negated
      return @_atomicCache[prop] ?= new WCTL.AtomicExpr(prop)
    return @_atomicNegCache[prop] ?= new WCTL.AtomicExpr(prop, true)
  
  OperatorExpr: (operator, expr1, expr2) ->
    if expr1.id < expr2.id
      tmp = expr2
      expr2 = expr1
      expr1 = tmp
    cache = expr1._opCache ?= {}
    return cache[operator + " " + expr2.stringify()] ?= new WCTL.OperatorExpr(operator, expr1, expr2)
  
  UntilUpperExpr: (quant, expr1, expr2, bound) ->
    cache = expr1._untilUpperCache ?= {}
    return cache[quant + "[<#{bound}]" + expr2.stringify()] ?= new WCTL.UntilUpperExpr(quant, expr1, expr2, bound, @)

  WeakUntilExpr: (quant, expr1, expr2, bound) ->
    cache = expr1._weakUntilCache ?= {}
    return cache[quant + "[>#{bound}]" + expr2.stringify()] ?= new WCTL.WeakUntilExpr(quant, expr1, expr2, bound, @)
  
  NextExpr: (quant, expr, bound) ->
    cache = expr._nextCache ?= {}
    return cache[quant + "[#{bound.re}#{bound.bound}]"] ?= new WCTL.NextExpr(quant, expr, bound)

  NotExpr: (expr) ->
    return expr._notCache ?= new WCTL.NotExpr(expr)
  
  ComparisonExpr: (expr1, expr2, cmpOp) ->
    cache = expr1._cmpCache ?= {}
    return cache[cmpOpToString(cmpOp) + expr2.stringify()] ?= new WCTL.ComparisonExpr(expr1, expr2, cmpOp)

  AAtomicExpr: (value) ->
    return @_aatomicCache[value] ?= new WCTL.Arithmetic.AtomicExpr(value)
    
  ABinaryExpr: (expr1, expr2, operator) ->
    cache = expr1._abinCache ?= {}
    return cache[binOpToString(operator) + expr2.stringify()] ?= new WCTL.Arithmetic.BinaryExpr(expr1, expr2, operator)
  
  AConstantExpr: (number) ->
    return @_aconstantCache[number] ?= new WCTL.Arithmetic.ConstantExpr(number)

  AUnaryMinusExpr: (expr) ->
    return expr._unaryCache ?= new WCTL.Arithmetic.UnaryMinusExpr(expr)
    
# Base class for an expression
class WCTL.Expr
  constructor: ->
    @id = _nextId++
    @level = -1
  stringify: -> throw "Must override stringify in subclasses"
  setLevel: (level) -> throw "Must override stringify in subclasses" # Cover-level

class WCTL.BoolExpr extends WCTL.Expr
  constructor: (@value) ->
    super()
  stringify: -> "#{@value}"
  setLevel: (l = 0) ->
    if @level < l
      @level = l

# Atomic expression: 'true' or a label
class WCTL.AtomicExpr extends WCTL.Expr
  constructor: (@prop, @negated = false) ->
    super()
  stringify: -> "#{if @negated then '!' else ''}#{@prop}"
  setLevel: (l = 0) ->
    if @level < l
      @level = l

# Logical operator
WCTL.operator =
  AND:    'AND'
  OR:     'OR'

# Conjunctive or disjunctive expression
class WCTL.OperatorExpr extends WCTL.Expr
  constructor: (@operator, @expr1, @expr2) ->
    super()
  stringify: -> "(#{@expr1.stringify()} #{@operator} #{@expr2.stringify()})"
  setLevel: (l = 0) ->
    if @level < l
      @level = l
      @expr1.setLevel l
      @expr2.setLevel l

# Quantifier
WCTL.quant =
  E:      'E'
  A:      'A'

# NOTE: Type of temporal formula is decided by parser.

# Temporal: Upper-bounded until expression
class WCTL.UntilUpperExpr extends WCTL.Expr
  constructor: (@quant, @expr1, @expr2, @bound, @ctx) ->
    super()
  stringify: -> "(#{@quant} #{@expr1.stringify()} U[<#{@bound}] #{@expr2.stringify()})"
  reduce: (weight) ->
    if weight is 0
      return @
    return @ctx.UntilUpperExpr(@quant, @expr1, @expr2, @bound - weight)
  abstract: -> @ctx.UntilUpperExpr(@quant, @expr1, @expr2, "?")
  setLevel: (l = 0) ->
    if @level < l
      @level = l
      if @bound isnt '?'
        @abstract().setLevel l + 1
      else
        @expr1.setLevel l + 1
        @expr2.setLevel l + 1

# Temporal: Lower-bounded until expression
class WCTL.WeakUntilExpr extends WCTL.Expr
  constructor: (@quant, @expr1, @expr2, @bound, @ctx) ->
    super()
  stringify: -> "(#{@quant} #{@expr1.stringify()} W[>#{@bound}] #{@expr2.stringify()})"
  reduce: (weight) ->
    if weight is 0
      return @
    return @ctx.WeakUntilExpr(@quant, @expr1, @expr2, @bound - weight)
  abstract: -> @ctx.WeakUntilExpr(@quant, @expr1, @expr2, "?") # symbolic until
  setLevel: (l = 0) ->
    if @level < l
      @level = l
      if @bound isnt '?'
        @abstract().setLevel l + 1
      else
        @expr1.setLevel l + 1
        @expr2.setLevel l + 1

# Bounded next expression
class WCTL.NextExpr extends WCTL.Expr
  constructor: (@quant, @expr, {@re, @bound}) ->
    super()
  stringify: -> "(#{@quant}X[#{@re}#{@bound}] #{@expr.stringify()})"
  setLevel: (l = 0) ->
    if @level < l
      @level = l
      @expr.setLevel l

# Not expression
class WCTL.NotExpr extends WCTL.Expr
  constructor: (@expr) ->
    super()
  stringify: -> "!#{@expr.stringify()})"
  setLevel: (l = 0) ->
    if @level < l
      @level = l
      @expr.setLevel l

# Arithmetic expr comparison
class WCTL.ComparisonExpr extends WCTL.Expr
  constructor: (@expr1, @expr2, @cmpOp) ->
    super()
  stringify: -> "(#{@expr1.stringify()} #{cmpOpToString @cmpOp} #{@expr2.stringify()})"
  setLevel: (l = 0) ->
    if @level < l
      @level = l

WCTL.Arithmetic ?= {}

# Comparison operators
WCTL.Arithmetic.cmpOp =
  '<':     (a, b) -> a < b
  '<=':    (a, b) -> a <= b
  '==':    (a, b) -> a == b
  '!=':    (a, b) -> a != b
  '>':     (a, b) -> a > b
  '>=':    (a, b) -> a >= b

cmpOpToString = (op) ->
  for k, v of WCTL.Arithmetic.cmpOp when v is op
    return k

class WCTL.Arithmetic.Expr
  constructor: ->
  stringify: -> throw "Must override stringify in subclasses"
  evaluate: (state) -> throw "Must override stringify in subclasses"

class WCTL.Arithmetic.AtomicExpr extends WCTL.Arithmetic.Expr
  constructor: (@prop) ->
  stringify: -> @prop
  evaluate: (state) -> state.countProp @prop

class WCTL.Arithmetic.ConstantExpr extends WCTL.Arithmetic.Expr
  constructor: (@number) ->
  stringify: -> @number
  evaluate: (state) -> @number

WCTL.Arithmetic.binOp =
  '+':    (a, b) -> a + b
  '-':    (a, b) -> a - b
  '*':    (a, b) -> a * b
  '/':    (a, b) -> a / b
  '^':    (a, b) -> Math.pow a, b

binOpToString = (op) ->
  for k, v of WCTL.Arithmetic.binOp when v is op
    return k

class WCTL.Arithmetic.BinaryExpr extends WCTL.Arithmetic.Expr
  constructor: (@expr1, @expr2, @op) ->
  stringify: -> "(#{@expr1.stringify()} #{binOpToString @op} #{@expr2.stringify()})"
  evaluate: (state) -> @op(@expr1.evaluate(state), @expr2.evaluate(state))

class WCTL.Arithmetic.UnaryMinusExpr extends WCTL.Arithmetic.Expr
  constructor: (@expr) ->
  stringify: -> "- #{@expr.stringify()}"
  evaluate: (state) -> - @expr.evaluate state


