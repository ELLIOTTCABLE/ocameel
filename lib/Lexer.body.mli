type wrapped_token = token * Lexing.position * Lexing.position

(** Signals a lexing error at the provided source location.  *)
exception LexError of (Lexing.position * string)

val token : LexBuffer.t -> token
val loc_token : LexBuffer.t -> wrapped_token
