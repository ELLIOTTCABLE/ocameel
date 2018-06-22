type t =
   | TICK
   | SEMI
   | RIGHT_PAREN
   | LVEC
   | LEFT_PAREN
   | IDENTIFIER of (string)
   | EOF
   | DQUO
   | COMMA_AT
   | COMMA
   | APOS
[@@deriving show]
