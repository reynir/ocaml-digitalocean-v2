open Lwt

module type TOKEN =
  sig
    val token : string
  end

module Make (Token : TOKEN) =
  struct
    open Token

    let make_url ~query ~resource : Uri.t =
      Uri.make ~scheme:"https"
               ~host:"api.digitalocean.com"
               ~path:("/v2/" ^ resource)
               ~query
               ()

    let get ?headers:h ?query:(query=[]) resource =
      let headers = (match h with
        | None -> Cohttp.Header.init ()
        | Some h -> h) in
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      Cohttp_lwt_unix.Client.get ~headers (make_url ~query ~resource)

    let actions =
      get ~query:(["per_page", ["10"]; "page", ["2"]])
          "actions"

    let droplets =
      get "droplets"
  end
