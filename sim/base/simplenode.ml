(*
 *
 *  Fake - a network simulator
 *  Henri Dubois-Ferriere, LCA/LCAV, EPFL
 * 
 *  Copyright (C) 2004 Laboratory of Audiovisual Communications (LCAV), and
 *  Laboratory for Computer Communications and Applications (LCA), 
 *  Ecole Polytechnique Federale de Lausanne (EPFL),
 *  CH-1015 Lausanne, Switzerland
 *
 *  This file is part of fake. Fake is free software; you can redistribute it 
 *  and/or modify it under the terms of the GNU General Public License as 
 *  published by the Free Software Foundation; either version 2 of the License,
 *  or (at your option) any later version. 
 *
 *  Fake is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 *  details (enclosed in the file GPL). 
 *
 *)

(* $Header$ *)



(* Mar03
   wierd: decrementing shopcount when packet not sent seems necessary, 
   ie omission was a bug, but not sure if it changes anything.
   anyway current solution is a bit of a quick hack 
   May03
   maybe this is due to the fact that ttl does not appear to be corrected
   either - should be looked into.
*)






open Printf
open Misc
open Ether

let max_nstacks = 8

type node_state_t = Coord.coordf_t

exception Mac_Send_Failure

class simplenode id   = 

object(s)
  
  inherit Log.inheritable_loggable 

  val mutable pktin_mhooks = Array.make max_nstacks []
  val mutable pktout_mhooks = Array.make max_nstacks []
  val mutable macs = Array.make max_nstacks (None : Mac.t option)
  val mutable rt_agents = Array.make max_nstacks (None : Rt_agent.t option)

  val id = id

  initializer (
    s#set_objdescr (sprintf "/node/%d" id);
    s#log_debug (lazy (sprintf "New node %d" id));
  )

  method id = id

  method mac ?(stack=0) () = o2v macs.(stack)

  method install_mac ?(stack=0) themac = 
    if (macs.(stack) <> None) then 
      failwith "Simplenode.install_mac: mac already there!";
    macs.(stack) <- Some themac

  method remove_mac ?(stack=0) () = 
    macs.(stack) <- None

  method remove_stack ?(stack=0) () = 
    s#remove_mac ~stack ();
    s#remove_rt_agent ~stack ()

  method install_rt_agent ?(stack=0) (theagent : Rt_agent.t)  = 
    if (rt_agents.(stack) <> None) then 
      failwith "Simplenode.install_rt_agent: agent already there!";
    rt_agents.(stack) <- Some theagent

  method agent ?(stack=0) () = o2v rt_agents.(stack)

  method remove_rt_agent ?(stack=0) () = 
    rt_agents.(stack) <- None


  method mac_recv_pkt ?(stack=0) l2pkt = (
    
    let l3pkt  = (L2pkt.l3pkt l2pkt) in

    s#log_debug (lazy (sprintf "Pkt received from source %d" 
      (L3pkt.l3src ~l3pkt:(L2pkt.l3pkt l2pkt))));

    (* mhook called before shoving packet up the stack, because 
       it should not rely on any ordering *)
    List.iter 
      (fun mhook -> mhook l2pkt s)
      pktin_mhooks.(stack);
    
    Array.iter 
      (Opt.may (fun agent -> agent#mac_recv_l3pkt l3pkt))
      rt_agents;
    
    Array.iter 
      (Opt.may (fun agent -> agent#mac_recv_l2pkt l2pkt))
      rt_agents 
  )
    
  method add_pktin_mhook ?(stack=0) f =
    pktin_mhooks.(stack) <- f::pktin_mhooks.(stack)
      
  method add_pktout_mhook ?(stack=0) f =
    pktout_mhooks.(stack) <- f::pktout_mhooks.(stack)
      
  method clear_pkt_mhooks ?(stack=0) () = (
    pktout_mhooks.(stack) <- [];
    pktin_mhooks.(stack) <- []
  )

  method private send_pkt_ ?(stack=0) ~l3pkt dstid = (
    (* this method only exists to factor code out of 
       mac_send_pkt and cheat_send_pkt *)

    let dst = (Nodes.node(dstid)) in

    assert (L3pkt.l3ttl ~l3pkt:l3pkt >= 0);

    let l2pkt = L2pkt.make_l2pkt ~srcid:id ~l2_dst:(L2pkt.L2_DST dst#id)
      ~l3pkt:l3pkt in

    List.iter 
      (fun mhook -> mhook l2pkt s)
      pktout_mhooks.(stack);
    
    (s#mac ~stack ())#xmit ~l2pkt
  )

  method mac_send_pkt ?(stack=0) ~dst l3pkt  = (
    if not ((World.w())#are_neighbors s#id dst) then (
	s#log_notice (lazy (Printf.sprintf "mac_send_pkt: %d not a neighbor." dst));
	raise Mac_Send_Failure
      ) else
	s#send_pkt_ ~stack ~l3pkt:l3pkt dst
  )
    
  method cheat_send_pkt ?(stack=0) ~dst l3pkt = s#send_pkt_ ~l3pkt:l3pkt dst

  method mac_bcast_pkt ?(stack=0) l3pkt = (

    assert (L3pkt.l3ttl ~l3pkt:l3pkt >= 0);

    let l2pkt = L2pkt.make_l2pkt ~srcid:id ~l2_dst:L2pkt.L2_BCAST
      ~l3pkt:l3pkt in

    List.iter 
    (fun mhook -> mhook l2pkt s )
      pktout_mhooks.(stack);

(*    Printf.printf "\ngot a bcast on stack %d\n" stack;*)
    (s#mac ~stack ())#xmit ~l2pkt;
  )

  method set_trafficsource ~gen ~dst = 
    match gen() with
      | Some time_to_next_pkt ->
	  let next_pkt_event() = s#trafficsource gen dst in
	  (Sched.s())#sched_in ~f:next_pkt_event ~t:time_to_next_pkt
      | None -> ()
	  
  method private trafficsource gen dst = 
    s#originate_app_pkt ~dst;
    (* when gen() returns None, this trafficsource is done sending *)
    match gen() with
      | Some time_to_next_pkt ->
	  let next_pkt_event() = s#trafficsource gen dst in
	  (Sched.s())#sched_in ~f:next_pkt_event ~t:time_to_next_pkt
      | None -> ()
      
  method originate_app_pkt ~dst = 
    Array.iter 
      (Opt.may (fun agent -> agent#app_recv_l4pkt `APP_PKT dst))
      rt_agents 

  method dump_state = (World.w())#nodepos id


end









(*
method next_position ~node ~mob = (
    match mob with
      | RANDOMWALK -> 
	  s#reflect_ (
	    node#pos +++. ([|Random.float 2.0; Random.float 2.0|] ---. [|1.0; 1.0|])
	  )
      | WAYPOINT -> raise Misc.Not_Implemented
  )
  *)
