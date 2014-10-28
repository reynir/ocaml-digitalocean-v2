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

let is_paginated (r : Yojson.Safe.json) : bool =
  match Responses.paginated_of_yojson r with
  | `Error _ -> false
  | `Ok _ -> true

let next_page (r : Yojson.Safe.json) : string option =
  match Responses.paginated_of_yojson r with
  | `Error s -> failwith s
  | `Ok { Responses.links =
            { Responses.pages =
                { Responses.next } } } ->
     next

let mk_url ?query:(query=[]) ~resource : Uri.t =
  Uri.make ~scheme:"https"
           ~host:"api.digitalocean.com"
           ~path:("/v2/" ^ resource)
           ~query
           ()

module Make (Token : Token.AUTH_TOKEN) =
  struct
    open Token

    let get ?headers:h ~url =
      let headers = (match h with
        | None -> Cohttp.Header.init ()
        | Some h -> h) in
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      Cohttp_lwt_unix.Client.get ~headers url

    let actions () : Responses.action Lwt_stream.t =
      let rec loop url : Responses.action list my_stream =
        Next (fun () ->
              get url >>= json_of_response
              >>= fun json ->
              let xs = Responses.((or_die actions_of_yojson json).actions) in
              match next_page json with
              | Some url ->
                 return (Some xs, (loop (Uri.of_string url)))
              | None -> return (Some xs, End))
      in Lwt_stream.flatten (lwt_stream_of_my_stream (loop (mk_url "actions")))

    let actions_list () = Lwt_stream.to_list (actions ())

    let droplets () =
      get (mk_url "droplets")
  end
