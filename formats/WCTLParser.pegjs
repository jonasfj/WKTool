expr
  = _ expr:boolean _                                  { return expr; }

boolean
  = e1:temporal _ '||' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.OR, e1, e2); }
  / e1:temporal _ '&&' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.AND, e1, e2); }
  / temporal

temporal
  = 'E' _ e1:expr _ 'U' _ b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.E, e1, e2, b); }
  / 'A' _ e1:expr _ 'U' _ b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.A, e1, e2, b); }
  / 'E' _ e1:expr _ 'U' _ e2:expr                     { return new WCTL.UntilExpr(WCTL.quant.E, e1, e2, Infinity); }
  / 'A' _ e1:expr _ 'U' _ e2:expr                     { return new WCTL.UntilExpr(WCTL.quant.A, e1, e2, Infinity); }
  / 'EX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.E, e, b); }
  / 'AX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.A, e, b); }
  / 'EX' _ e:expr                                     { return new WCTL.NextExpr(WCTL.quant.E, e, Infinity); }
  / 'AX' _ e:expr                                     { return new WCTL.NextExpr(WCTL.quant.A, e, Infinity); }
  / trivial

trivial
  = '!' _ p:prop                                      { return new WCTL.AtomicExpr(p, true); }
  / true                                              { return new WCTL.BoolExpr(true); }
  / false                                             { return new WCTL.BoolExpr(false); }
  / e1:aAdd _ op:cmpOp _ e2:aAdd                      
                              { return new WCTL.ComparisonExpr(e1, e2, WCTL.Arithmetic.cmpOp[op]); }
  / '(' _ e:boolean _ ')'                             { return e; }
  / p:prop                                            { return new WCTL.AtomicExpr(p, false); }

true "\"true\""
  = 'True' / 'true' / 'TRUE'

false "\"false\""
  = 'False' / 'false' / 'FALSE'

cmpOp
 = '<' / '<=' / '==' / '>=' / '>' / '!='

aAdd
  = e1:aMult _ op:addOp _ e2:aAdd   
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aMult

addOp
  = '+' / '-'

aMult
  = e1:aNeg _ op:multOp _ e2:aMult
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aNeg

multOp
  = '*' / '/'

aNeg
  = '-' _ e:aPow                                        { return new WCTL.Arithmetic.UnaryMinusExpr(e); }
  / aPow

aPow 
  = e1:aTriv _ '^' _ e2:aTriv
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp['^']); }
  / aTriv 

aTriv
  = p:prop                                            { return new WCTL.Arithmetic.AtomicExpr(p); }
  / c:const                                           { return new WCTL.Arithmetic.ConstantExpr(c); }
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