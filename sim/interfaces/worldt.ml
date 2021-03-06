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

(** 
  World: All computation requiring omniscience is done here. 
  Things like:
  - finding neighbors of a node.
  - finding the nearest node to a point satisfying some property.
  - computing a delaunay triangulation (not implemented).
  - computing the shortest path between two nodes.
  - checking connectedness of a network.

  @author Henri Dubois-Ferriere.
*)
class type lazy_world_t = 
object
    
  method random_pos : Coord.coordf_t 
    (** Return a uniform random position over the surface of the simulated area. *)

  method dist_coords :  Coord.coordf_t -> Coord.coordf_t -> float
    (** Compute distance between two euclidean coordinates. *)

  method dist_nodeids :  Common.nodeid_t -> Common.nodeid_t -> float
    (** Compute distance between two nodes. *)
    
  method neighbors : Common.nodeid_t -> Common.nodeid_t list
    (** Return all the neighbors of a node. Neighbors are nodes within
      distance {!Params.radiorange} of each other. *)

  method are_neighbors : Common.nodeid_t -> Common.nodeid_t -> bool
    (** Return true if two nodes are neighbors, false otherwise.
      Neighbors are nodes within  distance {!Params.radiorange} of each other. *)

  method add_mob_mhook : hook:(Coord.coordf_t -> Common.nodeid_t -> unit) -> unit
    (** Any monitoring application can register here to receive update each
       time the node moves.
       If multiple apps, order in which called is unspecified.*)
    
  method init_pos : nid:Common.nodeid_t -> pos:(Coord.coordf_t) -> unit
    (** Set initial position of a node. This should only be used once, after a
      node object has been created. *)

  method movenode : 
    nid:Common.nodeid_t -> 
    newpos:Coord.coordf_t ->
    unit
    (**  Each time a node moves, the world object should be informed through
      this method.
    *)

  method nodepos : Common.nodeid_t -> Coord.coordf_t 
    (** Return the position of a node. *)

  method find_closest : pos:Coord.coordf_t -> 
    ?f:(Common.nodeid_t -> bool) ->
    unit ->
    Common.nodeid_t option
    (** Returns the closest node to position [pos] which satisfies the boolean
      function [f], or None if no node satisfies [f].

      [f] is optional: if not provided, the closest node to [pos] is returned.
    *)

  method is_connected : unit -> bool
    (** Returns true if the network is connected (under a boolean connectivity
      model, with connectivity up to Params.radiorange), false otherwise.
      Warning: this is SLOW for networks in the 100s of nodes or above. *)

  method get_nodes_within_radius :  nid:Common.nodeid_t -> radius:float -> Common.nodeid_t list
    (** Return all nodes within a given distance of a node. 
      Note: Current implementation is not efficient (iterates over all nodes).*)

  (**/**)

  method neighbors_consistent : bool

  method boundarize : Coord.coordf_t -> Coord.coordf_t
    (* A topology-specific function which should put a point back within the
       boundaries of the world, if it has stepped outside, and should return
       the point intact if it has not.
       For example this might be implemented as wrapping in a torus, or
       bouncing on reflective borders, etc 
       This allows a mobility process computing a next position to be
       decoupled from the type of topology (ie reflecting against versus
       wrapping around on borders).

       Note: for efficiency, some implementations of world may assume that the
       position is at most one world size outside of the boundaries - if this
       is not the case, behavior is undefined.
    *)
    
  method project_2d : Coord.coordf_t -> Coord.coordf_t 
    (* return position projected to a unit square *)
    
  (*  method scale_unit : float -> float 
      return coordinate scaled to [0;1] interval. 
      can be used for example for drawing search disks *)
end

  
class type greedy_world_t = 
object
  inherit lazy_world_t

  method add_new_ngbr_hook : Common.nodeid_t -> hook:(Common.nodeid_t -> unit) -> unit
    (** Any agent (routing, application, etc) or mac layer who wants to know
      when nodes enter the neighborhood of the node given as first argument
      should  register through this hook. 
      Note that using this facility in protocols is "cheating" - in a fully
      distributed implementation, nodes can only infer neighborhood changes by
      exchanging packets. For visualization or measurements, fair game of course.
    *)
end


