graph "Weighted Graph"
  = _ 'digraph' _ '{' _ stmts:(statement*)  _ '}' _  
      {
        var wks = new WKS();
        var id2ref = {};
        for(var i = 0; i < stmts.length; i++){
          var stmt = stmts[i];
          if(stmt[0] === 'state'){
            var ref = wks.addState(stmt[2]);
            id2ref[stmt[1]] = ref;
            for(var j = 0; j < stmt[3].length; j++){
              wks.addProp(ref, stmt[3][j]);
            }
          }
        }
        for(var i = 0; i < stmts.length; i++){
          var stmt = stmts[i];
          if(stmt[0] === '->'){
            wks.addTransition(id2ref[stmt[1]], stmt[2], id2ref[stmt[3]]);
          }
        }
        return wks;
      }

statement "Statement"
 = state:id _ '[' _ 'label' _ '=' _ '"' _ name:id _ '{' _ props:ids _ '}' _ '"' _ ']' _ ';' _
                                                      { return ['state', state, name, props]; }
 / source:id _ '->' _ target:id _ '[' _ 'label' _ '=' _ '"' _ w:weight _ '"' _ ']' _ ';' _
                                                      { return ['->', source, w, target]; }

weight "Weight"
 = w:[0-9]+                                           { return parseInt(w.join(''));}

id "Identifier"
  = first:[A-z] rest:[A-z0-9_-]*                      { return first + rest.join(''); }

ids "Identifiers"
  = id:id _ ',' _ ids:ids                             { ids.push(id); return ids; }
  / id:id                                             { return [id]; }

_ "Whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}