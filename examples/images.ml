open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let print_images privat typ () =
  DO.images ~privat ?typ ()
  |> Lwt_stream.iter_s (fun x -> Responses.image_to_yojson x
                               |> Yojson.Safe.pretty_to_string
                               |> Lwt_io.printl)

let privat = Cmdliner.Arg.(value @@ flag @@ 
                           info ["p"; "private"] ~doc:"List only private images")

let typ = Cmdliner.Arg.(value @@ pos 0 (some string) None
                        @@ info [] ~docv:"TYPE" ~doc:"List only this type")

let cmd = Cmdliner.Term.(pure print_images $ privat $ typ)

let doc = Cmdliner.Term.info
    ~doc:"Images is a light weight utility to list images"
    ~man:[
      `P begin
        "This command will query the Digitalocean API for a list of images," ^
        " and print the resulting json objects. It is possible to filter on" ^
        " `type' and `private' images." end;
      `P begin
        "Note that the output is the individual image json objects, and only" ^
        " with the fields that were documented at implementation time. This" ^
        " means any undocumented fields will be filtered out!" end;
      `S "Examples";
      `I begin
        "Example 1",
        "images"
      end;
      `P "Lists all images, private, public, distros and application images.";
      `I begin
        "Example 2",
        "images distributions"
      end;
      `P "Lists only distribution images.";
      `I begin
        "Example 3",
        "images --private"
      end;
      `P "Lists only private images, i.e. snapshots made by the user.";
    ]
    "images"

let () =
  match Cmdliner.Term.eval (cmd, doc) with
  | `Ok main ->
    Lwt_main.run
      begin try%lwt
        main ()
        with Responses.Bad_response (err, json) ->
          Lwt_io.fprintl Lwt_io.stderr ("Bad_response: " ^ err) >>
          Lwt_io.fprintl Lwt_io.stderr ("JSON: " ^ Yojson.Safe.pretty_to_string json) >>
          exit 1
      end
  | _ -> ()

