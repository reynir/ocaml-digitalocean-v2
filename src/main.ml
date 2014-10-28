open Lwt
open Lwt_io

let main : unit Lwt.t =
  Util.get_token
  >>= fun (module Auth_token) ->
  let module DO = Digitalocean.Make(Auth_token) in
  DO.actions_all
  >>= fun xs -> 
  Yojson.Safe.to_string (`List xs)
  |> printl

let () =
  Lwt_main.run main
