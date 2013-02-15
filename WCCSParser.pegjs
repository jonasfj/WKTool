{
  var ctx = new WCCS.Context();
}

WCCS
  = _ name:[A-Z_]+ _ ":=" _ P:Choice _ ";" WCCS
                                { ctx.defineProcess(name, P); }
  / _

Choice
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel
  = P:Prefix _ "|" _ Q:Parallel { return ctx.getParallelProcess(P, Q); }
  / P:Prefix                    { return P; }

Prefix
  = "<" _ action:[a-z_]+ io:("!")? _ ","_ weight:[0-9]+ _ ">" _ "." _ P:Restrict
                                { return ctx.getActionProcess(action + io, weight, P); }
  / label:[A-z]* ":" P:Restrict { return ctx.getLabeledProcess(label, P); }


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
  = action:[a-z_]+ _ "," _ actions:Actions
                                { actions.push(action); return actions; }
  / action:[a-z_]+              { return [action]; }

Trivial
  = "(" _ P:Choice _ ")"        { return P; }
  / name:[A-Z_]+                { return ctx.getConstantProcess(name); }
  / "0"                         { return ctx.getNullProcess(); }


_ = [' '\n\r\t]*