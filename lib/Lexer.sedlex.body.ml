type wrapped_token = token * Lexing.position * Lexing.position

(* Mostly cribbed from Steffen Smolka's 2017 ocaml-parsing boilerplate:
      <https://github.com/smolkaj/ocaml-parsing> *)

(* use custom lexbuffer to keep track of source location *)
module Sedlexing = LexBuffer
open LexBuffer

(** Signals a lexing error at the provided source location.  *)
exception LexError of (Lexing.position * string)

(** Signals a parsing error at the provided token and its start and end locations. *)
exception ParseError of (token * Lexing.position * Lexing.position)

let error_of_exn = let open Location in function
   | LexError (pos, msg) ->
     let loc = { loc_start = pos; loc_end = pos; loc_ghost = false} in
     Some { loc; msg; sub=[]; if_highlight=""; }
   | _ -> None

(** Register exceptions for pretty printing *)
let pp_exceptions () =
   (* XXX: Jane Street Core intentionally blocks `Printexc`, without a clear explanation as to why.
    *      Should I not be using it?
    *      (See: <https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/Printexc/> *)
   Caml.Printexc.register_printer (fun exn -> Core.Option.try_with (fun () ->
         Location.report_exception Format.str_formatter exn;
         Format.flush_str_formatter ())) ;
   Location.register_error_of_exn error_of_exn


let failwith buf s = raise (LexError (buf.pos, s))

let illegal buf c =
   Char.escaped c
   |> Printf.sprintf "unexpected character in expression: '%s'"
   |> failwith buf

(** Regular expressions *)
let newline = [%sedlex.regexp? '\r' | '\n' | "\r\n" ]

(* TODO: I *could* crib JavaScript's definition of 'whitespace', expanding on Unicode category 'Zs'?
 *          <http://www.ecma-international.org/ecma-262/6.0/#table-32> *)
let whitespace = [%sedlex.regexp? ' ' | newline ]

(* FIXME: I'd really like to make this more multilingual, but I have no idea which Unicode
 *        categories or traits to use ... *)
let digit = [%sedlex.regexp? '0'..'9']
let letter = [%sedlex.regexp? 'A'..'Z' | 'a'..'z']

let special_initial = [%sedlex.regexp?
   '!' | '$' | '%' | '&' | '*' | '/' | ':' | '<' | '=' | '>' | '?' | '^' | '_' | '~' ]
let initial = [%sedlex.regexp? letter | special_initial ]

let special_subsequent = [%sedlex.regexp? '+' | '-' | '.' | '@' ]
let subsequent = [%sedlex.regexp? initial | digit | special_subsequent ]

let peculiar_identifier = [%sedlex.regexp? '+' | '-' | "..." ]
let identifier = [%sedlex.regexp? initial, Star subsequent | peculiar_identifier ]


(** Swallow whitespace and comments. *)
let rec swallow_atmosphere buf =
   match%sedlex buf with
   | Plus whitespace -> swallow_atmosphere buf
   | ";" -> swallow_comment buf
   | _ -> ()

and swallow_comment buf =
   match%sedlex buf with
   | newline -> swallow_atmosphere buf
   | any -> swallow_comment buf
   | _ -> assert false

(** Return the next token. *)
let rec token buf =
   swallow_atmosphere buf;
   match%sedlex buf with
   | eof -> EOF

   | identifier -> IDENTIFIER (LexBuffer.Utf8.lexeme buf)

   (* parenths *)
   | '(' -> LEFT_PAREN
   | ')' -> RIGHT_PAREN

   (* YOUR TOKENS HERE... *)
   | _ -> illegal buf (Char.chr (next buf))

(* wrapper around `token` that records start and end locations *)
let loc_token buf =
   let () = swallow_atmosphere buf in (* dispose of garbage before recording start location *)
   let loc_start = next_loc buf in
   let t = token buf in
   let loc_end = next_loc buf in
   (t, loc_start, loc_end)
