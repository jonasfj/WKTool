/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex

%%
\s+                   /* skip whitespace */
[0-9]+                return 'Bound';
[a-z]+                return 'Prop'
"!"                   return 'Neg'
"True"                return 'True'
"False"               return 'False'
"||"                  return 'Or'
"&&"                  return 'And'
"EX"                  return 'EX'
"AX"                  return 'AX'
"E"                   return 'E'
"A"                   return 'A'
"U"                   return 'U'
"("                   return '(';
")"                   return ')';
"["                   return '[';
"]"                   return ']';
<<EOF>>               return 'EOF';

/lex

/* operator associations and precedence */

%left 'Neg'
%left 'Or' 'And'
%left 'U' 'EX' 'AX'

%start expressions

%% /* language grammar */

expressions
    : e EOF                       {return $1;}
    ;
  e : 'True'                      {$$ = new WCTL.BoolExpr(true);}
    | 'False'                     {$$ = new WCTL.BoolExpr(false);}
    | '(' e ')'                   {$$ = $2;}
    | 'Neg' p                     {$$ = new WCTL.AtomicExpr($2, true);}
    | p                           {$$ = new WCTL.AtomicExpr($1, false);}
    | e 'And' e                   {$$ = new WCTL.OperatorExpr(WCTL.operator.AND,$1, $3);}
    | e 'Or' e                    {$$ = new WCTL.OperatorExpr(WCTL.operator.OR, $1, $3);}
    | 'E' e 'U' '[' b ']' e       {$$ = new WCTL.UntilExpr(WCTL.quant.E, $2, $7, $5)}
    | 'A' e 'U' '[' b ']' e       {$$ = new WCTL.UntilExpr(WCTL.quant.A, $2, $7, $5)}
	| 'EX' '[' b ']' e       	  {$$ = new WCTL.NextExpr(WCTL.quant.E, $5, $3)}
    | 'AX' '[' b ']' e            {$$ = new WCTL.NextExpr(WCTL.quant.A, $5, $3)}
    ;
  p : 'Prop'                      {$$ = yytext;}
    ;
  b : 'Bound'                     {$$ = Number(yytext);}
    ;


