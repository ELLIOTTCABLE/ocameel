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

(* Register exceptions for pretty printing *)
let _ =
   let open Location in
   register_error_of_exn (function
         | LexError (pos, msg) ->
           let loc = { loc_start = pos; loc_end = pos; loc_ghost = false} in
           Some { loc; msg; sub=[]; if_highlight=""; }
         | ParseError (token, loc_start, loc_end) ->
           let loc = Location.{ loc_start; loc_end; loc_ghost = false} in
           let msg =
              (* show_token token *) failwith "nyi"
              |> Printf.sprintf "parse error while reading token '%s'" in
           Some { loc; msg; sub=[]; if_highlight=""; }
         | _ -> None)


let failwith buf s = raise (LexError (buf.pos, s))

let illegal buf c =
   Char.escaped c
   |> Printf.sprintf "unexpected character in expression: '%s'"
   |> failwith buf

(* regular expressions  *)
(* let letter = [%sedlex.regexp? 'A'..'Z' | 'a'..'z'] *)
(* let digit = [%sedlex.regexp? '0'..'9'] *)
(* let id_init = [%sedlex.regexp? letter  | '_'] *)
(* let id_cont = [%sedlex.regexp? id_init | Chars ".\'" | digit ] *)
(* let id = [%sedlex.regexp? id_init, Star id_cont ] *)
(* let hex = [%sedlex.regexp? digit | 'a'..'f' | 'A'..'F' ] *)
(* let hexnum = [%sedlex.regexp? '0', 'x', Plus hex ] *)
(* let decnum = [%sedlex.regexp? Plus digit] *)
(* let decbyte = [%sedlex.regexp? (digit,digit,digit) | (digit,digit) | digit ] *)
(* let hexbyte = [%sedlex.regexp? hex,hex ] *)
let newline = [%sedlex.regexp? '\r' | '\n' | "\r\n" ]
let whitespace = [%sedlex.regexp? ' ' | newline ]

(** Swallow whitespace and comments. *)
let rec swallow_garbage buf =
   match%sedlex buf with
   | Plus whitespace -> swallow_garbage buf
   | ";" -> swallow_comment buf
   | _ -> ()

and swallow_comment buf =
   match%sedlex buf with
 (*| eof -> failwith buf "Unterminated comment at EOF"*)
   | newline -> swallow_garbage buf
   | any -> swallow_comment buf
   | _ -> assert false

(* returns the next token *)
let token buf =
   swallow_garbage buf;
   match%sedlex buf with
   | eof -> EOF
   (* parenths *)
   | '(' -> LPAR
   | ')' -> RPAR
   (* YOUR TOKENS HERE... *)
   | _ -> illegal buf (Char.chr (next buf))

(* wrapper around `token` that records start and end locations *)
let loc_token buf =
   let () = swallow_garbage buf in (* dispose of garbage before recording start location *)
   let loc_start = next_loc buf in
   let t = token buf in
   let loc_end = next_loc buf in
   (t, loc_start, loc_end)
