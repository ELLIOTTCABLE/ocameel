open Token
open Sedlexing

type mode = Main | BlockComment of int | Number of int option | String
type buffer = {
   sedlex: Sedlexing.lexbuf;
   mutable mode: mode
}

type token = Token.t * Lexing.position * Lexing.position
type gen = unit -> token option

exception LexError of (Lexing.position * string) [@@deriving sexp]
exception ParseError of token [@@deriving sexp]

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


(* {2 Regular expressions } *)
let newline = [%sedlex.regexp? "\r\n" | '\r' | '\n' ]

(* TODO: I *could* crib JavaScript's definition of 'whitespace', expanding on Unicode category 'Zs'?
 *          <http://www.ecma-international.org/ecma-262/6.0/#table-32> *)
let whitespace = [%sedlex.regexp? ' ' | newline ]

(* {3 Numbers } *)
let digit2 = [%sedlex.regexp? '0'..'1' ]
let digit8 = [%sedlex.regexp? digit2 | '2'..'7' ]
let digit10 = [%sedlex.regexp? digit8 | '8'..'9' ]
let digit16 = [%sedlex.regexp? digit10 | 'A'..'F' | 'a'..'f' ]

let sign = [%sedlex.regexp? "" | '+' | '-']
let exactness = [%sedlex.regexp? Opt('#', Chars "eiEI") ]

let radix10 = [%sedlex.regexp? Opt('#', Chars "dD") ]
let prefix10 = [%sedlex.regexp? (exactness, radix10) | (radix10, exactness) ]
let suffix10 = [%sedlex.regexp? Opt(Chars("esfdlESFDL"), sign, Plus digit10) ]
let uinteger10 = [%sedlex.regexp? Plus(digit10), Star('#') ]
let decimal10 = [%sedlex.regexp? uinteger10, suffix10 |
                               '.', Plus(digit10), Star('#'), suffix10 |
                               Plus(digit10), '.', Star(digit10), Star('#'), suffix10 |
                               Plus(digit10), Plus('#'), '.', Star('#'), suffix10 ]
let ureal10 = [%sedlex.regexp? uinteger10 | (uinteger10, '/', uinteger10) | decimal10 ]
let real10 = [%sedlex.regexp? sign, ureal10 ]

(* FIXME: NYI: lexing complexes *)
let complex10 = [%sedlex.regexp? real10 ]

(* FIXME: NYI: lexing non-base-10 numbers *)
let num10 = [%sedlex.regexp? prefix10 ]

let number = [%sedlex.regexp? num10 ]

(* {3 Identifiers } *)
(* FIXME: I'd really like to make this more multilingual, but I have no idea which Unicode
 *        categories or traits to use ... *)
let letter = [%sedlex.regexp? 'A'..'Z' | 'a'..'z' ]

let special_initial = [%sedlex.regexp? Chars "!$%&*/:<=>?^_~" ]
let initial = [%sedlex.regexp? letter | special_initial ]

let special_subsequent = [%sedlex.regexp? Chars "+-.@" ]
let subsequent = [%sedlex.regexp? initial | digit10 | special_subsequent ]

let peculiar_identifier = [%sedlex.regexp? '+' | '-' | "..." ]
let identifier = [%sedlex.regexp? (initial, Star subsequent) | peculiar_identifier ]


(* Swallows whitespace. *)
let rec swallow_atmosphere buf =
   let s = buf.sedlex in
   match%sedlex s with
   | Plus whitespace -> swallow_atmosphere buf
   | _ -> ()


let rec comment buf =
   let s = buf.sedlex in
   match%sedlex s with
   | eof -> EOF |> locate buf
   | Star (Compl ('\r' | '\n')) ->
     COMMENT_LINE (utf8 buf) |> locate buf
   | _ -> unreachable "comment"

and number base buf =
   failwith "NYI"

(* Wow. This is a monstrosity. *)
and block_comment depth buf =
   let s = buf.sedlex in
   match%sedlex s with
   | "|#" ->
     buf.mode <- (if depth = 1 then Main else BlockComment (depth - 1));
     RIGHT_COMMENT_DELIM |> locate buf

   | "#|" ->
     buf.mode <- BlockComment (depth + 1);
     LEFT_COMMENT_DELIM |> locate buf

   | '#', Compl '|'
   | '|', Compl '#'
   | Plus (Compl ('#' | '|')) ->
     let start, _ = sedlex_of_buffer buf |> Sedlexing.lexing_positions
     and acc = Buffer.create 256 (* 3 lines of 80 chars = ~240 bytes *) in
     Buffer.add_string acc (utf8 buf);
     continuing_block_comment buf start acc

   | eof -> lexfail buf "Reached end-of-file without finding a matching block-comment end-delimiter"
   | _ -> unreachable "block_comment"

and continuing_block_comment buf start acc =
   let s = buf.sedlex in
   let _, curr = Sedlexing.lexing_positions s in
   match%sedlex s with
   | "|#"
   | "#|" ->
     Sedlexing.rollback s;
     COMMENT_CHUNK (Buffer.contents acc), start, curr

   | '#', Compl '|'
   | '|', Compl '#'
   | Plus (Compl ('#' | '|')) ->
     Buffer.add_string acc (utf8 buf);
     continuing_block_comment buf start acc

   | eof -> lexfail buf "Reached end-of-file without finding a matching block-comment end-delimiter"
   | _ -> unreachable "continuing_block_comment"

and main buf =
   swallow_atmosphere buf;
   let s = buf.sedlex in
   match%sedlex s with
   | eof -> EOF |> locate buf

   (* The commenting-out of entire s-expressions is handled at the parser level ... *)
   | "#;" -> HASH_SEMI |> locate buf

   (* ... while one-line comments are lexed as a single token ... *)
   | ';' -> comment buf

   (* ... and block-comments swap into a custom lexing-mode to handle proper nesting. *)
   | "#|" ->
     buf.mode <- BlockComment 1;
     LEFT_COMMENT_DELIM |> locate buf
   | "|#" -> lexfail buf "Unmatched block-comment end-delimiter"

   | identifier -> IDENTIFIER (utf8 buf) |> locate buf

   | '(' -> LEFT_PAREN |> locate buf
   | ')' -> RIGHT_PAREN |> locate buf

   | _ ->
     match next buf.sedlex with
     | Some c -> illegal buf c
     | None -> unreachable "main"


(** Return the next token, with location information. *)
let token_loc buf =
   match buf.mode with
   | Main -> main buf
   | BlockComment depth -> block_comment depth buf
   | Number base -> number base buf
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
   let show_tokens = [%derive.show: Token.t list]

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

   let%expect_test "block-comments are bracketed by delimiter tokens" =
      let buf = lb "#| block comment |#" in
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      [%expect {|
         Token.LEFT_COMMENT_DELIM
         (Token.COMMENT_CHUNK " block comment ")
         Token.RIGHT_COMMENT_DELIM
      |}]

   let%expect_test "block-comments support non-delimiter hashes and bars within" =
      let buf = lb "#| block | # comment |#" in
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      [%expect {|
         Token.LEFT_COMMENT_DELIM
         (Token.COMMENT_CHUNK " block | # comment ")
         Token.RIGHT_COMMENT_DELIM
      |}]

   let%expect_test "block-comments can be nested" =
      let buf = lb "#| nested #| block |# comment |#" in
      tokens buf |> show_tokens |> print_endline;
      [%expect {|
         [Token.LEFT_COMMENT_DELIM; (Token.COMMENT_CHUNK " nested ");
           Token.LEFT_COMMENT_DELIM; (Token.COMMENT_CHUNK " block ");
           Token.RIGHT_COMMENT_DELIM; (Token.COMMENT_CHUNK " comment ");
           Token.RIGHT_COMMENT_DELIM]
      |}]

   let%expect_test "block-comments throw a LexError if unbalanced" =
      let buf = lb "#| nested #| block |# comment" in
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      token buf |> Token.show |> print_endline;
      [%expect {|
         Token.LEFT_COMMENT_DELIM
         (Token.COMMENT_CHUNK " nested ")
         Token.LEFT_COMMENT_DELIM
         (Token.COMMENT_CHUNK " block ")
         Token.RIGHT_COMMENT_DELIM
      |}];

      try token buf |> ignore with
      | LexError _ as exn ->
        match error_of_exn exn with
        | None -> raise exn
        | Some err -> Location.report_error Format.std_formatter err;
      [%expect {|
         File "", line 0, characters 29-29:
         Error: Reached end-of-file without finding a matching block-comment end-delimiter
      |}]
end)
