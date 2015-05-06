open Lwt

let mk_url ?query:(query=[]) ~resource : Uri.t =
  Uri.make ~scheme:"https"
    ~host:"api.digitalocean.com"
    ~path:("/v2/" ^ resource)
    ~query
    ()

let (/) a b = a ^ "/" ^ b

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

  let images ?typ ?(privat=false) () =
    let url = match typ with
      | None -> mk_url ~query:["private", [string_of_bool privat]] ~resource:"images"
      | Some s -> mk_url ~query:["type", [s]] ~resource:"images"
        in
    M.paginated
      (fun json ->
         Responses.((or_die images_of_yojson json).images))
      url

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
      (mk_url ("domains" / domain / "records"))

  let add_domain domain address =
    let data = `Assoc ["name", `String domain; "ip_address", `String address] in
    M.post_json (mk_url "domains") data

  let delete_domain domain =
    M.delete (mk_url ("domains"/domain))

  let add_CNAME domain_name ~domain ~host =
    let data = `Assoc ["type", `String "CNAME";
                       "name", `String domain;
                       "data", `String host;] in
    let url = mk_url ("domains" / domain_name / "records") in
    let%lwt json = M.post_json url data in
    Responses.((or_die domain_record_wrapper_of_yojson json).domain_record)
    |> Records.record_of_domain_record
    |> Lwt.return

  let add_A domain_name ~domain ~address =
    let data = `Assoc ["type", `String "A";
                       "name", `String domain;
                       "data", `String address;] in
    let url = (mk_url ("domains" / domain_name / "records")) in
    let%lwt json = M.post_json url data in
    Responses.((or_die domain_record_wrapper_of_yojson json).domain_record)
    |> Records.record_of_domain_record
    |> Lwt.return

  let update_record_data domain_name id data =
    let%lwt json = M.put_json
        (mk_url ("domains" / domain_name / "records" / string_of_int id))
        (`Assoc ["data", `String data])  in
    Responses.((or_die domain_record_wrapper_of_yojson json).domain_record)
    |> Records.record_of_domain_record
    |> Lwt.return

  let delete_record domain_name id =
    M.delete (mk_url ("domains" / domain_name / "records" / string_of_int id))
end
