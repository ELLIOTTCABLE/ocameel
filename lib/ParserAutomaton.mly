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

%start <Parser.AST.t> program

%%
(*** Rules ***)

program:
  | p = list(expression); EOF { p }
  ;

expression:
  | i = IDENTIFIER { Parser.AST.Atom i }

%%
