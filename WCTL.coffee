# Class for WCTL formulas.

@WCTL = WCTL = {}

# Base class for an expression
class Expr
  constructor: ->
  stringify: -> throw "Must override stringify in subclasses"

class WCTL.BoolExpr extends Expr
  constructor: (@value) ->
  stringify: => "#{@value}"

# Atomic expression: 'true' or a label
class WCTL.AtomicExpr extends Expr
  constructor: (@prop, @negated = false) ->
  stringify: => "#{if @negated then '!' else ''}#{@prop}"

# Logical operator
WCTL.operator =
  AND:    'AND'
  OR:     'OR'

# Conjunctive or disjunctive expression
class WCTL.OperatorExpr extends Expr
  constructor: (@operator, @expr1, @expr2) ->
  stringify: => "(#{@expr1.stringify()}#{@operator}#{@expr2.stringify()})"

# Quantifier
WCTL.quant =
  E:      'E'
  A:      'A'

# Bounded until expression
class WCTL.UntilExpr extends Expr
  constructor: (@quant, @expr1, @expr2, @bound) ->
  stringify: => "(#{@quant}#{@expr1.stringify()}U_#{@bound}#{@expr2.stringify()})"
  reduce: (weight) =>
    if weight is 0
      return @
    return new WCTL.UntilExpr(@quant, @expr1, @expr2, @bound - weight)
  abstract: => new WCTL.UntilExpr(@quant, @expr1, @expr2, "?")

# Bounded next expression
class WCTL.NextExpr extends Expr
  constructor: (@quant, @expr, @bound) ->
  stringify: => "(#{@quant}X_#{@bound}#{@expr.stringify()})"

