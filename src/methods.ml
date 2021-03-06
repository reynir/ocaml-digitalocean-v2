open Lwt

let json_of_response ((resp, body) : Cohttp.Response.t * Cohttp_lwt_body.t)
  : Yojson.Safe.json Lwt.t =
  Cohttp_lwt_body.to_string body
  >|= Yojson.Safe.from_string

let next_page (json : Yojson.Safe.json) : string option =
  let open Responses in
  match paginated_of_yojson json with
  | Error _ -> None
  | Ok { links = { pages = { next } } } -> next

let check_response ?expected:(oks=[`OK]) ((resp, body) : Cohttp_lwt_unix.Response.t
                                                         * Cohttp_lwt_body.t) =
  let status = Cohttp_lwt_unix.Response.status resp in
  if List.mem status oks
  then return_unit
  else let status_string = Cohttp.Code.string_of_status status in
    Printf.fprintf stderr "Error code: %s\n" status_string;
    let%lwt json = json_of_response (resp, body) in
    raise @@ Responses.Bad_response
      (Printf.sprintf "Error code %s" status_string,
       json)

module Make (Token : Token.AUTH_TOKEN) =
struct
  open Token

  let json_of_response = json_of_response

  let get ?expected ?headers:(headers=Cohttp.Header.init ()) ~url =
    let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
    let res = Cohttp_lwt_unix.Client.get ~headers url in
    res >>= check_response ?expected >> res >>= json_of_response

  let post ?(expected=[`Created]) ?headers:(headers=Cohttp.Header.init ()) ~url ~data =
    let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
    let body = Cohttp_lwt_body.of_string data in
    let res = Cohttp_lwt_unix.Client.post ~body ~headers url in
    res >>= check_response ~expected >> res >>= json_of_response

  let post_json ?expected ?headers:(headers=Cohttp.Header.init ()) ~url ~json =
    let headers = Cohttp.Header.add headers "Content-Type" "application/json" in
    let data = Yojson.Safe.to_string json in
    post ?expected ~headers ~url ~data

  let put ?expected ?headers:(headers=Cohttp.Header.init ()) ~url ~data =
    let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
    let body = Cohttp_lwt_body.of_string data in
    let res = Cohttp_lwt_unix.Client.put ~body ~headers url in
    res >>= check_response ?expected >> res >>= json_of_response

  let put_json ?expected ?headers:(headers=Cohttp.Header.init ()) ~url ~json =
    let headers = Cohttp.Header.add headers "Content-Type" "application/json" in
    let data = Yojson.Safe.to_string json in
    put ?expected ~headers ~url ~data

  let delete ?(expected=[`No_content]) ?headers:(headers=Cohttp.Header.init ()) ~url =
    let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
    let headers =
      Cohttp.Header.add headers
        "Content-Type" "application/x-www-form-urlencoded" in
    let res = Cohttp_lwt_unix.Client.delete ~headers url in
    res >>= check_response ~expected

  let paginated ?expected ?headers (parse: Yojson.Safe.json -> 'a list) (url : Uri.t)
    : 'a Lwt_stream.t =
    let next_url = ref (Some url) in
    let next () : 'a list option Lwt.t =
      match !next_url with
      | None -> return_none
      | Some url ->
        let%lwt json = get ?expected ?headers ~url in
        let xs = parse json in
        let () = match next_page json with
          | Some new_url -> next_url := Some (Uri.of_string new_url)
          | None -> next_url := None in
        return (Some xs) in
    Lwt_stream.from next |> Lwt_stream.flatten

end
