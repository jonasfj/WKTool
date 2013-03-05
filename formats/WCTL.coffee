# Class for WCTL formulas.

_nextId = 0

@WCTL = WCTL = {}

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
  
  UntilExpr: (quant, expr1, expr2, bound) ->
    cache = expr1._untilCache ?= {}
    return cache[quant + "[#{bound}]" + expr2.stringify()] ?= new WCTL.UntilExpr(quant, expr1, expr2, bound, @)
  
  NextExpr: (quant, expr, bound) ->
    cache = expr._nextCache ?= {}
    return cache[quant + "[#{bound}]"] ?= new WCTL.NextExpr(quant, expr, bound)
  
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
class Expr
  constructor: ->
  stringify: -> throw "Must override stringify in subclasses"

class WCTL.BoolExpr extends Expr
  constructor: (@value) ->
    @id = _nextId++
  stringify: -> "#{@value}"

# Atomic expression: 'true' or a label
class WCTL.AtomicExpr extends Expr
  constructor: (@prop, @negated = false) ->
    @id = _nextId++
  stringify: -> "#{if @negated then '!' else ''}#{@prop}"

# Logical operator
WCTL.operator =
  AND:    'AND'
  OR:     'OR'

# Conjunctive or disjunctive expression
class WCTL.OperatorExpr extends Expr
  constructor: (@operator, @expr1, @expr2) ->
    @id = _nextId++
  stringify: -> "(#{@expr1.stringify()}#{@operator}#{@expr2.stringify()})"

# Quantifier
WCTL.quant =
  E:      'E'
  A:      'A'

# Bounded until expression
class WCTL.UntilExpr extends Expr
  constructor: (@quant, @expr1, @expr2, @bound, @ctx) ->
    @id = _nextId++
  stringify: -> "(#{@quant}#{@expr1.stringify()}U_#{@bound}#{@expr2.stringify()})"
  reduce: (weight) ->
    if weight is 0
      return @
    return @ctx.UntilExpr(@quant, @expr1, @expr2, @bound - weight)
  abstract: ->
    return @ctx.UntilExpr(@quant, @expr1, @expr2, "?")

# Bounded next expression
class WCTL.NextExpr extends Expr
  constructor: (@quant, @expr, @bound) ->
    @id = _nextId++
  stringify: -> "(#{@quant}X_#{@bound}#{@expr.stringify()})"

# Arithmetic expr comparison
class WCTL.ComparisonExpr extends Expr
  constructor: (@expr1, @expr2, @cmpOp) ->
    @id = _nextId++
  stringify: -> "(#{@expr1.stringify()} #{cmpOpToString @cmpOp} #{@expr2.stringify()})"

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


