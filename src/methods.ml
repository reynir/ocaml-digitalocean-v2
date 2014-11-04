open Lwt

let json_of_response ((resp, body) : Cohttp.Response.t * Cohttp_lwt_body.t)
    : Yojson.Safe.json Lwt.t =
  Cohttp_lwt_body.to_string body
  >|= Yojson.Safe.from_string

let next_page (json : Yojson.Safe.json) : string option =
  let open Responses in
  match paginated_of_yojson json with
  | `Error _ -> None
  | `Ok { links = { pages = { next } } } -> next

let check_response ?expected:(oks=[`OK]) ((resp, body) : Cohttp_lwt_unix.Response.t
                                                   * Cohttp_lwt_body.t) =
  let status = Cohttp_lwt_unix.Response.status resp in
  if List.mem status oks
  then return ()
  else let status_string = Cohttp.Code.string_of_status status in
       Printf.fprintf stderr "Error code: %s\n" status_string;
       json_of_response (resp, body)
       >>= fun json ->
       raise @@ Responses.Bad_response
                  (Printf.sprintf "Error code %s" status_string,
                   json)

module Make (Token : Token.AUTH_TOKEN) =
  struct
    open Token

    let json_of_response = json_of_response

    let get ?headers:(headers=Cohttp.Header.init ()) ~url =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let res = Cohttp_lwt_unix.Client.get ~headers url in
      res >>= check_response >>= fun () -> res

    let post ?headers:(headers=Cohttp.Header.init ()) ~url ~data =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let body = Cohttp_lwt_body.of_string data in
      let res = Cohttp_lwt_unix.Client.post ~body ~headers url in
      res >>= check_response ~expected:[`Created] >>= fun () -> res

    let post_json ?headers:(headers=Cohttp.Header.init ()) ~url ~json =
      let headers = Cohttp.Header.add headers "Content-Type" "application/json" in
      let data = Yojson.Safe.to_string json in
      post ~headers ~url ~data

    let delete ?headers:(headers=Cohttp.Header.init ()) ~url =
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      let headers =
        Cohttp.Header.add headers
                          "Content-Type" "application/x-www-form-urlencoded" in
      let res = Cohttp_lwt_unix.Client.delete ~headers url in
      res >>= check_response ~expected:[`No_content] >>= fun () -> res

    let paginated (parse : Yojson.Safe.json -> 'a list) url : 'a Lwt_stream.t =
      let open Stream_wrapper in
      let rec loop url : 'a list my_stream =
        Next (fun () ->
              get url >>= json_of_response
              >>= fun json ->
              let xs = parse json in
              match next_page json with
              | Some url -> return (Some xs, loop (Uri.of_string url))
              | None -> return (Some xs, End))
      in Lwt_stream.flatten (lwt_stream_of_my_stream (loop url))

  end
