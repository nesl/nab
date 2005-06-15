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


open Misc
open Script_utils

let sp = Printf.sprintf

let () = 

  Script_utils.parse_args();
  Arg.current := 0;

  if not (Param.has_value Script_params.dumpfile) then
    failwith "need to set -dumpfile!!!";
  
  Warmup_utils.setup_or_restore();
  
  let dumpfile = Param.get Script_params.dumpfile in
  
  if Param.get Script_params.detach then begin
    let logname = (Filename.chop_extension dumpfile)^".log" in
    Script_utils.detach_daemon ~outfilename:logname ()end;

  Warmup_utils.maybe_warmup ~fname:dumpfile
