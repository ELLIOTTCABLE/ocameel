open Core

let input_source channel =
   Sexp.input_sexps channel

let load_source path =
   Sexp.load_sexps path

let print_source ?(channel = stdout) sexps =
   let formatter = Format.formatter_of_out_channel channel in
   List.iter ~f:(fun (sexp) -> Sexp.pp_hum formatter sexp) sexps ;
   Format.pp_print_flush formatter () ;
   Out_channel.newline channel


let rec compile_program sexps channel =
   Out_channel.output_lines channel [
      Printf.sprintf (".text") ;
      Printf.sprintf (".align 4,0x90") ;
      Printf.sprintf (".globl _scheme_entry") ;
      Printf.sprintf ("_scheme_entry:")
   ] ;

   compile_list sexps channel ;

   Out_channel.output_lines channel [
      Printf.sprintf ("ret")
   ]

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
   (* TODO: Radix and exactness prefixes (`#e1e10`) *)
   (* FIXME: `-` needs to be a unary operation, I think? *)
   match str.[0] with
   | '-' | '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ->
     compile_int str channel
   | _ -> failwith "NYI: everything else"

and compile_int str channel =
   let i = int_of_string str in
   let instr = Printf.sprintf ("movl $%i, %%eax") i in
   Out_channel.output_lines channel [instr]
