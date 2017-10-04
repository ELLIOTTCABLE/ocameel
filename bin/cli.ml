open Core


(* ### ocameel parse ### *)

let do_parse files output =
   let out_channel = match output with
   | "-"       -> stdout
   | filename  -> Out_channel.create filename
   in
   List.iter files (fun file -> (match file with
         | "-"       -> Ocameel.input_source In_channel.stdin
         | filename  -> Ocameel.load_source filename
      ) |> Ocameel.print_source ~channel:out_channel)

let parse ~common =
   Command.basic
      ~summary:"Output a stripped-and-formatted version of a provided Scheme file"
      Command.Spec.(
         empty
         +> anon (sequence ("filename" %: file))
         ++ common
      )
      (fun files output () ->
          match files with
          | []     -> do_parse ["-"] output
          | files  -> do_parse files output
      )


(* ### ocameel compile ### *)

let do_compile files output =
   let out_channel = match output with
   | "-"       -> stdout
   | filename  -> Out_channel.create filename
   in
   List.iter files (fun file ->
         let source = (match file with
               | "-"       -> Ocameel.input_source In_channel.stdin
               | filename  -> Ocameel.load_source filename
            ) in
         Ocameel.compile_program source out_channel)

let compile ~common =
   Command.basic
      ~summary:"Compile some Scheme code to x86 assembly"
      Command.Spec.(
         empty
         +> anon (sequence ("filename" %: file))
         ++ common
      )
      (fun files output () ->
          match files with
          | []     -> do_compile ["-"] output
          | files  -> do_compile files output
      )


let () =
   let common =
    Command.Spec.(
      empty
      +> flag "-o" (optional_with_default "-" file) ~doc:" Output filename"
   (* +> flag "-d" (optional_with_default false bool) ~doc:" Debug mode" *)
   (* +> flag "-v" (optional_with_default false bool) ~doc:" Verbose output" *)
    )
  in
   Exn.handle_uncaught ~exit:true (fun () ->
         Command.group ~summary:"Interact with Scheme code"
            [ "parse", parse common; "compile", compile common ]
         |> Command.run ~version:"0.1"
      )
