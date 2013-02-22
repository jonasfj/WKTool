
expr "Expression"
  = _ expr:boolean _                                  { return expr; }

boolean
  = e1:temporal _ '||' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.OR, e1, e2); }
  / e1:temporal _ '&&' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.AND, e1, e2); }
  / temporal

temporal
  = 'E' _ e1:expr _ 'U' b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.E, e1, e2, b); }
  / 'A' _ e1:expr _ 'U' b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.A, e1, e2, b); }
  / 'E' _ e1:expr _ 'U' _ e2:expr                     { return new WCTL.UntilExpr(WCTL.quant.E, e1, e2, Infinity); }
  / 'A' _ e1:expr _ 'U' _ e2:expr                     { return new WCTL.UntilExpr(WCTL.quant.A, e1, e2, Infinity); }
  / 'EX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.E, e, b); }
  / 'AX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.A, e, b); }
  / 'EX' _ e:expr                                     { return new WCTL.NextExpr(WCTL.quant.E, e, Infinity); }
  / 'AX' _ e:expr                                     { return new WCTL.NextExpr(WCTL.quant.A, e, Infinity); }
  / trivial

trivial
  = '!' _ p:prop                                      { return new WCTL.AtomicExpr(p, true); }
  / 'True'                                            { return new WCTL.BoolExpr(true); }
  / 'False'                                           { return new WCTL.BoolExpr(false); }
  / e1:aAdd _ op:cmpOp _ e2:aAdd                      
                              { return new WCTL.ComparisonExpr(e1, e2, WCTL.Arithmetic.cmpOp[op]); }
  / '(' _ e:boolean _ ')'                             { return e; }
  / p:prop                                            { return new WCTL.AtomicExpr(p, false); }

cmpOp "Binary Comparison Operator"
 = '<' / '<=' / '==' / '>=' / '>' / '!='

aAdd "Arithmetic Expression"
  = e1:aMult _ op:addOp _ e2:aAdd   
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aMult

addOp "Binary Operator"
  = '+' / '-'

aMult "Arithmetic Expression"                        
  = e1:aNeg _ op:multOp _ e2:aMult
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp[op]); }
  / aNeg

multOp "Binary Operator"
  = '*' / '/'

aNeg "Arithmetic Expression"
  = '-' _ e:aPow                                        { return new WCTL.Arithmetic.UnaryMinusExpr(e); }
  / aPow

aPow 
  = e1:aTriv _ '^' _ e2:aTriv
                        { return new WCTL.Arithmetic.BinaryExpr(e1, e2, WCTL.Arithmetic.binOp['^']); }
  / aTriv 

aTriv "Arithmetic Expression"
  = p:prop                                            { return new WCTL.Arithmetic.AtomicExpr(p); }
  / c:const                                           { return new WCTL.Arithmetic.ConstantExpr(c); }
  / '(' _ e:aAdd _ ')'                                { return e; }

const "Constant Integer"
  = c:[0-9]+                                          { return parseInt(c.join('')); }

prop "Property"
  = first:[A-z] rest:[A-z0-9_-]*                      { return first + rest.join(''); }

bound "Weight Bound"
  = '[' _ weight:[0-9]+ _ ']'                         { return parseInt(weight.join('')); }

_ "Whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}