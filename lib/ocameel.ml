open Core

let input_source channel =
   Sexp.input_sexps channel

let load_source path =
   Sexp.load_sexps path

let print_source ?(channel = stdout) sexps =
   List.iter sexps (fun sexp ->
         Sexp.output_hum channel sexp ;
         Out_channel.newline stdout
      )

(* FIXME: No idea why this refuses to work. *)
(* let formatter = Format.formatter_of_out_channel channel in
   Sexp.pp_hum formatter |> List.iter sexps *)

let rec compile sexp channel =
   match sexp with
   | Sexp.Atom str   -> compile_atom str channel
   | Sexp.List sexps -> compile_list sexps channel

and compile_list sexps channel =
   match sexps with
   | [sexp]    -> compile sexp channel
   | []        -> failwith "NYI: empty expression"
   | hd :: tl  -> failwith "NYI: multiple atoms"

and compile_atom str channel =
   match str.[0] with
   | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ->
         compile_int str channel
   | _ -> failwith "NYI: everything else"

and compile_int str channel =
   let i = int_of_string str in
   let instr = Printf.sprintf ("movl $%i %%eax") i in
   Out_channel.output_lines channel [instr]
