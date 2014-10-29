open Lwt
open Lwt_io

let (>>-) a b = a >>= fun _ -> b


module DO = Digitalocean.Make((val (Lwt_main.run Util.get_token)))

let print_actions () : unit Lwt.t =
  DO.actions ()
  |> Lwt_stream.iter (fun x -> Responses.action_to_yojson x
                               |> Yojson.Safe.to_string
                               |> print_endline)

let print_droplets () : unit Lwt.t =
  DO.droplets ()
  |> Lwt_stream.iter (fun x -> Responses.droplet_to_yojson x
                               |> Yojson.Safe.pretty_to_string
                               |> print_endline)

let main : unit Lwt.t =
  print_actions ()
  >>= print_droplets
let () =
  try
    Lwt_main.run main
  with Responses.Bad_response (err, json) ->
    Lwt_main.run
      begin fprintl stderr ("Bad_response: " ^ err)
            >>= fun () ->
            fprintl stderr ("JSON: " ^ Yojson.Safe.pretty_to_string json)
      end;
    exit 1
    
