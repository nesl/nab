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


(** Functions for controlling mobility processes.
  @author Henri Dubois-Ferriere.
 *)

module Persist : Persist.t

val make_uniwaypoint_mobs : ?gran:float -> unit -> unit
  (** Create {!Mob.t} objects that implement a uniform waypoint mobility
    model (see {!Mobs.uniwaypoint}). Optional gran indicates the mobility granularity. 
  *)

val make_borderwaypoint_mobs : ?gran:float -> unit -> unit
  (** Create {!Mob.t} objects that implement a border waypoint mobility
    model (see {!Mobs.borderwaypoint}). Optional gran indicates the mobility granularity. 
  *)

val make_billiard_mobs : ?gran:float -> unit -> unit
  (** Create {!Mob.t} objects that implement a border waypoint mobility
    model (see {!Mobs.billiard}). Optional [gran] indicates the mobility granularity. 
  *)

val make_epfl_waypoint_mobs : unit -> unit
  (** Create {!Mob.t} objects that implement a waypoint mobility model
    over epfl campus, using graph representation of epfl campus (see file [gui/epflcoords.ml]). *)

val make_discrete_randomwalk_mobs : ?gran:float -> ?dim:[`One | `Two ]-> unit -> unit
  (** Create {!Mob.t} objects that implement a discrete random walk 
    mobility model. 
    Optional [gran] indicates the step size.
    Optional [dim] defaults to two and indicates dimensionality.
  *)

val set_speed : Common.nodeid_t -> float -> unit
  (** [set_speed nid speed] sets the mobility speed of node [nid] to [speed]
    (in meters/sec). *)

val set_speed_all : float -> unit
  (** [set_speed_all speed] sets the mobility speed of all nodes to [speed]
    (in meters/sec). *)


val get_speed : Common.nodeid_t -> float
  (** Returns the speed of given node. *)

val start_node : Common.nodeid_t -> unit
  (** Starts mobility of given node. Idempotent. *)

(** Warning: multiple start/stops might  have faulty behavior, see
  general_todo.txt *)

val stop_node : Common.nodeid_t -> unit
  (** Stops mobility of given node. Idempotent.*)

val start_all : unit -> unit
  (** Starts mobility of all nodes. Idempotent.*)

val stop_all : unit -> unit
  (** Stops mobility of all nodes. Idempotent.*)

type mob_t = 
    [ `Borderwaypoint 
    | `Uniwaypoint 
    | `Epfl_waypoint
    | `Randomwalk_2d
    | `Randomwalk_1d
    | `Billiard]


val mob : [ mob_t | `None] Param.t
  (** Mob param, default is Billiard. *)
