open Core


(* ### ocameel parse ### *)

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


(* ### ocameel compile ### *)

let do_compile files =
   List.iter files (fun file ->
         let source = (match file with
               | "-"       -> Ocameel.input_source In_channel.stdin
               | filename  -> Ocameel.load_source filename
            ) in
         Ocameel.compile_program source stdout)

let compile =
   Command.basic
      ~summary:"Compile some Scheme code to x86 assembly"
      Command.Spec.(
         empty
         +> anon (sequence ("filename" %: file))
      )
      (fun files () ->
          match files with
          | []     -> do_compile ["-"]
          | files  -> do_compile files
      )


let () =
   Exn.handle_uncaught ~exit:true (fun () ->
         Command.group ~summary:"Interact with Scheme code"
            [ "parse", parse; "compile", compile ]
         |> Command.run ~version:"0.1"
      )
