open Lwt
open Lwt_io

let get_token : string Lwt.t =
  lwt inc = open_file ~mode:Input "token" in
    lwt token = read_line inc in
    lwt () = close inc in
    return token

let string_of_response ((resp, body) : Cohttp.Response.t * Cohttp_lwt_body.t)
    : string Lwt.t =
  Cohttp_lwt_body.to_string body

