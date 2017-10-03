open Core


let parse filename () =
   Ocameel.read_source_from filename |> Ocameel.print_source


let command =
   Command.basic
      ~summary:"Run some Scheme code"
      Command.Spec.(empty +> anon ("source file" %: file))
      parse

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
      Command.run ~version:"1.0" ~build_info:"RWO" command
   )
