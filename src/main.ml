open Lwt

let make_url obj : Uri.t = Uri.of_string ("https://api.digitalocean.com/v2/" ^ obj)

let get_token : string Lwt.t =
  Lwt_io.open_file ~mode:Lwt_io.Input "token"
  >>=
  Lwt_io.read_line

let main (token : string) : unit Lwt.t =
  let headers = Cohttp.Header.init_with "Authorization" ("Bearer "^token) in
  Cohttp_lwt_unix.Client.get ~headers (make_url "droplets")
  >>= fun (resp, body) ->
  Cohttp_lwt_body.to_string body 
  >>= fun s ->
  print_endline s
  |> Lwt.return

let () =
  Lwt_main.run (get_token >>= main)
