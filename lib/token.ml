type t =
   | LEFT_PAREN
   | RIGHT_PAREN
   | TICK
   | LVEC
   | DQUO
   | COMMA_AT
   | COMMA
   | APOS

   | IDENTIFIER of string

   | COMMENT_LINE of string
   | LEFT_COMMENT_DELIM
   | RIGHT_COMMENT_DELIM
   | COMMENT_CHUNK of string
   | EOF
[@@deriving show]
