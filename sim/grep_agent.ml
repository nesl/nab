(* should send_out distinguish exceptions between no nexthop and xmit failure ?*)
(* when we get a rrep, do we also update route to replying node (if different
   from destination node)?? we should. *)
(* 19may / removed code in simplenode that decrs shopcount when bcast has no
   neighbors. should check throughout grep_agent that there are no places
   where we reuse a packet, and where it would be necessary to correct a
   needlessly changed (ttl or hopcount) field *)

(*                                  *)
(* mws  multihop wireless simulator *)
(*                                  *)


open Printf
open Misc

let packet_buffer_size = 50

class type grep_agent_t =
  object
    method private app_send : L4pkt.l4pkt_t -> dst:Common.nodeid_t -> unit
    method private buffer_packet : l3pkt:L3pkt.l3packet_t -> unit
    method private hand_upper_layer : l3pkt:L3pkt.l3packet_t -> unit
    method private incr_seqno : unit -> unit
    method private inv_packet_upwards :
      nexthop:Common.nodeid_t -> l3pkt:L3pkt.l3packet_t -> unit
    method private inv_ttl_zero : l3pkt:L3pkt.l3packet_t -> unit
    method newadv : 
      dst:Common.nodeid_t -> 
      rtent:Rtab.rtab_entry_t ->
      ?ignorehops:bool -> 
      unit -> bool
    method objdescr : string
    method private packet_fresh : l3pkt:L3pkt.l3packet_t -> bool
    method private queue_size : unit -> int
    method private packets_waiting : dst:Common.nodeid_t -> bool
    method private process_data_pkt : l3pkt:L3pkt.l3packet_t -> unit
    method private process_radv_pkt :
      l3pkt:L3pkt.l3packet_t -> 
      sender:Common.nodeid_t -> unit
    method private process_rrep_pkt :
      l3pkt:L3pkt.l3packet_t -> 
      sender:Common.nodeid_t -> unit
    method private process_rreq_pkt :
      l3pkt:L3pkt.l3packet_t -> 
      fresh:bool -> unit
    method private newadv_rrep :
      adv:L4pkt.grep_adv_payload_t ->
      sender:Common.nodeid_t -> 
      shopcount:int -> bool
    method private recv_l2pkt_hook : L2pkt.l2packet_t -> unit
    method private send_out : l3pkt:L3pkt.l3packet_t -> unit
    method private send_rrep : dst:Common.nodeid_t -> obo:Common.nodeid_t -> unit
    method private send_rreq :
      ttl:int -> dst:Common.nodeid_t -> dseqno:int -> dhopcount:int -> unit
    method private send_waiting_packets : dst:Common.nodeid_t -> unit
  end


exception Send_Out_Failure


let agents_array = ref ([||]:grep_agent_t array)

let set_agents arr = agents_array := arr
let agent i = !agents_array.(i)


let _ERS_START_TTL = 2
let _ERS_MULT_FACT = 2


class grep_agent owner : grep_agent_t = 
object(s)

  inherit Log.loggable

  val owner:Simplenode.simplenode = owner
  val rtab = Rtab.create ~size:(Param.get Params.nodes) 
  val mutable seqno = 0
  val pktqs = Array.init (Param.get Params.nodes) (fun n -> Queue.create()) 

  initializer (
    objdescr <- (owner#objdescr ^  "/GREP_Agent");
    owner#add_recv_l2pkt_hook ~hook:s#recv_l2pkt_hook;
    owner#add_app_send_pkt_hook ~hook:s#app_send;
    s#incr_seqno()
  )

  method private incr_seqno() = (
    seqno <- seqno + 1;
    let update = 
      Rtab.newadv 
	~rt:rtab 
	~dst:owner#id
	~rtent:{
	  Rtab.seqno = Some seqno;
	  Rtab.hopcount = Some 0;
	  Rtab.nexthop = Some owner#id}
    in 
    assert(update);
  )

  method private packets_waiting ~dst = 
    not (Queue.is_empty pktqs.(dst))

  method private queue_size() = 
    Array.fold_left (fun n q -> n + (Queue.length q))  0 pktqs

  method private send_waiting_packets ~dst = 
    while s#packets_waiting ~dst do
      let pkt = (Queue.pop pktqs.(dst)) in
	try 
(*	  s#log_info 
	    (sprintf "Sending buffered DATA pkt from src %d to dst %d."
	      (L3pkt.l3src ~l3pkt:pkt) dst);*)
	  s#send_out ~l3pkt:pkt
	with 
	  | Send_Out_Failure -> 
	      s#log_error 
	      (lazy (sprintf "Sending buffered DATA pkt from src %d to dst %d failed, dropping"
		(L3pkt.l3src ~l3pkt:pkt) dst));
    done

  (* DATA packets are buffered when they fail on send, 
     or if there are already buffered packets for that destination *)
  method private buffer_packet ~(l3pkt:L3pkt.l3packet_t) = (
    match s#queue_size() < packet_buffer_size with 
      | true ->
	  let dst = L3pkt.l3dst ~l3pkt in
	  assert (dst != L3pkt._L3_BCAST_ADDR);
	  Queue.push l3pkt pktqs.(dst);
      | false -> (
	  Grep_hooks.drop_data();
(*	  s#log_notice (sprintf "Dropped packet for dst %d" 
	    (L3pkt.l3dst ~l3pkt))*)
	)
  )

  (* wrapper around Rtab.newadv which additionally checks for 
     open rreqs to that dest and cancels if any,
     buffered packets to that dest and sends them if any *)
  method newadv  
    ~(dst:Common.nodeid_t)
    ~(rtent:Rtab.rtab_entry_t) 
    ?(ignorehops=false)
    () = (
      let update = 
	if ignorehops then 
	  Rtab.newadv_ignorehops ~rt:rtab ~dst ~rtent:rtent
	else 
	  Rtab.newadv ~rt:rtab ~dst ~rtent:rtent
      in
      if update then (
(*	s#log_info 
	(sprintf "New route to dst %d: nexthop %d, hopcount %d, seqno %d"
	  dst 
	  (o2v rtent.Rtab.nexthop) 
	  (o2v rtent.Rtab.hopcount)
	  (o2v rtent.Rtab.seqno));*)
	(* if route to dst was accepted, send any packets that were waiting
	   for a route to this dst *)
	if (s#packets_waiting ~dst) then (
	  s#send_waiting_packets ~dst
	)
      );
      update
    )


  (* wrapper around Grep_agent.newadv for those that come in 
     radv/rrep packets *)
  (* route replies, we accept a route with same seqno even if it has more
     hops. This is to allow rreps from intermediate nodes which would have the
     same route as us but which were between us and the break. This does not
     introduce loops because an intermediate node only answers if 
     (its hopcount < packet.shopcount + packet.dhopcount).
     Therefore, a node which is 'behind' us on the route would not satisfy this.
  *)
  method private newadv_rrep
    ~(adv:L4pkt.grep_adv_payload_t)
    ~(sender:Common.nodeid_t) 
    ~(shopcount:int)  = (
      s#newadv 
      ~ignorehops:false
      ~dst:(adv.L4pkt.adv_dst)
      ~rtent:{
	Rtab.seqno = Some (adv.L4pkt.adv_seqno);
	Rtab.hopcount = Some ((adv.L4pkt.adv_hopcount) + shopcount);
	Rtab.nexthop = Some sender 
      }
      ()
    )

  (* as in paper *)
  method private packet_fresh ~l3pkt = (
    let pkt_sseqno = L3pkt.l3sseqno ~l3pkt in
    match (Rtab.seqno ~rt:rtab ~dst:(L3pkt.l3src l3pkt)) with
      | None -> true 
      | Some s when (pkt_sseqno > s) -> true
      | Some s when (pkt_sseqno = s) -> 
	  L3pkt.l3shopcount l3pkt 
	  <
	  o2v (Rtab.hopcount ~rt:rtab ~dst:(L3pkt.l3src l3pkt))
      | Some s when (pkt_sseqno < s) -> false
      | _ -> raise (Misc.Impossible_Case "Grep_agent.packet_fresh()")
  )
    
   
  (* as recv_packet in paper *)
  method private recv_l2pkt_hook l2pkt = (

    let l3pkt = L2pkt.l3pkt ~l2pkt:l2pkt in
    assert (L3pkt.l3ttl ~l3pkt >= 0);
    (* create or update 1-hop route to previous hop *)
    let sender = L2pkt.l2src l2pkt in
    if (sender != (L3pkt.l3src ~l3pkt)) then (
      let sender_seqno = 
	match Rtab.seqno ~rt:rtab ~dst:sender with
	  | None -> 1
	  | Some n -> n + 1
      in
      let update =  
	s#newadv 
	  ~dst:sender
	  ~rtent:{
	    Rtab.seqno = Some sender_seqno;
	    Rtab.hopcount = Some 1;
	    Rtab.nexthop = Some sender
	  } 
	  ()
      in
      assert (update);
    );
    (* update route to source if packet came over fresher route than what we
       have *)
    let pkt_fresh = (s#packet_fresh ~l3pkt)
    and update =  
      s#newadv 
	~dst:(L3pkt.l3src ~l3pkt)
	~rtent:{
	  Rtab.seqno = Some (L3pkt.l3sseqno ~l3pkt);
	  Rtab.hopcount = Some (L3pkt.l3shopcount ~l3pkt);
	  Rtab.nexthop = Some sender
	} 
	()
    in
    assert (update = pkt_fresh);
    
    (* hand off to per-type method private *)
    begin match L3pkt.l3grepflags ~l3pkt with
      | L3pkt.GREP_DATA -> s#process_data_pkt ~l3pkt;
      | L3pkt.GREP_RREQ -> s#process_rreq_pkt ~l3pkt ~fresh:pkt_fresh
      | L3pkt.GREP_RADV -> s#process_radv_pkt ~l3pkt ~sender;
      | L3pkt.GREP_RREP -> s#process_rrep_pkt ~l3pkt ~sender;
      | L3pkt.NOT_GREP | L3pkt.EASE 
	-> raise (Failure "Grep_agent.recv_l2pkt_hook");
      | L3pkt.GREP_RERR -> raise (Failure "Grep_agent.recv_l2pkt_hook");
    end
  ) 

  method private process_radv_pkt ~l3pkt ~sender = 
    raise Misc.Not_Implemented

  method private process_rreq_pkt ~l3pkt ~fresh = (

    let rreq = (L3pkt.grep_rreq_pkt ~l3pkt) in

(*    s#log_info 
    (sprintf "Received RREQ pkt from src %d for dst %d"
      (L3pkt.l3src ~l3pkt) 
      rreq.L3pkt.rreq_dst);*)
    match fresh with 
      | true -> 
	  let answer_rreq = 
	    (rreq.L4pkt.rreq_dst = owner#id)
	    ||
	    begin match (Rtab.seqno ~rt:rtab ~dst:rreq.L4pkt.rreq_dst) with 
	      | None -> false
	      | Some s when (s > rreq.L4pkt.dseqno) -> true
	      | Some s when (s = rreq.L4pkt.dseqno) ->
		  (o2v (Rtab.hopcount ~rt:rtab ~dst:rreq.L4pkt.rreq_dst) 
		  <
		  rreq.L4pkt.dhopcount + L3pkt.l3shopcount ~l3pkt)
	      | Some s when (s < rreq.L4pkt.dseqno) -> false
	      | _ -> raise (Misc.Impossible_Case "Grep_agent.answer_rreq()") end
	  in
	  if (answer_rreq) then 
	    s#send_rrep 
	      ~dst:(L3pkt.l3src ~l3pkt)
	      ~obo:rreq.L4pkt.rreq_dst
	  else (* broadcast the rreq further along *)
	    s#send_out ~l3pkt
      | false -> ()
(*	  s#log_info 
	  (sprintf "Dropping RREQ pkt from src %d for dst %d (not fresh)"
	    (L3pkt.l3src ~l3pkt) 
	    rreq.L3pkt.rreq_dst);*)
  )
      
  method private send_rrep ~dst ~obo = (
(*    s#log_info 
    (sprintf "Sending RREP pkt to dst %d, obo %d"
      dst obo);*)
    let adv = L4pkt.make_grep_adv_payload 
      ~adv_dst:obo
      ~adv_seqno:(o2v (Rtab.seqno ~rt:rtab ~dst:obo))
      ~adv_hopcount:(o2v (Rtab.hopcount ~rt:rtab ~dst:obo))
    in
    let l3pkt =
      L3pkt.make_grep_rrep_l3pkt 
	~rrep_payload:adv
	~l3hdr:(
	  L3pkt.make_l3hdr
	  ~srcid:owner#id
	  ~dstid:dst
	  ~ext:(L3pkt.make_grep_l3hdr_ext
	    ~flags:L3pkt.GREP_RREP
	    ~sseqno:seqno
	    ~shopcount:0
	  )
	  ~ttl:0 (* will be set by send_out *)
	  ()
	)
    in
    
    
    try 
      s#send_out  ~l3pkt
    with 
      | Send_Out_Failure -> 
	  s#log_notice 
	  (lazy (sprintf "Sending RREP pkt to dst %d, obo %d failed, dropping"
	    dst obo));
  )

  method private inv_packet_upwards ~nexthop ~l3pkt = (
    (* this expects to be called just prior to sending l3pkt
       and so assumes that ttl has already been decremented on l3pkt *)

    let agent_nexthop = agent nexthop 
    and dst = (L3pkt.l3dst ~l3pkt) in
    assert (
      (agent_nexthop#newadv
	~dst
	~rtent:{
	  Rtab.seqno = (Rtab.seqno ~rt:rtab ~dst);
	  Rtab.hopcount = Some ((L3pkt.l3ttl ~l3pkt) + 1);
	  Rtab.nexthop = Some 0 (* this rtent will be ignored anyway *)
	}
	()) = false
    )
  )
    
  method private inv_ttl_zero ~l3pkt = (
    assert ((L3pkt.l3ttl l3pkt)  = 0);
  )
    
  method private process_data_pkt 
    ~(l3pkt:L3pkt.l3packet_t) =  (
      
      if ((L3pkt.l3dst ~l3pkt) = owner#id) then (   (* for us *)
	begin match L3pkt.l3grepflags ~l3pkt with
	  | L3pkt.GREP_DATA | L3pkt.GREP_RREP -> s#inv_ttl_zero ~l3pkt
	  | _ -> raise (Misc.Impossible_Case "Grep_agent.process_data_pkt");
	end;
	s#hand_upper_layer ~l3pkt;
      ) else (
	if (s#packets_waiting ~dst:(L3pkt.l3dst ~l3pkt)) then (
	  s#buffer_packet ~l3pkt
	) else (
	  try 
	    s#send_out ~l3pkt
	  with 
	    | Send_Out_Failure -> 
		begin
		  (* taken out of simplenode#mac_send_pkt, should not be
		     there. 
		     let l3hdr = L3pkt.l3hdr l3pkt in
		     l3hdr.L3pkt.grep_shopcount <- l3hdr.L3pkt.grep_shopcount - 1;
		     probably also need to check if other fields need to be
		     set back to their proper values (esp ttl)
		  *)
		  raise (Failure "Grep_agent.process_data_pkt: fix packet");


		  let dst = (L3pkt.l3dst ~l3pkt) in
(*		  s#log_notice 
		    (sprintf "Forwarding DATA pkt to dst %d failed, buffering."
		      dst);*)
		  (* important to buffer packet first because send_rreq checks for
		     this *)
		  s#buffer_packet ~l3pkt;
		  let (dseqno,dhopcount) = 
		    begin match (Rtab.seqno ~rt:rtab ~dst) with
		      | None -> (0, max_int)
		      | Some s -> (s, o2v (Rtab.hopcount ~rt:rtab ~dst)) end
		  in
		  s#send_rreq 
		    ~ttl:_ERS_START_TTL 
		    ~dst 
		    ~dseqno:dseqno
		    ~dhopcount:dhopcount;
		end
	  )
      )
    )

  method private send_rreq ~ttl ~dst ~dseqno ~dhopcount = (
    
    if (s#packets_waiting ~dst) then (
      (* we check this as a simple way to not do a repeat rreq from a 
	 previous rreq timeout. Ie, if a rrep came in in the meantime, then we
	 sent all packets, and don't need to send a new rreq. 
	 At some point a more detailed implementation would probably need a
	 separate representation of pending rreqs to know which have been
	 satisfied, etc *)
      s#log_info (lazy (sprintf "Sending RREQ pkt for dst %d with ttl %d"
	dst ttl));
      
      let l3hdr = 
	L3pkt.make_l3hdr
	  ~srcid:owner#id
	  ~dstid:L3pkt._L3_BCAST_ADDR
	  ~ext:(L3pkt.make_grep_l3hdr_ext
	    ~flags:L3pkt.GREP_RREQ
	    ~sseqno:seqno
	    ~shopcount:0
	  )
	  ~ttl:ttl 
	  ()
      in
      let rreq_payload = 
	L4pkt.make_grep_rreq_payload
	  ~rreq_dst:dst
	  ~dseqno:dseqno 
	  ~dhopcount:dhopcount
      in
      let l3pkt = 
	L3pkt.make_grep_rreq_l3pkt 
	  ~l3hdr:l3hdr
	  ~rreq_payload:rreq_payload
      in
      let next_rreq_ttl = 
	(ttl*_ERS_MULT_FACT) in
      let next_rreq_timeout = 
	((i2f next_rreq_ttl) *. 0.02) in
      let next_rreq_event() = 
	  (s#send_rreq 
	    ~ttl:next_rreq_ttl
	    ~dst
	    ~dseqno:dseqno
	    ~dhopcount:dhopcount)
      in	

	s#send_out ~l3pkt;
	(* we say that maximum 1-hop traversal is 20ms, 
	   ie half of value used by AODV. Another difference relative to AODV
	   is that we use ttl, not (ttl + 2).
	   This is ok while we use a simple MAC, and ok since our AODV impl 
	   will use the same values*)
	
	
	if next_rreq_ttl < ((Param.get Params.nodes)/10) then
	  (Gsched.sched())#sched_in ~f:next_rreq_event ~t:next_rreq_timeout;
    )
  )
    

  method private process_rrep_pkt 
    ~(l3pkt:L3pkt.l3packet_t) 
    ~(sender:Common.nodeid_t) = (
      
      let adv = (L3pkt.grep_rrep_pkt ~l3pkt)
      in 
      let update = (s#newadv_rrep
	~adv:adv 
	~sender 
	~shopcount:(L3pkt.l3shopcount ~l3pkt))
      in 
      if ((L3pkt.l3dst ~l3pkt) != owner#id) then
	try 
	  s#send_out ~l3pkt
	with 
	  | Send_Out_Failure -> ()
(*	      s#log_notice 
	      (sprintf "Forwarding RREP pkt to dst %d, obo %d failed, dropping"
		(L3pkt.l3dst ~l3pkt) 
		(adv.L3pkt.adv_dst));*)
      else ()
    )
    
  method private send_out ~l3pkt = (
    
    let dst = L3pkt.l3dst ~l3pkt in
    assert (dst != owner#id);
    assert (L3pkt.l3ttl ~l3pkt >= 0);
    assert (L3pkt.l3sseqno ~l3pkt >= 1);

    let decr_and_check_ttl() = (
      L3pkt.decr_l3ttl ~l3pkt;

      if ((L3pkt.l3ttl ~l3pkt) > ((Param.get Params.nodes)/10)) then (
	s#log_warning (lazy (sprintf "Packet with ttl %d" (L3pkt.l3ttl
	~l3pkt)));
	let n_ngbrs = (List.length ((Gworld.world())#neighbors owner#id)) in
	s#log_warning (lazy (sprintf "we have %d neighbors" n_ngbrs));
      );

      if ((L3pkt.l3ttl ~l3pkt) < 0) then (
	s#log_info (lazy (sprintf "Dropping packet (negative ttl)"));
	
	assert(
	  L3pkt.l3grepflags ~l3pkt = L3pkt.GREP_RADV ||
	  L3pkt.l3grepflags ~l3pkt = L3pkt.GREP_RREQ
	);
	false
      ) else true
    )
    in
    s#incr_seqno();
    L3pkt.incr_shopcount_pkt ~l3pkt;
    begin match (L3pkt.l3grepflags ~l3pkt) with

      | L3pkt.NOT_GREP | L3pkt.EASE ->
	  raise (Failure "Grep_agent.send_out")
      | L3pkt.GREP_RERR ->
	  raise (Misc.Impossible_Case "Grep_agent.send_out")
      | L3pkt.GREP_RADV 
      | L3pkt.GREP_RREQ -> 
	  if (decr_and_check_ttl()) then (
	    assert (dst = L3pkt._L3_BCAST_ADDR);
	    Grep_hooks.sent_rreq() ;
	    owner#mac_bcast_pkt ~l3pkt;
	  )
      | L3pkt.GREP_DATA 
      | L3pkt.GREP_RREP ->
	  if ((L3pkt.l3grepflags ~l3pkt) = L3pkt.GREP_DATA) then (
	    if (L3pkt.l3src ~l3pkt) = owner#id then
	      Grep_hooks.orig_data()
	    else 
	      Grep_hooks.sent_data();
	  ) else (
	    Grep_hooks.sent_rrep_rerr();
	  );
	  let (nexthop, ttl) = 
	    match Rtab.nexthop ~rt:rtab ~dst  with
	      | None -> raise Send_Out_Failure
	      | Some nh -> (nh, o2v (Rtab.hopcount ~rt:rtab ~dst)) 
	  in 
	  L3pkt.set_l3ttl ~l3pkt ~ttl:ttl;
	  if (decr_and_check_ttl()) then (
	    (* since we accept rreps with same seqno but more hops, this invariant does
	       not work*)
	    (*	    s#inv_packet_upwards ~nexthop:nexthop ~l3pkt;*)
	    try begin
	      assert((L3pkt.l3ttl ~l3pkt) >= 0);
	      owner#mac_send_pkt ~l3pkt ~dstid:nexthop; end
	    with Simplenode.Mac_Send_Failure ->
 	      raise Send_Out_Failure
	  )
    end
 )
		
	

  (* this is a null method because so far we don't need to model apps getting
     packets since we model CBR streams, and mhook catches packets as they enter
     the node *)
  method private hand_upper_layer ~l3pkt = (
    Grep_hooks.recv_data();
    (*    s#log_notice (sprintf "Received app pkt from src %d"
	  (L3pkt.l3src ~l3pkt));
    *)
  )

  (*
    method ctrl_hook action = (

    s#log_debug (sprintf "Originating dsdv (ttl 5) ");

    let pkt = 
      L3pkt.DSDV_PKT (L3pkt.make_dsdv_pkt 
	~srcid:owner#id 
	~originator:owner#id 
	~nhops:0
    ~seqno:seqno
    ~ttl:6) in
    
    seqno <- seqno + 1;
    owner#mac_bcast_pkt 
    ~l3pkt:pkt;
    )
  *)
    
    
  method private app_send l4pkt ~dst = (
(*    s#log_info (sprintf "Received app pkt with dst %d"
      dst);*)
      let l3hdr = 
	L3pkt.make_l3hdr
	  ~srcid:owner#id
	  ~dstid:dst
	  ~ext:(L3pkt.make_grep_l3hdr_ext
	    ~flags:L3pkt.GREP_DATA
	    ~sseqno:seqno
	    ~shopcount:0
	  )
	  ~ttl:0 (* will be set by send_out *)
	  ()
      in
      let l3pkt = (L3pkt.make_l3pkt ~l3hdr:l3hdr ~l4pkt:l4pkt) in
      if (s#packets_waiting ~dst) then (
	s#buffer_packet ~l3pkt
      ) else (
	try 
	  s#send_out ~l3pkt
	with 
	  | Send_Out_Failure -> 
	      begin
(*		s#log_notice 
		  (sprintf 
		    "Originating DATA pkt to dst %d failed, buffering."
		    dst);
*)
		let dst = (L3pkt.l3dst ~l3pkt) in
		(* important to buffer packet first because send_rreq checks for
		   this *)
		s#buffer_packet ~l3pkt;
		let (dseqno,dhopcount) = 
		  begin match (Rtab.seqno ~rt:rtab ~dst) with
		    | None -> (0, max_int)
		    | Some s -> (s, o2v (Rtab.hopcount ~rt:rtab ~dst)) end
		in
		s#send_rreq 
		  ~ttl:_ERS_START_TTL 
		  ~dst 
		  ~dseqno
		  ~dhopcount;
	      end
      )
  )




end
