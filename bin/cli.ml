open Core


let do_parse files =
   List.iter files (fun file -> (match file with
      | "-"       -> Ocameel.input_source In_channel.stdin
      | filename  -> Ocameel.load_source filename
   ) |> Ocameel.print_source)


let command =
   Command.basic
      ~summary:"Run some Scheme code"
      Command.Spec.(
         empty
         +> anon (sequence ("filename" %: file))
      )
      (fun files () ->
         match files with
         | []     -> do_parse ["-"]
         | files  -> do_parse files
      )

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
      Command.run ~version:"0.1" command
   )
