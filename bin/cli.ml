open Core
let run () =
   Ocameel.read_source_from "test.scm" |> Ocameel.print_source

let () =
  Exn.handle_uncaught ~exit:true run
