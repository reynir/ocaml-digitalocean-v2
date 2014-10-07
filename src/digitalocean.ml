open Lwt

module type TOKEN =
  sig
    val token : string
  end

module Make (Token : TOKEN) =
  struct
    open Token

    let make_url obj : Uri.t =
      Uri.make ~scheme:"https"
               ~host:"api.digitalocean.com"
               ~path:("/v2/" ^ obj)
               ~query:[("per_page", ["1000"])]
               ()

    let get ?headers:h ~resource =
      let headers = (match h with
        | None -> Cohttp.Header.init ()
        | Some h -> h) in
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      Cohttp_lwt_unix.Client.get ~headers (make_url resource)

    let get_actions : string Lwt.t =
      print_endline (Uri.to_string (make_url "actions"));
      get "actions"
      >>= fun (resp, body) ->
      Cohttp_lwt_body.to_string body
  end
