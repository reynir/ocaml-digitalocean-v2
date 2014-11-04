open Lwt

module DO = Api.Make((val (Lwt_main.run Util.get_token)))

let is_www = function
  | Records.CNAME { Records.domain = "www"; _ }
  | Records.A { Records.domain = "www"; _ } ->
     true
  | _ -> false

let add () : unit Lwt.t =
  DO.domains ()
  |> Lwt_stream.iter_p
       (fun ({ Responses.name = domain_name; _ } : Responses.domain) ->
        DO.domain_records domain_name |> Lwt_stream.to_list
        >>= fun records ->
        if List.exists is_www records
        then Lwt_io.printl ("Domain "^domain_name^" has www!")
        else  DO.add_CNAME domain_name ~domain:"www" ~host:"@"
              >>= Util.string_of_response
              >>= Lwt_io.printl
              >>= fun () ->
              Lwt_io.printl ("Www added to "^domain_name^"!"))

let remove () : unit Lwt.t =
  DO.domains ()
  |> Lwt_stream.iter_p
       (fun ({ Responses.name = domain_name; _ } : Responses.domain) ->
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
               | _ -> return ()))

let main () : unit Lwt.t =
  add ()

let () = Lwt_main.run @@ main ()
