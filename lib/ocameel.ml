open Core

let input_source channel =
   Sexp.input_sexps channel

let load_source path =
   Sexp.load_sexps path

let print_source ?(channel = stdout) sexps =
   let formatter = Format.formatter_of_out_channel channel in
   Sexp.pp_hum formatter |> List.iter sexps ;
   Format.pp_print_flush formatter ()


let rec compile_program sexps channel =
   let entry =  Printf.sprintf ("_scheme_entry:") in
   let return = Printf.sprintf ("ret") in
   Out_channel.output_lines channel [entry] ;
   compile_list sexps channel ;
   Out_channel.output_lines channel [return]

and compile_sexp sexp channel =
   match sexp with
   | Sexp.Atom str   -> compile_atom str channel
   | Sexp.List sexps -> compile_list sexps channel

and compile_list sexps channel =
   match sexps with
   | [sexp]    -> compile_sexp sexp channel
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
