(*
 *
 *  NAB - Network in a Box
 *  Henri Dubois-Ferriere, LCA/LCAV, EPFL
 * 
 *  Copyright (C) 2004 Laboratory of Audiovisual Communications (LCAV), and
 *  Laboratory for Computer Communications and Applications (LCA), 
 *  Ecole Polytechnique Federale de Lausanne (EPFL),
 *  CH-1015 Lausanne, Switzerland
 *
 *  This file is part of NAB. NAB is free software; you can redistribute it 
 *  and/or modify it under the terms of the GNU General Public License as 
 *  published by the Free Software Foundation; either version 2 of the License,
 *  or (at your option) any later version. 
 *
 *  NAB is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 *  details (enclosed in the file GPL). 
 *
 *)

(* $Id$ *)

(** Routing tables for GREP. *)

type t
  (** The type of routing table exported by this module. *)



type spec = [ `GREP ]

type rtab_entry_t = {
  mutable seqno: int option;
  mutable nexthop: Common.nodeid_t option;
  mutable hopcount: int option;
  mutable repairing: bool;
  other: spec
}

val create_grep : size:int -> t

val seqno : rt:t -> dst:Common.nodeid_t -> int option
val nexthop : rt:t -> dst:Common.nodeid_t -> Common.nodeid_t option
val hopcount : rt:t -> dst:Common.nodeid_t -> int option

val invalidate : rt:t -> dst:Common.nodeid_t -> unit
val invalid : rt:t -> dst:Common.nodeid_t -> bool
val repairing  : rt:t -> dst:Common.nodeid_t -> bool
val repair_start  : rt:t -> dst:Common.nodeid_t -> unit
val repair_done  : rt:t -> dst:Common.nodeid_t -> unit

val newadv : 
  rt:t -> 
  dst:Common.nodeid_t -> 
  sn:int -> hc:int -> nh:int ->
  bool
  (* looks at rtent (proposed new routing entry), updates routing table 
     if fresher seqno or same seqno and shorter hopcount *)

val newadv_ignorehops : 
  rt:t -> 
  dst:Common.nodeid_t -> 
  sn:int -> hc:int -> nh:int ->
  bool
  (* same as newadv except based on seqnos only: a fresher or equal seqno is
  accepted, older seqno not *)


val clear_entry : rt:t -> dst:Common.nodeid_t -> unit
  (** Set entry for dst back to 'empty' state (ie, state when a routing table
    is initially created *)

val clear_all_entries : rt:t -> unit
  (** Set all entries back to 'empty' state (ie, state when a routing table
    is initially created). *)

