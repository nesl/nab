open Misc 

let _DEFAULT_HELLO_PERIOD = 10.
let _HELLO_JITTER_INTERVAL() = _DEFAULT_HELLO_PERIOD /. 5.
let _ERS_START_TTL = 2
let _ERS_MULT_FACT = 2
let _ERS_MAX_TTL = 64

let  xmitdelay ~bytes ~bps = (i2f (bytes * 8)) /. bps


(* we say that maximum 1-hop traversal is 20ms, 
   ie half of value used by AODV. Another difference relative to AODV
   is that we use ttl, not (ttl + 2).
   This is ok while we use a simple MAC, and ok since our AODV impl 
   will use the same values*)
  
let hop_traversal_time bps = 
  max 0.2
  ((Param.get Params.rrange) /. Ether.speed_of_light
  +.xmitdelay ~bytes:2000 ~bps)


let next_rreq_ttl ttl = 
  min _ERS_MAX_TTL (ttl*_ERS_MULT_FACT) 
