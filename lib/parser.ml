open Core_kernel
open Sexplib.Sexp


(** {2: Numerics } *)

type radix = Binary | Octal | Decimal | Hex

let radix_of_string = function
   | "#b" -> Binary
   | "#o" -> Octal
   | "#d" -> Decimal
   | "#x" -> Hex
   | _ -> failwith "Unreachable: unsupported radix-string"

let string_of_radix = function
   | Binary -> "#b"
   | Octal -> "#o"
   | Decimal -> "#d"
   | Hex -> "#x"

let radix_re = let open Tyre in
   conv radix_of_string string_of_radix (regex (Re_posix.re "#[bodx]"))

let decimal_only = let open Tyre in
   conv radix_of_string string_of_radix (regex (Re_posix.re "#d"))

type sign = Positive | Negative

let sign_of_string = function
   | "+" -> Positive
   | "-" -> Negative
   | _ -> failwith "Unreachable: unsupported sign-string"

let string_of_sign = function
   | Positive -> "+"
   | Negative -> "-"

let sign_re = let open Tyre in
   conv sign_of_string string_of_sign (regex (Re_posix.re "[+-]"))

let char_of_int n =
   if n < 9 then
      char_of_int (48 + n) (* '0'..'9' start at ASCII 48 *)
   else
      char_of_int (55 + n) (* 'A'..'F' start at ASCII 65 *)

let uint_re n = let open Tyre in
   (regex (Re.rg '0' (char_of_int n)))

let decimal_re = Tyre.compile (uint_re 10)


(** DOCME
 * *)
let rec parse_program (sexps : Sexp.t list)
   : AST.t option =
   failwith "NYI"

and parse_root_expr (sexp : Sexp.t)
   : AST.expr =
   failwith "NYI"

and parse_literal =
   function
   | List _ -> None
   | Atom str ->
     match parse_boolean str with
     | Some b -> Some (AST.Boolean b)
     | None ->
       match parse_number str with
       | Some n -> Some (AST.Numeric n)
       | None ->
         match parse_str

and parse_boolean =
   function
   | "#t" -> Some true
   | "#f" -> Some false
   | _ -> None

and parse_number s = let open Tyre in
   match exec decimal_re s with
   | Ok s -> Some (AST.Decimal s)
   | Error `NoMatch (_) -> None
   | Error `ConverterFailure exn -> None


and parse_expr (sexp : Sexp.t)
   : AST.expr option =
   failwith "NYI"
