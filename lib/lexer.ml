open Token
open Sedlexing

type token = Token.t * Lexing.position * Lexing.position
type gen = unit -> token option

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
   | _ -> ()

and comment_line buf =
   match%sedlex buf with
   | Star (Compl '\n') -> COMMENT_LINE (Sedlexing.Utf8.lexeme buf) |> locate buf
   | _ -> token_loc buf

(** Return the next token, with location information. *)
and token_loc buf =
   swallow_atmosphere buf;
   match%sedlex buf with
   | eof -> EOF |> locate buf
   | ';' -> comment_line buf

   | identifier -> IDENTIFIER (Sedlexing.Utf8.lexeme buf) |> locate buf

   (* parenths *)
   | '(' -> LEFT_PAREN |> locate buf
   | ')' -> RIGHT_PAREN |> locate buf

   (* YOUR TOKENS HERE... *)
   | _ ->
     match next buf with
     | Some c -> illegal buf c
     | None -> Pervasives.failwith "Unreachable: WTF"


(** Return *just* the next token, discarding location information. *)
let token buf =
   let tok, _, _ = token_loc buf in tok

let gen_loc buf =
   fun () -> match token_loc buf with
      | EOF, _, _ -> None
      | _ as tuple -> Some tuple

let gen buf =
   fun () -> match token_loc buf with
      | EOF, _, _ -> None
      | tok, _, _ -> Some tok

let tokens_loc buf = gen_loc buf |> Gen.to_list
let tokens buf = gen buf |> Gen.to_list




let%test_module "Lexing" = (module struct
   (* {2 Helpers } *)
   let lb str = Sedlexing.Latin1.from_string str

   (* {2 Tests } *)
   let%test "generator yields tokens" =
      let g = Sedlexing.Latin1.from_string "()" |> gen in
      g () = Some LEFT_PAREN &&
      g () = Some RIGHT_PAREN &&
      g () = None

   let%test "can generate into a list" =
      let toks = Sedlexing.Latin1.from_string "()" |> tokens in
      toks = [LEFT_PAREN; RIGHT_PAREN]

   let%test "simple opening paren" =
      lb "(" |> token = LEFT_PAREN

   (* Parens, whitespace, simple identifiers, comments *)
   let%test "simple pair of parens" =
      let buf = lb "()" in
      token buf |> ignore;
      token buf = RIGHT_PAREN

   let%test "bare identifier" =
      let buf = lb "lily-buttons" in
      token buf = IDENTIFIER "lily-buttons"

   let%test "identifier in parens" =
      let buf = lb "(lily-buttons)" in
      token buf = LEFT_PAREN &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = RIGHT_PAREN

   let%test "extraneous whitespace" =
      let buf = lb "   (   lily-buttons   )   " in
      token buf = LEFT_PAREN &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = RIGHT_PAREN

   let%test "extraneous newlines" =
      let buf = lb "\n(\n   lily-buttons\n)\n" in
      token buf = LEFT_PAREN &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = RIGHT_PAREN

   let%test "comments at start of line" =
      let buf = lb "\n(\n; comment!\n   lily-buttons\n)\n" in
      token buf = LEFT_PAREN &&
      token buf = COMMENT_LINE " comment!" &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = RIGHT_PAREN

   let%test "comments at end of line" =
      let buf = lb "\n(\n   lily-buttons ; comment!\n)\n" in
      token buf = LEFT_PAREN &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = COMMENT_LINE " comment!" &&
      token buf = RIGHT_PAREN
end)
