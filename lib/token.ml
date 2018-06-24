type t =
   | LEFT_PAREN
   | RIGHT_PAREN
   | TICK
   | SEMI
   | LVEC
   | DQUO
   | COMMA_AT
   | COMMA
   | APOS

   | IDENTIFIER of string

   | COMMENT_LINE of string
   | EOF
[@@deriving show]
