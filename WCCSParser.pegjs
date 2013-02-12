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
  = "<" _ action:[a-z_]+ io:("!")? _ ","_ weight:[0-9]+ _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(action + io, weight, P); }
  / "(" _ P:Choice _ ")"        { return P; }
  / name:[A-Z_]+                { return ctx.getConstantProcess(name); }
  / "0"                         { return ctx.getNullProcess(); }

_ = [' '\n\r\t]*