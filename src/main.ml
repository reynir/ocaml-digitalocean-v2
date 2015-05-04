open Lwt
open Lwt_io

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let print_actions () : unit Lwt.t =
  DO.actions ()
  |> Lwt_stream.iter (fun x -> Responses.action_to_yojson x
                               |> Yojson.Safe.pretty_to_string
                               |> print_endline)

let print_droplets () : unit Lwt.t =
  DO.droplets ()
  |> Lwt_stream.iter (fun x -> Responses.droplet_to_yojson x
                               |> Yojson.Safe.pretty_to_string
                               |> print_endline)

let print_domains () : unit Lwt.t =
  DO.domains ()
  |> Lwt_stream.iter (fun x -> Responses.domain_to_yojson x
                               |> Yojson.Safe.pretty_to_string
                               |> print_endline)

let print_domain_records domain =
  DO.domain_records domain
  |> Lwt_stream.iter (fun x -> Records.show_record x
                               |> print_endline)

let main : unit Lwt.t =
  print_actions ()
  >>= print_droplets
  >>= print_domains
  >>= fun () ->
  DO.domains ()
  |> Lwt_stream.get
  >>= begin function
    | None ->return ()
    | Some { Responses.name; _ } -> 
      print_domain_records name
  end


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

