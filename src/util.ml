open Lwt
open Lwt_io

let get_token : (module Token.AUTH_TOKEN) Lwt.t =
  let%lwt inc = open_file ~mode:Input "token" in
  let%lwt token = read_line inc in
  let%lwt () = close inc in
  return (module struct let token = token end
                 : Token.AUTH_TOKEN)

let string_of_response ((resp, body) : Cohttp.Response.t * Cohttp_lwt_body.t)
    : string Lwt.t =
  Cohttp_lwt_body.to_string body

let eprintl_bad_response (msg, json) : unit Lwt.t =
  let open Lwt in
  Lwt_io.eprintlf "Bad response: %s" msg >>
  Lwt_io.eprintlf "Json: %s" (Yojson.Safe.pretty_to_string json)
