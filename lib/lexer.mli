type wrapped_token = Token.t * Lexing.position * Lexing.position

(** Signals a lexing error at the provided source location.  *)
exception LexError of (Lexing.position * string)

val token : Sedlexing.lexbuf -> Token.t
val pp_exceptions : unit -> unit
