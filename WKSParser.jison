/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex

%%
\s+                   /* skip whitespace */
"digraph"             return 'Digraph';
"//"[^\r\n]*          /* skip comment */
"{"                   return '{';
"}"                   return '}';
"["                   return '[';
"]"                   return ']';
"label"               return 'Label';
"="                   return '=';
";"                   return ';';
"\""                  return '"';
[0-9]+                return 'Weight';
[a-zA-Z][a-zA-Z0-9]*  return 'Id';
"->"                  return '->';
","                   return ',';
<<EOF>>               return 'EOF';

/lex

/* operator associations and precedence */

%start graph

%% /* language grammar */

graph  : 'Digraph' '{' stmts '}' EOF     {
          var wks = new WKS();
          var data = $3.reverse();
          for(var i = 0; i < data.length; i++){
            var row = data[i];
            if(row.type == 'state'){
              row.index = wks.addState(row.name);
              for(var j = 0; j < row.props.length; j++){
                wks.addProp(row.index, row.props[j]); 
              }
            }
          }
          function getIndex(id){
            for(var i = 0; i < data.length; i++){
              var row = data[i];
              if(row.type == 'state' && row.id == id)
                return row.index;
            }
          }
          for(var i = 0; i < data.length; i++){
            var row = data[i];
            if(row.type == 'transition'){
              var src = getIndex(row.source);
              var dst = getIndex(row.target);
              wks.addTransition(src, row.weight, dst);
            }
          }
          return wks;
       }
       ;
 stmts : stmt stmts               {$2.push($1); $$ = $2;}
       | stmt                     {$$ = [$1];}
       ;
 stmt : id '[' 'Label' '=' '"' id '{' ids '}' '"' ']' ';' {
          $$ = {
            type:   'state',
            id:     $1,
            name:   $6,
            props:  $8.reverse(),
            label:  $6
          };
      }
      | id '->' id '[' 'Label' '=' '"' w '"' ']' ';'  {
          $$ = {
            type:   'transition',
            source: $1,
            target: $3,
            weight: $8
          };
      }
      ;
  ids : id ',' ids                  {$3.push($1); $$ = $3;}
      | id                          {$$ = [$1];}
      |                             {$$ = [];}
      ;
   id : 'Id'                        {$$ = yytext;}
      ;
    w : 'Weight'                    {$$ = Number(yytext); }
      ;