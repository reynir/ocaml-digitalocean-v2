type number = Responses.number
[@@deriving show]
                
type rA = {
  id : number;
  domain : string;
  ipv4 : string;
} [@@deriving show]
type rAAAA = {
  id : number;
  domain : string;
  ipv6 : string;
} [@@deriving show]
type rCNAME = {
  id : number;
  domain : string;
  host : string;
} [@@deriving show]
type rMX = {
  id : number;
  domain : string;
  exchange : string;
  preference : int;
} [@@deriving show]
type rTXT = {
  id : number;
  name : string;
  data : string;
} [@@deriving show]
type rSRV = {
  id : number;
  domain : string;
  target : string;
  port : number;
  weight : number;
  priority : number;
} [@@deriving show]
type rNS = {
  id : number;
  domain : string;
  host : string;
} [@@deriving show]

type record =
  | A of rA
  | AAAA of rAAAA
  | CNAME of rCNAME
  | MX of rMX
  | TXT of rTXT
  | SRV of rSRV
  | NS of rNS
[@@deriving show]

exception Bad_record of Responses.domain_record

let record_of_domain_record =
  function
  | { Responses.typ = "A"; id; name; data; _ } ->
     A { id; domain = name; ipv4 = data }
  | { Responses.typ = "AAAA"; id; name; data; _ } ->
     AAAA { id; domain = name; ipv6 = data }
  | { Responses.typ = "CNAME"; id; name; data; _ } ->
     CNAME { id; domain = name; host = data }
  | { Responses.typ = "MX"; id; name; data; priority = Some p } ->
     MX { id; domain = name; exchange = data; preference = p }
  | { Responses.typ = "TXT"; id; name; data; _ } ->
     TXT { id; name; data }
  | { Responses.typ = "SRV"; id; name; data;
      port = Some port; priority = Some priority;
      weight = Some weight; } ->
     SRV { id; domain = name; target = data; port; priority; weight }
  | { Responses.typ = "NS"; id; name; data; _ } -> 
     NS { id; domain = name; host = data; }
  | r -> raise (Bad_record r)
