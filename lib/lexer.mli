type buffer
type token = Token.t * Lexing.position * Lexing.position
type mode = Main | BlockComment of int | String
type gen = unit -> token option

(** Signals a lexing error at the provided source location. *)
exception LexError of (Lexing.position * string)

(** Signals a parsing error at the provided token and its start and end locations. *)
exception ParseError of token


val token_loc : buffer -> token
val token : buffer -> Token.t
val tokens_loc : buffer -> token list
val tokens : buffer -> Token.t list
val gen_loc : buffer -> (unit -> token option)
val gen : buffer -> (unit -> Token.t option)
val mode : buffer -> mode
val pp_exceptions : unit -> unit
