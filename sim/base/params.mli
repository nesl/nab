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






(** Core simulator parameters.  
  @author Henri Dubois-Ferriere.
*)

(* These parameters have not (yet?) been examined to figure out if they  *)
(* really need to be globally acessible.                                 *)

val nodes : int Param.t
  (** The number of nodes in the simulation. *)

val x_size : float Param.t
  (** The X (meters) size  of the simulation area. *)

val y_size : float Param.t
  (** The Y (meters) size  of the simulation area. *)

val x_pix_size : int Param.t
  (** The X (pixels) size  of the simulation area, when using a GUI. *)

val y_pix_size : int Param.t
  (** The Y (pixels) size  of the simulation area, when using a GUI. *)

val rrange : float Param.t
  (** Radio range (meters) of nodes *)

val ntargets : int Param.t
  (** The number of nodes that can potentially be routed to as destinations.
    In small simulations, this should be equal to the number of nodes. 
    For large simulations, some parts of mws may be more efficient when this
    is kept small. For example, in EASE routing, the size of the
    Last-Encounter table depends on the number of targets value. *)
    
(*
val world : string Param.t
  (** The type of world representation (taurus vs reflecting, lazy vs greedy, epfl)
    that is to be used in this simulation. @see 'worldt.ml' for details. *)
*)
val log_level : string Param.t
  (** Logging level. *)

val mac : string Param.t
  (** Mac layer used. *)
