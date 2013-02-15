{
  var ctx = new WCCS.Context();
}

WCCS
  = _ name:[A-z_]+ _ ":=" _ P:Choice _ ";" WCCS
                                { 
                                  ctx.defineProcess(name.join(''), P);
                                  ctx.setInitProcess(ctx.getConstantProcess(name.join('')));
                                  return ctx;
                                }
  / _

Choice
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel
  = P:Prefix _ "|" _ Q:Parallel { return ctx.getParallelProcess(P, Q); }
  / P:Prefix                    { return P; }

Prefix
  = "<" _ action:[A-z_]+ io:"!"? _ ","_ weight:[0-9]+ _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(action.join('') + io, parseInt(weight.join('')), P); }
  / label:[A-z]* ":" P:Prefix   { return ctx.getLabeledProcess(label.join(''), P); }
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


Actions
  = action:[A-z_]+ _ "," _ actions:Actions
                                { actions.push(action.join('')); return actions; }
  / action:[A-z_]+              { return [action.join('')]; }

Trivial
  = "(" _ P:Choice _ ")"        { return P; }
  / name:[A-z_]+                { return ctx.getConstantProcess(name.join('')); }
  / "0"                         { return ctx.getNullProcess(); }


_ = [' '\n\r\t]*