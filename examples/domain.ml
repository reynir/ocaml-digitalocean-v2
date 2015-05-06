open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let domain = "home.sweet.home.reyn.ir"

let delete domain () =
  DO.delete_domain domain >>
  Lwt_io.printl "Deleted domain!"

let create domain address () =
  let%lwt json = DO.add_domain domain address in
  Lwt_io.printl (Yojson.Safe.pretty_to_string json)

let s idx docv =
  Cmdliner.Arg.(required @@ pos idx (some string) None @@ info [] ~docv)

let delete = Cmdliner.Term.(
    pure delete $ s 0 "DOMAIN"
  )

let create = Cmdliner.Term.(
    pure create $ s 0 "DOMAIN" $ s 1 "ADDRESS"
  )

let cmds = Cmdliner.Term.([delete, info "delete"; create, info "create"])

let usage () =
  Lwt_io.printl "TODO: usage"

let default = Cmdliner.Term.(pure usage, info "domain")

let () = 
  match Cmdliner.Term.eval_choice default cmds with
  | `Ok main ->
    Lwt_main.run
      begin try%lwt
        main ()
        with Responses.Bad_response (err, json) ->
          Lwt_io.eprintlf "Bad_response: %s" err >>
          Lwt_io.eprintlf "JSON: %s" (Yojson.Safe.pretty_to_string json) >>
          exit 1
      end
  | _ -> ()
