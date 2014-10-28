open Lwt
open Lwt_io

let main : unit Lwt.t =
  Util.get_token
  >>= fun (module Auth_token) ->
  let module DO = Digitalocean.Make(Auth_token) in
  DO.actions ()
  |> Lwt_stream.iter (fun x -> Yojson.Safe.to_string x |> print_endline)

let () =
  Lwt_main.run main
