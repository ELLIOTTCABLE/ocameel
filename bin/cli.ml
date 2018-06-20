open Core

type stage = Parsing | Compilation | Assembly | Linking

let do_parse files options output =
   let out_channel = match output with
      | "-"       -> stdout
      | out_file  -> Out_channel.create (out_file ^ ".scm")
   in
   List.iter files (fun in_file -> (match in_file with
         | "-"       -> Ocameel.input_source In_channel.stdin
         | in_file   -> Ocameel.load_source in_file )
                                   |> Ocameel.print_source ~channel:out_channel ) ;
   Out_channel.close out_channel

let do_compile files options output =
   let out_channel = match output with
      | "-"       -> stdout
      | out_file  -> Out_channel.create (out_file ^ ".s")
   in match files with

   | [ in_file ] ->
     let source = (match in_file with
           | "-"     -> Ocameel.input_source In_channel.stdin
           | in_file -> Ocameel.load_source in_file)
     in
     Ocameel.compile_program source out_channel ;
     Out_channel.close out_channel

   | _ ->
     failwith "NYI: multiple input files"

(* --------------------------- *)

let do_stages stage files options output =
   match stage with
   | Parsing      -> do_parse files options output
   | Compilation  -> do_compile files options output

   | Assembly     -> failwith "NYI: invoking linker"

   (* FIXME: error handling *)
   | Linking      ->
     do_compile files options output ;
     ignore (Unix.exec ~use_path: true
                ~prog: "gcc"
                ~argv: [ "gcc" ; "-o" ; output ; (output ^ ".s") ; "runtime.o"  ]
                () )

let command =
   let spec = Command.Spec.(
         empty
         +> flag "-E"
               no_arg ~doc:"Only invoke the parser (effectively pretty-printing and \
                            concatenating the input files)"

         +> flag "-S"
               no_arg ~doc:"Only compile an assembly file (overrides -E)"

         +> flag "-c"
               no_arg ~doc:"Compile, then invoke the assembler; generating a target .o \
                            object-file (overrides -E, -S)"

         +> flag "-o"
               (optional file) ~doc:"file-name Designate output file (Will be appended with an appropriate \
                                     suffix, based on the chosen stage)"

         +> flag "-dump-ast"
               (optional file) ~doc:"file-name Dumps an internal representation of input \
                                     programs to file-name"

         (* +> flag "-d" (optional_with_default false bool) ~doc:" Debug mode" *)
         (* +> flag "-v" (optional_with_default false bool) ~doc:" Verbose output" *)
         +> anon (sequence ("filename" %: file)) )
   in

   Command.basic_spec
      ~summary:"Compile some Scheme code to x86 assembly"
      ~readme:(fun () ->
            "By default, the compiler invokes both the assembler and the linker, producing an
executable. This can be overriden by selecting lesser stages with `-E`, `-S`,
or `-c`." )

      spec

      (fun parse_only and_generate and_invoke_assembler
         output_to dump_ast_to files () ->
          let output_to = match output_to with | None -> "a" | Some filename -> filename in
          let selected_stage =
             if (and_invoke_assembler) then Assembly
             else if (and_generate) then Compilation
             else if (parse_only) then Parsing
             else Linking

          and options = {
             Ocameel.ast_dump_output_file = dump_ast_to;
          }

          in match files with
          | []     -> do_stages selected_stage ["-"] options output_to
          | files  -> do_stages selected_stage files options output_to )

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
         Command.run ~version:"0.1" command )
