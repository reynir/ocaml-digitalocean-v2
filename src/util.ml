open Lwt
open Lwt_io

let get_token : string Lwt.t =
  lwt inc = open_file ~mode:Input "token" in
    lwt token = read_line inc in
    lwt () = close inc in
    return token
