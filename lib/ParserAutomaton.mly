(*** Tokens ***)
%token LEFT_PAREN RIGHT_PAREN LVEC APOS TICK COMMA COMMA_AT DQUO SEMI EOF
%token <string> IDENTIFIER
(* %token <bool> BOOL *)
(* %token <int> NUM10 *)
(* %token <string> STREL *)

%start <Parser.AST.t> program

%%
(*** Rules ***)

program:
  | it = list(expression); EOF { it }
  ;

expression:
   | LEFT_PAREN; it = list(identifier); RIGHT_PAREN { Parser.AST.List it }
   ;

identifier:
  | it = IDENTIFIER { Parser.AST.Atom it }

%%
