open Token
open Sedlexing

type mode = Main | BlockComment of int | String
type buffer = {
   sedlex: Sedlexing.lexbuf;
   mutable mode: mode
}

type token = Token.t * Lexing.position * Lexing.position
type gen = unit -> token option

exception LexError of (Lexing.position * string)
exception ParseError of token

let sedlex_of_buffer buf = buf.sedlex
let buffer_of_sedlex sedlex = { sedlex = sedlex; mode = Main }


let locate buf token =
   let start, curr = lexing_positions buf.sedlex in
   token, start, curr

let utf8 buf = Sedlexing.Utf8.lexeme buf.sedlex


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


let lexfail buf s =
   let start, curr = lexing_positions buf.sedlex in
   raise (LexError (curr, s))

let illegal buf c =
   Uchar.to_int c
   |> Printf.sprintf "unexpected character in expression: 'U+%04X'"
   |> lexfail buf

let unreachable str =
   failwith (Printf.sprintf "Unreachable: %s" str)


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


(* Swallows whitespace. *)
let rec swallow_atmosphere buf =
   let s = buf.sedlex in
   match%sedlex s with
   | Plus whitespace -> swallow_atmosphere buf
   | _ -> ()


let rec comment buf =
   let s = buf.sedlex in
   match%sedlex s with
   | Star (Compl ('\r' | '\n')) ->
     COMMENT_LINE (utf8 buf) |> locate buf
   | _ -> unreachable "comment"

and block_comment depth buf =
   let s = buf.sedlex in
   match%sedlex s with
   | "|#" ->
     buf.mode <- (if depth = 1 then Main else BlockComment (depth - 1));
     RIGHT_COMMENT_DELIM |> locate buf
   | "#|" ->
     buf.mode <- BlockComment (depth + 1);
     LEFT_COMMENT_DELIM |> locate buf
   | Plus any -> COMMENT_CHUNK (utf8 buf) |> locate buf
   | eof -> lexfail buf "Reached end-of-file without finding closing block-comment marker"
   | _ -> unreachable "block_comment"

and main buf =
   swallow_atmosphere buf;
   let s = buf.sedlex in
   match%sedlex s with
   | eof -> EOF |> locate buf
   | ';' -> comment buf

   | "#|" ->
     buf.mode <- BlockComment 1;
     LEFT_COMMENT_DELIM |> locate buf
   | "|#" -> lexfail buf "Unmatched block-comment close"

   | identifier -> IDENTIFIER (utf8 buf) |> locate buf

   (* parenths *)
   | '(' -> LEFT_PAREN |> locate buf
   | ')' -> RIGHT_PAREN |> locate buf

   (* YOUR TOKENS HERE... *)
   | _ ->
     match next buf.sedlex with
     | Some c -> illegal buf c
     | None -> unreachable "main"


(** Return the next token, with location information. *)
let token_loc buf =
   match buf.mode with
   | Main -> main buf
   | BlockComment depth -> block_comment depth buf
   | String -> failwith "NYI"


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

let mode buf = buf.mode


(* ---- --- ---- /!\ ---- --- ---- *)

let%test_module "Lexing" = (module struct
   (* {2 Helpers } *)
   let lb str = buffer_of_sedlex (Sedlexing.Utf8.from_string str)

   (* {2 Tests } *)
   let%test "generator yields tokens" =
      let g = buffer_of_sedlex (Sedlexing.Utf8.from_string "()") |> gen in
      g () = Some LEFT_PAREN &&
      g () = Some RIGHT_PAREN &&
      g () = None

   let%test "can generate into a list" =
      let toks = buffer_of_sedlex (Sedlexing.Utf8.from_string "()") |> tokens in
      toks = [LEFT_PAREN; RIGHT_PAREN]

   let%test "simple opening paren" =
      lb "(" |> token = LEFT_PAREN

   (* Parens, whitespace, simple identifiers, line-comments *)
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

   let%test "line-comments at start of line" =
      let buf = lb "\n(\n; comment!\n   lily-buttons\n)\n" in
      token buf = LEFT_PAREN &&
      token buf = COMMENT_LINE " comment!" &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = RIGHT_PAREN

   let%test "line-comments at end of line" =
      let buf = lb "\n(\n   lily-buttons ; comment!\n)\n" in
      token buf = LEFT_PAREN &&
      token buf = IDENTIFIER "lily-buttons" &&
      token buf = COMMENT_LINE " comment!" &&
      token buf = RIGHT_PAREN

   (* Block comments *)
   let%test "block-comments start with a delimiter token" =
      let buf = lb "#| block comment |#" in
      token buf = LEFT_COMMENT_DELIM

   let%test "block-comments contain comment-chunk tokens" =
      let buf = lb "#| block comment |#" in
      token buf |> ignore;
      match token buf with
      | COMMENT_CHUNK _ -> true
      | _ -> false
end)
