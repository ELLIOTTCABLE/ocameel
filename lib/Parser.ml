open Core

(* Mostly cribbed from Steffen Smolka's 2017 ocaml-parsing boilerplate:
      <https://github.com/smolkaj/ocaml-parsing> *)

exception ParseError of (Lexer.token * Lexing.position * Lexing.position)

(* I alias this to hide the noisy name from error-messages. *)
type ('a, 'b) interface = ('a, 'b) MenhirLib.Convert.traditional
type 'a production = (Lexer.token, 'a) interface

module AST = struct
   type sexp = Base.Sexp.t = Atom of string | List of sexp list
   type t = sexp list
end


let parse lexbuf production =
   let last_token = ref Lexing.(Lexer.EOF, dummy_pos, dummy_pos) in
   let next_token () = last_token := Lexer.loc_token lexbuf; !last_token in
   try MenhirLib.Convert.Simplified.traditional2revised production next_token with
   | Lexer.LexError (pos, s) -> raise (Lexer.LexError (pos, s))
   | _ -> raise (ParseError (!last_token))


let pp_exceptions () =
   (* XXX: Jane Street Core intentionally blocks `Printexc`, without a clear explanation as to why.
    *      Should I not be using it?
    *      (See: <https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/Printexc/> *)
  Caml.Printexc.register_printer (fun exn -> Core.Option.try_with (fun () ->
    Location.report_exception Format.str_formatter exn;
    Format.flush_str_formatter ()))


module Utf8 = struct
   let parse_string ?pos s production =
      parse (LexBuffer.Utf8.from_string ?pos s) production

   let parse_file ~file production =
      let chan = In_channel.create file in
      parse (LexBuffer.Utf8.from_channel chan) production

   let parse_channel chan production =
      parse (LexBuffer.Utf8.from_channel chan) production
end


module Ascii = struct
   let parse_string ?pos s production =
      parse (LexBuffer.Ascii.from_string ?pos s) production

   let parse_file ~file production =
      let chan = In_channel.create file in
      parse (LexBuffer.Ascii.from_channel chan) production

   let parse_channel chan production =
      parse (LexBuffer.Ascii.from_channel chan) production
end
