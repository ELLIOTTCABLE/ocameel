open Core


let parse filename () =
   (  match filename with
      | "-"       -> Ocameel.input_source In_channel.stdin
      | filename  -> Ocameel.load_source filename
   ) |> Ocameel.print_source


let command =
   Command.basic
      ~summary:"Run some Scheme code"
      Command.Spec.(
         empty
         +> anon (maybe_with_default "-" ("filename" %: file))
      )
      parse

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
      Command.run ~version:"0.1" command
   )
