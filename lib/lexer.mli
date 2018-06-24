type token = Token.t * Lexing.position * Lexing.position

(** Signals a lexing error at the provided source location.  *)
exception LexError of (Lexing.position * string)

(** Signals a parsing error at the provided token and its start and end locations. *)
exception ParseError of token


val token : Sedlexing.lexbuf -> token
val pp_exceptions : unit -> unit
