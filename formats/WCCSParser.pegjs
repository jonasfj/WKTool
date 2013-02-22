{
  var ctx = new WCCS.Context();
}


WCCS
  = _ name:id _ ":=" _ P:Choice _ ";" _ WCCS?
                                { 
                                  ctx.defineProcess(name, P);
                                  ctx.setInitProcess(ctx.getConstantProcess(name));
                                  return ctx;
                                }


Choice "a process"
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel "a process"
  = P:Prefix _ "|" _ Q:Parallel { return ctx.getParallelProcess(P, Q); }
  / P:Prefix                    { return P; }

Prefix "a process"
  = "<" _ action:id io:"!"? _ ","_ w:weight _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(action + io, w, P); }
  / "<" _ action:id io:"!"? _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(action + io, 0, P); }
  / label:id ":" P:Prefix       { return ctx.getLabeledProcess(label, P); }
  / Restrict

Restrict "a process"
  = P:Trivial _ actions:Restrictions
                                { return ctx.getRestrictionProcess(actions, P); }
  / Trivial

Restrictions "a restriction"
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


/* TODO: Finish renaming
  / P:Trivial _ mapping:Mapping
                                { return ctx.getRenamingProcess(mapping, P); }

Mapping "a mapping"
  = "[" _ actions:Actions _ "]" restrictions:Restrictions
                                {
                                  for(var i = 0; i < actions.length; i++){
                                    if(restrictions.indexOf(actions[i]) < 0)
                                      restrictions.push(actions[i]);
                                  }
                                  return restrictions;
                                }
  / "\\" _ "{" _ actions:Actions _ "}"
                                { return actions; }
*/

Actions "channels"
  = action:id _ "," _ actions:Actions
                                { actions.push(action); return actions; }
  / action:id                   { return [action]; }

Trivial "an expression"
  = "(" _ P:Choice _ ")"        { return P; }
  / name:id                     { return ctx.getConstantProcess(name); }
  / "0"                         { return ctx.getNullProcess(); }

id  "identifier"
  = first:[A-z] rest:[A-z0-9_-]*
                                { return first + rest.join(''); }

weight "a weight"
  = w:[0-9]*                    { return parseInt(w.join('')); }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}
