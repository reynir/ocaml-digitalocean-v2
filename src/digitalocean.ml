open Lwt

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

module Make (Token : Token.AUTH_TOKEN) =
  struct
    open Token

    let mk_url ?query:(query=[]) ~resource : Uri.t =
      Uri.make ~scheme:"https"
               ~host:"api.digitalocean.com"
               ~path:("/v2/" ^ resource)
               ~query
               ()

    let get ?headers:h ~url =
      let headers = (match h with
        | None -> Cohttp.Header.init ()
        | Some h -> h) in
      let headers = Cohttp.Header.add headers "Authorization" ("Bearer "^token) in
      Cohttp_lwt_unix.Client.get ~headers url

    let actions =
      get (mk_url ~query:(["per_page", ["2"]; "page", ["2"]])
                    ~resource:"actions")
      >>= Util.string_of_response
      >>= fun s ->
      Yojson.Safe.from_string s
      |> Responses.actions_of_yojson
      |> Responses.or_die
      |> return

    let actions_all =
      let rec loop url =
        get url
        >>= Util.json_of_response
        >>= fun json ->
        let xs = match Responses.actions_of_yojson json with
          | `Error s -> failwith s
          | `Ok { Responses.actions } -> actions in
        match next_page json with (* /actions is always paginated *)
        | Some url ->
           loop (Uri.of_string url) >|= (@) xs
        | None -> return xs
      in loop (mk_url ~query:[] ~resource:"actions")

    let droplets =
      get (mk_url "droplets")
  end
