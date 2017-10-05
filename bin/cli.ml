open Core

type stage = Parsing | Compilation | Assembly | Linking


let do_parse files output =
   let out_channel = match output with
      | "-"       -> stdout
      | filename  -> Out_channel.create (filename ^ ".scm")
   in
   List.iter files (fun file -> (match file with
         | "-"       -> Ocameel.input_source In_channel.stdin
         | filename  -> Ocameel.load_source filename )
                                |> Ocameel.print_source ~channel:out_channel )

let do_compile files output =
   let out_channel = match output with
      | "-"       -> stdout
      | filename  -> Out_channel.create filename
   in
   List.iter files (fun file ->
         let source = (match file with
               | "-"       -> Ocameel.input_source In_channel.stdin
               | filename  -> Ocameel.load_source filename)
         in
         Ocameel.compile_program source out_channel )

(* --------------------------- *)

let do_stages stage files output =
   match stage with
   | Parsing      -> do_parse files output
   | Compilation  -> do_compile files output
   | Assembly     -> failwith "NYI: invoking assembler"
   | Linking      -> failwith "NYI: invoking linker"

let command =
   let spec = Command.Spec.(
         empty
         +> flag "-E"
               no_arg ~doc:"boolean Only invoke the parser (effectively pretty-printing and \
                            concatenating the input files)"

         +> flag "-S"
               no_arg ~doc:"boolean Only compile an assembly file (overrides -E)"

         +> flag "-c"
               no_arg ~doc:"boolean Compile, then invoke the assembler; generating a target .o \
                            object-file (overrides -E, -S)"

         +> flag "-o"
               (optional file) ~doc:" Output filename (will be appended with an appropriate \
                                     suffix, based on the chosen stage)"

         (* +> flag "-d" (optional_with_default false bool) ~doc:" Debug mode" *)
         (* +> flag "-v" (optional_with_default false bool) ~doc:" Verbose output" *)
         +> anon (sequence ("filename" %: file)) )
   in

   Command.basic
      ~summary:"Compile some Scheme code to x86 assembly"
      ~readme:(fun () ->
            "By default, the compiler invokes both the assembler and the linker, producing an
executable. This can be overriden by selecting lesser stages with `-E`, `-S`,
or `-c`." )

      spec

      (fun parse_only and_generate and_invoke_assembler output files  () ->
          let output = match output with | None -> "a" | Some filename -> filename in
          let selected_stage =
             if (and_invoke_assembler) then Assembly
             else if (and_generate) then Compilation
             else if (parse_only) then Parsing
             else Linking
          in
          match files with
          | []     -> do_stages selected_stage ["-"] output
          | files  -> do_stages selected_stage files output )

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
         Command.run ~version:"0.1" command )
