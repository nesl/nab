




type time_t = float

(* Time *)
let time_ = ref 0.0
let set_time t = time_ := t
let get_time () = !time_
let time = get_time