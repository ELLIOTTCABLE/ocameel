type program =
   expr list

and expr =
   | Varible of string
   | Literal of literal
   | Assignment of string * expr
[@@deriving show, eq, ord]

and literal =
   (* ### Self-evaluating *)
   | Boolean of bool
   | Numeric of numeric
   (* | Char of char *)
   | String of string
   (* | Symbol of symbol *)
[@@deriving show, eq, ord]

and numeric =
    | Decimal of string
[@@deriving show, eq, ord]

type t = program
[@@deriving show, eq, ord]
