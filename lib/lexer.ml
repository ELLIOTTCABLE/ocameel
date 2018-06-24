open Token
open Sedlexing

type token = Token.t * Lexing.position * Lexing.position

exception LexError of (Lexing.position * string)
exception ParseError of token


let locate buf token =
   let start, curr = lexing_positions buf in
   token, start, curr


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


let failwith buf s =
   let start, curr = lexing_positions buf in
   raise (LexError (curr, s))

let illegal buf c =
   Uchar.to_int c
   |> Printf.sprintf "unexpected character in expression: 'U+%04X'"
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
   | eof -> EOF |> locate buf

   | identifier -> IDENTIFIER (Sedlexing.Utf8.lexeme buf) |> locate buf

   (* parenths *)
   | '(' -> LEFT_PAREN |> locate buf
   | ')' -> RIGHT_PAREN |> locate buf

   (* YOUR TOKENS HERE... *)
   | _ ->
     match next buf with
     | Some c -> illegal buf c
     | None -> Pervasives.failwith "Unreachable: WTF"


let lb str = Sedlexing.Latin1.from_string str

let%test _ = token (lb "()") = LEFT_PAREN
