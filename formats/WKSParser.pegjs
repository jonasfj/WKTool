graph
  = _ 'digraph' _ '{' _ stmts:(statement*)  _ '}' _  
      {
        var names = [];
        var wks = new WKS();
        var id2ref = {};
        for(var i = 0; i < stmts.length; i++){
          var stmt = stmts[i];
          if(stmt[0] === 'state'){
            if(names.indexOf(stmt[2].name) >= 0){
              var err = new Error("State name \"" + stmt[2].name + "\" is used twice!");
              err.line = stmt[2].line;
              err.column = stmt[2].column;
              err.name = "TypeError";
              throw err;
            }
            names.push(stmt[2].name);
            var ref = wks.addState(stmt[2].name);
            if(id2ref[stmt[1].id] !== undefined){
              var err = new Error("State \"" + stmt[1].id + "\" is defined twice!");
              err.line = stmt[1].line;
              err.column = stmt[1].column;
              err.name = "TypeError";
              throw err;
            }
            id2ref[stmt[1].id] = ref;
            for(var j = 0; j < stmt[3].length; j++){
              wks.addProp(ref, stmt[3][j]);
            }
          }
        }
        for(var i = 0; i < stmts.length; i++){
          var stmt = stmts[i];
          if(stmt[0] === '->'){
            if(id2ref[stmt[1].id] === undefined){
              var err = new Error("State \"" + stmt[1].id + "\" is not defined!");
              err.line = stmt[1].line;
              err.column = stmt[1].column;
              err.name = "TypeError";
              throw err;
            }
            if(id2ref[stmt[3].id] === undefined){
              var err = new Error("State \"" + stmt[3].id + "\" is not defined!");
              err.line = stmt[3].line;
              err.column = stmt[3].column;
              err.name = "TypeError";
              throw err;
            }
            wks.addTransition(id2ref[stmt[1].id], stmt[2], id2ref[stmt[3].id]);
          }
        }
        return wks;
      }

statement
 = state:id _ '[' _ 'label' _ '=' _ '"' _ n:name _ '{' _ p:props _ '}' _ '"' _ ']' _ ';' _
                                                      { return ['state', state, n, p]; }
 / source:id _ '->' _ target:id _ '[' _ 'label' _ '=' _ '"' _ w:weight _ '"' _ ']' _ ';' _
                                                      { return ['->', source, w, target]; }

weight "weight"
 = w:[0-9]+                                           { return parseInt(w.join(''));}

id "identifier"
  = first:[A-Za-z] rest:[A-Za-z0-9_]*                 { return {id: first + rest.join(''), line: line, column: column}; }

name "name"
  = first:[A-Za-z] rest:[A-Za-z0-9_]*                 { return {name: first + rest.join(''), line: line, column: column}; }

props
  = p:prop _ ',' _ ps:props                           { ps.push(p); return ps; }
  / p:prop                                            { return [p]; }

prop "property"
  = first:[A-Za-z] rest:[A-Za-z0-9_]*                 { return first + rest.join(''); }

_ "whitespace"
  = [' '\n\r\t] _               {}
  / '#' [^\n]* '\n' _           {}
  / '#' [^\n]* ![^]             {}
  /                             {}