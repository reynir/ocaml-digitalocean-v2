open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let mxs = [
  "mx.mailstache.io.", 1;
  "mx2.mailstache.io.", 5;
  "mx3.mailstache.io.", 5;
  "mx4.mailstache.io.", 10;
  "mx5.mailstache.io.", 10;
]


let main domain () =
  Lwt_list.iter_p (fun (mx, priority) ->
      let%lwt record = DO.add_MX domain "@" mx priority in
      Lwt_io.printl (Records.show_record record))
    mxs

let domain = Cmdliner.Arg.(required @@ pos 0 (some string) None @@ info [] ~docv:"DOMAIN")

let cmd = Cmdliner.Term.(pure main $ domain)

let info = Cmdliner.Term.(
    info ~doc:"Adds dns records required for mailstace.io" "mailstache"
  )

let () = match Cmdliner.Term.eval (cmd, info) with
  | `Ok main ->
    Lwt_main.run begin
      try%lwt main ()
      with Responses.Bad_response e ->
        Util.eprintl_bad_response e >> exit 1
    end
  | _ -> ()
