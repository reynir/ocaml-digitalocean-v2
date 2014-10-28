exception Bad_response of (string * Yojson.Safe.json)

let or_die parse json = match parse json with
  | `Error error_msg -> raise (Bad_response (error_msg, json))
  | `Ok res -> res

type pages = {
  first : string option [@default None];
  next : string option [@default None];
  prev : string option [@default None];
  last : string option [@default None];
} [@@deriving yojson]

type links = {
  pages : pages;
} [@@deriving yojson { strict = false }]

type paginated = {
  links : links;
  meta : Yojson.Safe.json;
} [@@deriving yojson { strict = false }]

type action = Yojson.Safe.json
[@@deriving yojson]

type actions = {
  actions : action list;
} [@@deriving yojson { strict = false }]
