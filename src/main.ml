open Lwt
open Lwt_io

let main : unit Lwt.t =
  Util.get_token
  >>= fun token ->
  let module DO = Digitalocean.Make(struct let token = token end) in
  DO.get_actions
  >>= printl

let () =
  Lwt_main.run main
