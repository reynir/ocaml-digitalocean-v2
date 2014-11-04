open Lwt

type 'a my_stream = Next of (unit -> ('a option * 'a my_stream) Lwt.t)
                  | End

let lwt_stream_of_my_stream (s : 'a my_stream) : 'a Lwt_stream.t =
  let next = ref s in
  Lwt_stream.from
    (fun () ->
     match !next with
     | End -> return None
     | Next f ->
        f ()
        >>= function
          | (x, s') ->
             next := s';
             return x)

let json_of_response ((resp, body) : Cohttp.Response.t * Cohttp_lwt_body.t)
    : Yojson.Safe.json Lwt.t =
  Cohttp_lwt_body.to_string body
  >|= Yojson.Safe.from_string

let next_page (json : Yojson.Safe.json) : string option =
  let open Responses in
  match paginated_of_yojson json with
  | `Error _ -> None
  | `Ok { links = { pages = { next } } } -> next

let mk_url ?query:(query=[]) ~resource : Uri.t =
  Uri.make ~scheme:"https"
           ~host:"api.digitalocean.com"
           ~path:("/v2/" ^ resource)
           ~query
           ()

module Make (Token : Token.AUTH_TOKEN) =
  struct
    open Token

    let check_response ((resp, body) : Cohttp_lwt_unix.Response.t * Cohttp_lwt_body.t) =
      let module Resp = Cohttp_lwt_unix.Response in
      let status = Cohttp_lwt_unix.Response.status resp in
      match status with
      | `OK -> return ()
      | _ -> let status_string = Cohttp.Code.string_of_status status in
             Printf.fprintf stderr "Error code: %s\n" status_string;
             json_of_response (resp, body)
             >>= fun json ->
             raise @@ Responses.Bad_response
                        (Printf.sprintf "Error code %s" status_string,
                         json)

    let get ?headers:(headers=Cohttp.Header.init ()) ~url =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let res = Cohttp_lwt_unix.Client.get ~headers url in
      res >>= check_response >>= fun () -> res

    let post ?headers:(headers=Cohttp.Header.init ()) ~url ~data =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let body = Cohttp_lwt_body.of_string data in
      let res = Cohttp_lwt_unix.Client.post ~body ~headers url in
      res >>= check_response >>= fun () -> res

    let post_json ?headers:(headers=Cohttp.Header.init ()) ~url ~json =
      let headers = Cohttp.Header.add headers "Content-Type" "application/json" in
      let data = Yojson.Safe.to_string json in
      let res = post ~headers ~url ~data in
      res >>= check_response >>= fun () -> res

    let delete ?headers:(headers=Cohttp.Header.init ()) ~url =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let headers =
        Cohttp.Header.add headers
                          "Content-Type" "application/x-www-form-urlencoded" in
      let res = Cohttp_lwt_unix.Client.delete ~headers url in
      res >>= check_response >>= fun () -> res

    let paginated (parse : Yojson.Safe.json -> 'a list) url : 'a Lwt_stream.t =
      let rec loop url : 'a list my_stream =
        Next (fun () ->
              get url >>= json_of_response
              >>= fun json ->
              let xs = parse json in
              match next_page json with
                   | Some url -> return (Some xs, loop (Uri.of_string url))
                   | None -> return (Some xs, End))
      in Lwt_stream.flatten (lwt_stream_of_my_stream (loop url))

    let actions () : Responses.action Lwt_stream.t =
      paginated (fun json ->
                 Responses.((or_die actions_of_yojson json).actions))
                (mk_url "actions")

    let actions_list () = Lwt_stream.to_list (actions ())

    let droplets () =
      paginated
        (fun json ->
         Responses.((or_die droplets_of_yojson json).droplets))
        (mk_url "droplets")

    let domains () =
      paginated
        (fun json ->
         Responses.((or_die domains_of_yojson json).domains))
        (mk_url "domains")

    let domain_records (domain : string)  =
      paginated
        (fun json ->
         Responses.((or_die domain_records_of_yojson json).domain_records)
        |> List.map Records.record_of_domain_record)
        (mk_url ("domains/"^domain^"/records"))

    let add_CNAME domain_name ~domain ~host =
      post_json (mk_url ("domains/" ^ domain_name ^ "/records"))
                (`Assoc ["type", `String "CNAME";
                         "name", `String domain;
                         "data", `String host;])

    let delete_record domain_name id =
      delete (mk_url ("domains/"^domain_name^"/records/"^string_of_int id))
  end
