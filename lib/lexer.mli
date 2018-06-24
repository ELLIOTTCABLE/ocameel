type token = Token.t * Lexing.position * Lexing.position
type gen = unit -> token option

(** Signals a lexing error at the provided source location.  *)
exception LexError of (Lexing.position * string)

(** Signals a parsing error at the provided token and its start and end locations. *)
exception ParseError of token


val token_loc : Sedlexing.lexbuf -> token
val token : Sedlexing.lexbuf -> Token.t
val tokens_loc : Sedlexing.lexbuf -> token list
val tokens : Sedlexing.lexbuf -> Token.t list
val gen_loc : Sedlexing.lexbuf -> (unit -> token option)
val gen : Sedlexing.lexbuf -> (unit -> Token.t option)
val pp_exceptions : unit -> unit
