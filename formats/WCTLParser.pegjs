{
  var ctx = new WCTL.Context();
}

expr
  = _ expr:boolean _                        { return expr; }

boolean
  = e1:negated _ '||' _ e2:boolean          { return ctx.OperatorExpr(WCTL.operator.OR, e1, e2); }
  / e1:negated _ '&&' _ e2:boolean          { return ctx.OperatorExpr(WCTL.operator.AND, e1, e2); }
  / negated

negated
  = '!' _ e1:temporal                       { return ctx.NotExpr(e1); }
  / temporal

temporal
  = 'E' _ e1:expr _ 'U' _ b:ubound _ e2:expr{ return ctx.UntilUpperExpr(WCTL.quant.E, e1, e2, b.bound); }
  / 'A' _ e1:expr _ 'U' _ b:ubound _ e2:expr{ return ctx.UntilUpperExpr(WCTL.quant.A, e1, e2, b.bound); }
  / 'E' _ e1:expr _ 'U' _ e2:expr           { return ctx.UntilUpperExpr(WCTL.quant.E, e1, e2, Infinity); }
  / 'A' _ e1:expr _ 'U' _ e2:expr           { return ctx.UntilUpperExpr(WCTL.quant.A, e1, e2, Infinity); }
  / 'E' _ e1:expr _ 'W' _ b:lbound _ e2:expr{ return ctx.WeakUntilExpr(WCTL.quant.E, e1, e2, b.bound); }
  / 'A' _ e1:expr _ 'W' _ b:lbound _ e2:expr{ return ctx.WeakUntilExpr(WCTL.quant.A, e1, e2, b.bound); }
  / 'E' _ e1:expr _ 'W' _ e2:expr           { return ctx.WeakUntilExpr(WCTL.quant.E, e1, e2, -Infinity); }
  / 'A' _ e1:expr _ 'W' _ e2:expr           { return ctx.WeakUntilExpr(WCTL.quant.A, e1, e2, -Infinity); }
  / 'EX' b:bound _ e:expr                   { return ctx.NextExpr(WCTL.quant.E, e, b); }
  / 'AX' b:bound _ e:expr                   { return ctx.NextExpr(WCTL.quant.A, e, b); }
  / 'EX' _ e:expr                           { return ctx.NextExpr(WCTL.quant.E, e, {re: '<', bound: Infinity}); }
  / 'AX' _ e:expr                           { return ctx.NextExpr(WCTL.quant.A, e, {re: '<', bound: Infinity}); }
  / 'EF' b:ubound _ e:expr                  { return ctx.UntilUpperExpr(WCTL.quant.E, ctx.BoolExpr(true), e, b.bound);}
  / 'AG ' b:ubound _ e:expr                  { return ctx.NotExpr(
                                                ctx.UntilUpperExpr(WCTL.quant.E, ctx.BoolExpr(true), ctx.NotExpr(e), b.bound)
                                              );
                                            }
  / 'AF' b:ubound _ e:expr                  { return ctx.UntilUpperExpr(WCTL.quant.A, ctx.BoolExpr(true), e, b.bound); }
  / 'EG' b:ubound _ e:expr                  { 
                                              return ctx.NotExpr(
                                                ctx.UntilUpperExpr(WCTL.quant.A, ctx.BoolExpr(true), ctx.NotExpr(e), b.bound)
                                              );
                                            }
  / 'EF' _ e:expr                           { return ctx.UntilUpperExpr(WCTL.quant.E, ctx.BoolExpr(true), e, Infinity); }
  / 'AF' _ e:expr                           { return ctx.UntilUpperExpr(WCTL.quant.A, ctx.BoolExpr(true), e, Infinity); }
  / 'EG' _ e:expr                           { 
                                              return ctx.NotExpr(
                                                ctx.UntilUpperExpr(WCTL.quant.A, ctx.BoolExpr(true), ctx.NotExpr(e), Infinity)
                                              );
                                            }
  / 'AG' _ e:expr                           { 
                                              return ctx.NotExpr(
                                                ctx.UntilUpperExpr(WCTL.quant.E, ctx.BoolExpr(true), ctx.NotExpr(e), Infinity)
                                              );
                                            }
  / trivial

trivial
  = '!' _ p:prop                                      { return ctx.AtomicExpr(p, true); }
  / true                                              { return ctx.BoolExpr(true); }
  / false                                             { return ctx.BoolExpr(false); }
  / e1:aAdd _ op:cmpOp _ e2:aAdd                      { return ctx.ComparisonExpr(e1, e2, WCTL.Arithmetic.cmpOp[op]); }
  / '(' _ e:boolean _ ')'                             { return e; }
  / p:prop                                            { return ctx.AtomicExpr(p, false); }

true "\"true\""
  = 'True' / 'true' / 'TRUE'

false "\"false\""
  = 'False' / 'false' / 'FALSE'

cmpOp
 = '<=' / '<' / '==' / '>=' / '>' / '!='

aAdd
  = e1:aMult _ op:addOp _ e2:aAdd   
                        { return ctx.ABinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aMult

addOp
  = '+' / '-'

aMult
  = e1:aNeg _ op:multOp _ e2:aMult
                        { return ctx.ABinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aNeg

multOp
  = '*' / '/'

aNeg
  = '-' _ e:aPow                                        { return ctx.AUnaryMinusExpr(e); }
  / aPow

aPow 
  = e1:aTriv _ '^' _ e2:aTriv
                        { return ctx.ABinaryExpr(e1, e2, WCTL.Arithmetic.binOp['^']); }
  / aTriv 

aTriv
  = p:prop                                            { return ctx.AAtomicExpr(p); }
  / c:const                                           { return ctx.AConstantExpr(c); }
  / '(' _ e:aAdd _ ')'                                { return e; }

const "integer"
  = c:[0-9]+                                          { return parseInt(c.join('')); }

prop "property"
  = first:[A-Za-z] rest:[A-Za-z0-9_]*                 { return first + rest.join(''); }

ubound "upper bound"
  = '[' _ r:urelation _ weight:[0-9]+ _ ']'           { return {re: r.re, bound: parseInt(weight.join('')) - r.offset}; }

lbound "lower bound"
  = '[' _ r:lrelation _ weight:[0-9]+ _ ']'           { return {re: r.re, bound: parseInt(weight.join('')) - r.offset}; }

urelation
  = '<='                                              { return {re: '<', offset: 0}; }
  / '<'                                               { return {re: '<', offset: 1}; }

lrelation
  = '>='                                              { return {re: '>', offset: 1}; }
  / '>'                                               { return {re: '>', offset: 0}; }

bound "weight bound"
  = '[' _ r:relation _ weight:[0-9]+ _ ']'           { return {re: r.re, bound: parseInt(weight.join('')) - r.offset}; }

relation
  = '<='                                              { return {re: '<', offset: 0}; }
  / '<'                                               { return {re: '<', offset: 1}; }
  / '>='                                              { return {re: '>', offset: 1}; }
  / '>'                                               { return {re: '>', offset: 0}; }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}