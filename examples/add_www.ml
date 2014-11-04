open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let is_www = function
  | Records.CNAME { Records.domain = "www"; _ }
  | Records.A { Records.domain = "www"; _ } ->
     true
  | _ -> false

let do_add domain_name : unit Lwt.t =
  DO.domain_records domain_name
  |> Lwt_stream.to_list
  >>= fun records ->
  if List.exists is_www records
  then Lwt_io.printl ("Domain "^domain_name^" has www!")
  else  DO.add_CNAME domain_name ~domain:"www" ~host:"@"
        >>= fun _ ->
        Lwt_io.printl ("Www added to "^domain_name^"!")

let add_all () : unit Lwt.t =
  DO.domains ()
  |> Lwt_stream.iter_p
       (fun ({ Responses.name = domain_name; _ } : Responses.domain) ->
        do_add domain_name)

let do_remove domain_name : unit Lwt.t =
  DO.domain_records domain_name
  |> Lwt_stream.iter_p 
       (function
         | Records.CNAME { Records.domain = "www"; id; _ }
         | Records.A {Records.domain = "www"; id; _ } ->
            Lwt_io.printl ("Www exists for "^domain_name^"! Removing...")
            >>= fun () ->
            DO.delete_record domain_name id
            >>= fun _ ->
            return ()
         | _ -> return ())

let remove_all () : unit Lwt.t =
  DO.domains ()
  |> Lwt_stream.iter_p
       (fun ({ Responses.name = domain_name; _ } : Responses.domain) ->
        do_remove domain_name)

let domain_opt =
  Cmdliner.Arg.(value @@ opt_all string [] @@ info ["DOMAIN"])

let add (domains : string list) =
  match domains with
  | [] -> add_all ()
  | _ -> Lwt_list.iter_p do_add domains

let add_cmd =
  Cmdliner.Term.(pure add $ domain_opt)

let remove (domains : string list) =
  match domains with
  | [] -> remove_all ()
  | _ -> Lwt_list.iter_p do_remove domains

let remove_cmd =
  Cmdliner.Term.(pure remove $ domain_opt)

let cmd = Cmdliner.Term.eval_choice
            (add_cmd, Cmdliner.Term.info "add")
            [add_cmd, Cmdliner.Term.info "add";
             remove_cmd, Cmdliner.Term.info "remove"]

let () =
  cmd
  |> function
    | `Ok main -> Lwt_main.run main
    | _ -> ()
