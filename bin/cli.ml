open Core


let do_parse files =
   List.iter files (fun file -> (match file with
         | "-"       -> Ocameel.input_source In_channel.stdin
         | filename  -> Ocameel.load_source filename
      ) |> Ocameel.print_source)


let parse =
   Command.basic
      ~summary:"Output a stripped-and-formatted version of a provided Scheme file"
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
         Command.group ~summary:"Interact with Scheme code"
            [ "parse", parse ]
         |> Command.run ~version:"0.1"
      )
