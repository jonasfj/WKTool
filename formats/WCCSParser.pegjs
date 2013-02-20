{
  var ctx = new WCCS.Context();
}

WCCS "Process Definition"
  = _ name:id _ ":=" _ P:Choice _ ";" WCCS
                                { 
                                  ctx.defineProcess(name, P);
                                  ctx.setInitProcess(ctx.getConstantProcess(name));
                                  return ctx;
                                }
  / _

Choice "Expression"
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel "Expression"
  = P:Prefix _ "|" _ Q:Parallel { return ctx.getParallelProcess(P, Q); }
  / P:Prefix                    { return P; }

Prefix "Expression"
  = "<" _ action:id io:"!"? _ ","_ w:weight _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(action + io, w, P); }
  / label:id ":" P:Prefix       { return ctx.getLabeledProcess(label, P); }
  / Restrict

Restrict "Expression"
  = P:Trivial _ actions:Restrictions
                                { return ctx.getRestrictionProcess(actions, P); }
  / Trivial

Restrictions "Restriction"
  = "\\" _ "{" _ actions:Actions _ "}" restrictions:Restrictions
                                {
                                  for(var i = 0; i < actions.length; i++){
                                    if(restrictions.indexOf(actions[i]) < 0)
                                      restrictions.push(actions[i]);
                                  }
                                  return restrictions;
                                }
  / "\\" _ "{" _ actions:Actions _ "}"
                                { return actions; }


Actions "Channels"
  = action:id _ "," _ actions:Actions
                                { actions.push(action); return actions; }
  / action:id                   { return [action]; }

Trivial "Expression"
  = "(" _ P:Choice _ ")"        { return P; }
  / name:id                     { return ctx.getConstantProcess(name); }
  / "0"                         { return ctx.getNullProcess(); }

id  "Identifier"
  = first:[A-z] rest:[A-z0-9_-]*
                                { return first + rest.join(''); }

weight "Weight"
  = w:[0-9]*                    { return parseInt(w.join('')); }

_ "Whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}