(*** OCaml preamble ***)
%{
(* open Core *)
%}

(*** Tokens ***)
%token LPAR RPAR LVEC APOS TICK COMMA COMMA_AT DQUO SEMI EOF
%token <string> IDENTIFIER
%token <bool> BOOL
(* %token <int> NUM10 *)
(* %token <string> STREL *)

%start <unit> ast_eof

%%
(*** Rules ***)

ast_eof:
  | ast; EOF { () }
  ;

ast:
  | list(nested) { () }

nested:
  | LPAR; ast; RPAR { () }
  ;

%%
