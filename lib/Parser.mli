(** Signals a parsing error at the provided token and its start and end locations. *)
exception ParseError of (Lexer.token * Lexing.position * Lexing.position)

type ('a, 'b) interface = ('a, 'b) MenhirLib.Convert.traditional
type 'a production = (Lexer.token, 'a) interface

module AST : sig
   (** Our expression-type; the classic S-expression encoding *)
   type sexp = Base.Sexp.t = Atom of string | List of sexp list

   (** The type of an entire program — a series of S-expressions *)
   type t = sexp list
end


(* TODO: DOCME *)
val parse : LexBuffer.t -> 'a production -> 'a

(** Registers a pretty printer for lex and parse exceptions. This results in
    colorful error messages including the source location when errrors occur. *)
val pp_exceptions : unit -> unit


module Utf8 : sig
   val parse_string : ?pos:Lexing.position -> string -> 'a production -> 'a
   val parse_file : file:string -> 'a production -> 'a
   val parse_channel : Pervasives.in_channel -> 'a production -> 'a
end

module Ascii : sig
   val parse_string : ?pos:Lexing.position -> string -> 'a production -> 'a
   val parse_file : file:string -> 'a production -> 'a
   val parse_channel : Pervasives.in_channel -> 'a production -> 'a
end
