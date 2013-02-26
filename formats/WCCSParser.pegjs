{
  var ctx = new WCCS.Context();
}

WCCS
  = _ n:name _ ":=" _ P:Choice _ ";" _ WCCS?
                                { 
                                  ctx.defineProcess(n.name, P);
                                  ctx.setInitProcess(ctx.getConstantProcess(n));
                                  return ctx;
                                }


Choice
  = P:Parallel _ "+" _ Q:Choice { return ctx.getChoiceProcess(P, Q); }
  / P:Parallel                  { return P; }

Parallel
  = P:Prefix Ps:(_ "|" _ Q:Prefix { return Q; })*
                                {
                                  Ps.unshift(P);
                                  while(Ps.length > 1){
                                    var p = Ps.shift();
                                    var q = Ps.shift();
                                    Ps.push(ctx.getParallelProcess(p, q));
                                  }
                                  return Ps[0];
                                }

Prefix
  = "<" _ a:action io:"!"? _ ","_ w:weight _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(a + io, w, P); }
  / "<" _ a:action io:"!"? _ ">" _ "." _ P:Prefix
                                { return ctx.getActionProcess(a + io, 0, P); }
  / label:prop ":" P:Prefix     { return ctx.getLabeledProcess(label, P); }
  / Postfix


Postfix
  = P:Trivial modifiers:(Modifier)*
                                {
                                  for(var i = 0; i < modifiers.length; i++){
                                    var m = modifiers[i];
                                    if(m.type === 'restrict')
                                      P = ctx.getRestrictionProcess(m.actions, P);
                                    else if(m.type === 'rename')
                                      P = ctx.getRenamingProcess(m.maps.action, m.maps.prop, P);
                                    else
                                      throw new Error("Internal parser error!");
                                  }
                                  return P;
                                }
  / Trivial

Modifier
  = _ '\\' _ '{' _ acts:Actions _ '}'
                                { return {type: 'restrict', actions: acts}; }
  / _ '[' _ maps:Maps _ ']'     { return {type: 'rename', maps: maps}; }

Actions
  = a:action acts:(_ "," _ action)*
                                { 
                                  var actions = [a];
                                  for(var i = 0; i < acts.length; i++)
                                    actions.push(acts[i][3]);
                                  return actions;
                                }
  /                             { return []; }

Maps
  = m:Map maps:(_ ',' _ Map)*   {
                                  var retval = {action: {}, prop: {}};
                                  retval[m.type][m.from] = m.to;
                                  for(var i = 0; i < maps.length; i++){
                                    m = maps[i][3];
                                    retval[m.type][m.from] = m.to;
                                  }
                                  return retval;
                                }
  /                             { return {action: {}, prop: {}}; }

Map
  = from:action _ '->' _  to:action    { return {type: 'action', from: from, to: to}; }
  / from:prop _ '=>' _  to:prop        { return {type: 'prop', from: from, to: to}; }



Trivial
  = "(" _ P:Choice _ ")"        { return P; }
  / "0"                         { return ctx.getNullProcess(); }
  / n:name                      { 
                                  var P = ctx.getConstantProcess(n.name);
                                  if(P.line === undefined){
                                    P.line = n.line;
                                    P.column = n.column;
                                  }
                                  return P;
                                }

name "name"
  = first:[A-Za-z] rest:[A-Za-z0-9_]* { return {name: first + rest.join(''), line: line, column: column}; }

action "action"
  = first:[A-Za-z] rest:[A-Za-z0-9_]* { return first + rest.join(''); }

prop "property"
  = first:[A-Za-z] rest:[A-Za-z0-9_]* { return first + rest.join(''); }

weight "weight"
  = w:[0-9]+                    { return parseInt(w.join('')); }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}
