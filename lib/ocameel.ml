open Core

let read_source_from path =
   Sexp.load_sexps path

let rec print_source ?(channel = stdout) sexps =
   Sexp.output_hum channel |> List.iter sexps
