open Core

let input_source channel =
   Sexp.input_sexps channel

let load_source path =
   Sexp.load_sexps path

let rec print_source ?(channel = stdout) sexps =
   List.iter sexps (fun sexp ->
         Sexp.output_hum channel sexp ;
         Out_channel.newline stdout
      )

(* FIXME: No idea why this refuses to work. *)
(* let formatter = Format.formatter_of_out_channel channel in
      Sexp.pp_hum formatter |> List.iter sexps *)
