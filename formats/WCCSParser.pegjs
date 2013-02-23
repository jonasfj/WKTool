{
  var ctx = new WCCS.Context();
}


WCCS
  = _ n:name _ ":=" _ P:Choice _ ";" _ WCCS?
                                { 
                                  ctx.defineProcess(n, P);
                                  ctx.setInitProcess(ctx.getConstantProcess(n));
                                  return ctx;
                                }


Choice
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel
  = P:Prefix _ "|" _ Q:Parallel { return ctx.getParallelProcess(P, Q); }
  / P:Prefix                    { return P; }

Prefix
  = "<" _ a:action io:"!"? _ ","_ w:weight _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(a + io, w, P); }
  / "<" _ a:action io:"!"? _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(a + io, 0, P); }
  / label:prop ":" P:Prefix     { return ctx.getLabeledProcess(label, P); }
  / Restrict

Restrict
  = P:Trivial _ actions:Restrictions
                                { return ctx.getRestrictionProcess(actions, P); }
  / Trivial

Restrictions
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

Actions
  = a:action _ "," _ actions:Actions
                                { actions.push(a); return actions; }
  / a:action                   { return [a]; }

Trivial
  = "(" _ P:Choice _ ")"        { return P; }
  / n:name                      { return ctx.getConstantProcess(n); }
  / "0"                         { return ctx.getNullProcess(); }

name "name"
  = first:[A-Za-z] rest:[A-Za-z0-9_-]* { return first + rest.join(''); }

action "action"
  = first:[A-Za-z] rest:[A-Za-z0-9_-]* { return first + rest.join(''); }

prop "property"
  = first:[A-Za-z] rest:[A-Za-z0-9_-]* { return first + rest.join(''); }

weight "weight"
  = w:[0-9]+                    { return parseInt(w.join('')); }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}
