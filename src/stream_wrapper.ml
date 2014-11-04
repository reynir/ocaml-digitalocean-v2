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
