(*

  Copyright (C) 2004�Swiss Federal Institute of Technology Lausanne (EPFL),
  Laboratory of Audiovisual Communications (LCAV) and 
  Laboratory for Computer Communications and Applications (LCA), 
  CH-1015 Lausanne, Switzerland

  Author: Henri Dubois-Ferriere 

  This file is part of mws (multihop wireless simulator).

  Mws is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  
  Mws is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with mws; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


*)



(** 
  "Cheat" MAC Layer: A MAC layer which does not take into account connectivity
  range or neighborhood. Using the "cheat" MAC, one can directly send a packet
  to any node, anywhere in the network. 
  This behavior only applies to unicast packets; broadcast packets are
  received only by nodes within connectivity range.

  This MAC layer also does not model any collisions or losses; only
  transmission delay is applied.
*)


open Ether
open L2pkt
open Printf 

class cheatmac ?(stack=0) theowner : Mac.t = 
object(s)


  inherit Mac_null.nullmac ~stack theowner as super
  initializer (
    s#set_objdescr ~owner:(theowner :> Log.inheritable_loggable)  "/cheatmac";
  )

  method xmit ~l2pkt = (
    s#log_debug (lazy "TX packet ");
    
    match L2pkt.l2dst ~pkt:l2pkt with 
      | L2pkt.L2_BCAST ->
	  SimpleEther.emit ~stack ~nid:theowner#id l2pkt
      | L2pkt.L2_DST dstid ->
	  let dstnode = (Nodes.node(dstid)) in
	  let recvtime = 
	    Time.get_time()
	    +. propdelay 
	      ((World.w())#nodepos dstid)
	      ((World.w())#nodepos theowner#id) in
	  let recv_event() = 
	    (dstnode#mac ~stack ())#recv ~l2pkt:(L2pkt.clone_l2pkt ~l2pkt:l2pkt) () in
	  (Sched.s())#sched_at ~f:recv_event ~t:(Scheduler.Time recvtime)
  )
end 
      
    
    