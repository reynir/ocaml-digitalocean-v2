open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let update verbose domain_name domain address =
  let verbose_printl = if verbose
    then Lwt_io.printl
    else Lwt.wrap1 ignore in
  DO.domain_records domain_name
  |> Lwt_stream.find (function
      | Records.A { Records.domain = domain'; _ } ->
        domain = domain'
      | _ -> false)
  >>= function
  | Some (Records.A { Records.ipv4; Records.id; _ }) ->
    if ipv4 = address
    then return_unit
    else
      DO.update_record_data domain_name id address
      >|= Records.show_record
      >>= verbose_printl
  | Some _ ->
    Lwt_io.eprintl "Non-A record exists!" (* TODO: non-A record already exists *)
  | None ->
    DO.add_A domain_name ~domain ~address
    >|= Records.show_record
    >>= verbose_printl

let s idx docv =
  Cmdliner.Arg.(required @@ pos idx (some string) None
                @@ info [] ~docv)

let verbose =
  Cmdliner.Arg.(value @@ flag @@ info ["v"; "verbose"] ~docv:"--verbose")

let cmd = Cmdliner.Term.(pure update $ verbose $ s 0 "DOMAIN" $ s 1 "NAME" $ s 2 "ADDRESS")

let doc = Cmdliner.Term.info ~doc:"Update an A record" "update"

let () = Cmdliner.Term.eval (cmd, doc)
         |> function
         | `Ok main ->
           Lwt_main.run main
         | _ -> ()
