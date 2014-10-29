exception Bad_response of (string * Yojson.Safe.json)

let or_die parse json = match parse json with
  | `Error error_msg -> raise (Bad_response (error_msg, json))
  | `Ok res -> res

(** Some common types **)
(* The type 'number' seems to always be an integer *)
type number = int
[@@deriving yojson]

(* "object" in the documentation *)
type objekt = Yojson.Safe.json
[@@deriving yojson]

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

type action = {
  id : number;
  status : string;
  typ [@key "type"] : string;
  started_at : string;
  completed_at : string;
  resource_id : number option;
  region : string option;
} [@@deriving yojson { strict = false }]

type actions = {
  actions : action list;
} [@@deriving yojson { strict = false }]

type droplet = {
  id : number;
  name : string;
  memory : number;
  vcpus : number;
  disk : number;
  region : objekt;
  image : objekt;
  kernel : objekt;
  size_slug : string;
  locked : bool;
  created_at : string;
  status : string;
  networks : objekt;
  (* making assumptions on the element types *)
  backup_ids : number list;
  snapshot_ids : number list;
  features : string list;
}
[@@deriving yojson { strict = false }]

type droplets = {
  droplets : droplet list;
} [@@deriving yojson { strict = false }]
