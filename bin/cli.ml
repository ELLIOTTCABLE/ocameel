open Core


let parse filename () =
   (  match filename with
      | None | Some "-" -> Ocameel.input_source In_channel.stdin
      | Some filename   -> Ocameel.load_source filename
   ) |> Ocameel.print_source


let command =
   Command.basic
      ~summary:"Run some Scheme code"
      Command.Spec.(empty +> anon (maybe ("source-file" %: file)))
      parse

let () =
   Exn.handle_uncaught ~exit:true (fun () ->
      Command.run ~version:"0.1" command
   )
