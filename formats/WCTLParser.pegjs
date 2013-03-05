{
  var ctx = new WCTL.Context();
}

expr
  = _ expr:boolean _                                  { return expr; }

boolean
  = e1:temporal _ '||' _ e2:boolean                   { return ctx.OperatorExpr(WCTL.operator.OR, e1, e2); }
  / e1:temporal _ '&&' _ e2:boolean                   { return ctx.OperatorExpr(WCTL.operator.AND, e1, e2); }
  / temporal

temporal
  = 'E' _ e1:expr _ 'U' _ b:bound _ e2:expr   { return ctx.UntilExpr(WCTL.quant.E, e1, e2, b); }
  / 'A' _ e1:expr _ 'U' _ b:bound _ e2:expr   { return ctx.UntilExpr(WCTL.quant.A, e1, e2, b); }
  / 'E' _ e1:expr _ 'U' _ e2:expr             { return ctx.UntilExpr(WCTL.quant.E, e1, e2, Infinity); }
  / 'A' _ e1:expr _ 'U' _ e2:expr             { return ctx.UntilExpr(WCTL.quant.A, e1, e2, Infinity); }
  / 'EX' b:bound _ e:expr                     { return ctx.NextExpr(WCTL.quant.E, e, b); }
  / 'AX' b:bound _ e:expr                     { return ctx.NextExpr(WCTL.quant.A, e, b); }
  / 'EX' _ e:expr                             { return ctx.NextExpr(WCTL.quant.E, e, Infinity); }
  / 'AX' _ e:expr                             { return ctx.NextExpr(WCTL.quant.A, e, Infinity); }

  / 'EF' b:bound _ e:expr                     { return ctx.UntilExpr(WCTL.quant.E, ctx.BoolExpr(true), e, b); }
  / 'AF' b:bound _ e:expr                     { return ctx.UntilExpr(WCTL.quant.A, ctx.BoolExpr(true), e, b); }
  / 'EF' _ e:expr                             { return ctx.UntilExpr(WCTL.quant.E, ctx.BoolExpr(true), e, Infinity); }
  / 'AF' _ e:expr                             { return ctx.UntilExpr(WCTL.quant.A, ctx.BoolExpr(true), e, Infinity); }
  / trivial

trivial
  = '!' _ p:prop                                      { return ctx.AtomicExpr(p, true); }
  / true                                              { return ctx.BoolExpr(true); }
  / false                                             { return ctx.BoolExpr(false); }
  / e1:aAdd _ op:cmpOp _ e2:aAdd                      
                              { return ctx.ComparisonExpr(e1, e2, WCTL.Arithmetic.cmpOp[op]); }
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

bound "weight bound"
  = '[' _ weight:[0-9]+ _ ']'                         { return parseInt(weight.join('')); }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}