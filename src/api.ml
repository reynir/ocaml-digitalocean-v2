open Lwt

let mk_url ?query:(query=[]) ~resource : Uri.t =
  Uri.make ~scheme:"https"
           ~host:"api.digitalocean.com"
           ~path:("/v2/" ^ resource)
           ~query
           ()

module Make (Token : Token.AUTH_TOKEN) =
  struct
    module M = Methods.Make(Token)

    let actions () : Responses.action Lwt_stream.t =
      M.paginated (fun json ->
                   Responses.((or_die actions_of_yojson json).actions))
                  (mk_url "actions")

    let actions_list () = Lwt_stream.to_list (actions ())

    let droplets () =
      M.paginated
        (fun json ->
         Responses.((or_die droplets_of_yojson json).droplets))
        (mk_url "droplets")

    let domains () =
      M.paginated
        (fun json ->
         Responses.((or_die domains_of_yojson json).domains))
        (mk_url "domains")

    let domain_records (domain : string)  =
      M.paginated
        (fun json ->
         Responses.((or_die domain_records_of_yojson json).domain_records)
         |> List.map Records.record_of_domain_record)
        (mk_url ("domains/"^domain^"/records"))

    let add_CNAME domain_name ~domain ~host =
      M.post_json (mk_url ("domains/" ^ domain_name ^ "/records"))
                  (`Assoc ["type", `String "CNAME";
                           "name", `String domain;
                           "data", `String host;])
      >>= M.json_of_response
      >|= fun json ->
          Responses.((or_die domain_record_wrapper_of_yojson json).domain_record)
          |> Records.record_of_domain_record

    let delete_record domain_name id =
      M.delete (mk_url ("domains/"^domain_name^"/records/"^string_of_int id))
  end
