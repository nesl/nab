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




val ease_route_pktin_mhook : 
  ?num:int ->
  (Common.nodeid_t, Coord.coordf_t) Route.ease_route_t ref ->
  L2pkt.t ->
  Gpsnode.gpsnode -> 
  unit
  
val ease_route_pktout_mhook : 
  ?num:int ->
  (Common.nodeid_t, Coord.coordf_t) Route.ease_route_t ref ->
  L2pkt.t ->
  Gpsnode.gpsnode -> 
  unit

val grep_route_pktin_mhook : 
  Common.nodeid_t Route.grep_route_t ref ->
  L2pkt.t ->
  Simplenode.simplenode -> 
  unit

val grep_route_pktout_mhook : 
  Common.nodeid_t Route.grep_route_t ref ->
  L2pkt.t ->
  Simplenode.simplenode -> 
  unit

val routes_done : int ref


