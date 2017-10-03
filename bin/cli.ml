open Core


let parse filename =
   Ocameel.read_source_from filename |> Ocameel.print_source


let spec =
  let open Command.Spec in
  empty
  +> anon ("filename" %: string)

let command =
  Command.basic
    ~summary:"Run some Scheme code"
    spec
    (fun filename () ->
       parse filename)

let () =
  Exn.handle_uncaught ~exit:true (fun () ->
     Command.run ~version:"1.0" ~build_info:"RWO" command
  )
