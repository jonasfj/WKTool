
expr "Expression"
  = _ expr:boolean _                                  { return expr; }

boolean
  = e1:temporal _ '||' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.OR, e1, e2); }
  / e1:temporal _ '&&' _ e2:boolean                   { return new WCTL.OperatorExpr(WCTL.operator.AND, e1, e2); }
  / temporal

temporal
  = 'E' _ e1:expr _ 'U' b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.E, e1, e2, b); }
  / 'A' _ e1:expr _ 'U' b:bound _ e2:expr             { return new WCTL.UntilExpr(WCTL.quant.A, e1, e2, b); }
  / 'EX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.E, e); }
  / 'AX' b:bound _ e:expr                             { return new WCTL.NextExpr(WCTL.quant.A, e); }
  / trivial

trivial
  = '!' _ p:prop                                      { return new WCTL.AtomicExpr(p, true); }
  / 'True'                                            { return new WCTL.BoolExpr(true); }
  / 'False'                                           { return new WCTL.BoolExpr(false); }
  / p:prop                                            { return new WCTL.AtomicExpr(p, false); }
  / '(' _ e:boolean _ ')'                             { return e; }


prop "Property"
  = first:[A-z] rest:[A-z0-9_-]*                      { return first + rest.join(''); }

bound "Weight Bound"
  = '[' _ weight:[0-9]+ _ ']'                         { return parseInt(weight.join('')); }

_ "Whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}