open Coord
open Graph
open Misc

(* changelog: 
   + coords are now expressed in meters, so no need to 
     use one_meter
*)

(* xxx/hack copied from gui_hooks b/c otherwise makefile problems in using
   Gui_hooks.* from here *)
let x_pix_size = ref 1200
let y_pix_size = ref 900

let x_mtr() = Param.get Params.x_size
and y_mtr() = Param.get Params.y_size

let x_mtr_to_pix x = f2i ((i2f !x_pix_size) *. (x /. x_mtr()))
let y_mtr_to_pix y = f2i ((i2f !y_pix_size) *. (y /. y_mtr()))

let x_pix_to_mtr x = (x_mtr()) *. ((i2f x) /. (i2f !x_pix_size))
let y_pix_to_mtr y = (y_mtr()) *. ((i2f y) /. (i2f !y_pix_size))


let pos_mtr_to_pix pos = 
  (x_mtr_to_pix (Coord.xx pos), y_mtr_to_pix (Coord.yy pos))

let pos_pix_to_mtr pos = 
  (x_pix_to_mtr (Coord.xx pos), y_pix_to_mtr (Coord.yy pos))

class type virtual mobility_t =
  object
    val abbrev : string
    val mutable moving : bool
    val owner : Node.node_t
    val mutable speed_mps : float
    method abbrevname : string
    method virtual getnewpos : gran:float -> Coord.coordf_t
    method move : unit
    method set_speed_mps : float -> unit
    method start : unit
    method stop : unit
  end

class type waypoint_t =

  object
    val abbrev : string
    val mutable moving : bool
    val owner : Node.node_t
    val mutable speed_mps : float
    val mutable target_ : Coord.coordf_t
    method abbrevname : string
    method getnewpos : gran:float -> Coord.coordf_t
    method move : unit
    method set_speed_mps : float -> unit
    method start : unit
    method stop : unit
  end

class virtual mobility (abbrevname:string) (owner:Node.node_t) = 
object(s)
  val abbrev = abbrevname
  val owner:Node.node_t = owner
  val mutable speed_mps = 10.0
  val mutable moving =  false
  val granularity = 40.0

  method start = (
    if (not moving) then (
      moving <- true;
      s#move
    ) 
  )

  method stop = (
    if (moving) then 
      moving <- false
  )

  method set_speed_mps speed = speed_mps <- speed

    
  (*  method virtual initialize : unit -> unit*)
    
  (* should move us by gran meters .
     not sure if this gran parameter makes sense in other mobs (like rw)
  *)
  method virtual getnewpos : gran:float -> Coord.coordf_t
    
  method move  = (

    (* if we are stopped then we ignore previously scheduled mobility events. 
       this is for example so that in the gui case, when we call sched#run() to compute
       a route, we can be sure that no node will move during the route computation *)
    if (moving) then (
      let newpos = s#getnewpos granularity in 
      owner#move newpos;

      (* mob is assumed to move us by granularity [meters], so we should schedule the next
	 one in granulatiry / speed_mps seconds *)
      let move_event() = s#move in
      (Gsched.sched())#sched_in ~handler:move_event ~t:(granularity /. speed_mps)
    )
  )

  method abbrevname = abbrev (* for making filenames etc *)
end


class waypoint (owner:Node.node_t) = 
object 
  inherit mobility "wp" owner
  val mutable target_ = (0.0, 0.0)

  initializer (
    target_ <- (Gworld.world())#random_pos
  )

   method getnewpos ~gran = (
    
    let pos = owner#pos in
    assert (((Gworld.world())#boundarize pos) = pos);
    if ((Gworld.world())#dist_coords target_ pos) <= gran then (
      (* arrived within gran[m] of target *)
      let oldtarget = target_ 
      in
      target_ <- (Gworld.world())#random_pos;
      oldtarget
    ) else (
      let direction =  (Coord.normalize (target_ ---. pos))   in
      (pos +++. (direction ***. gran))
    )
  )


end


let get_containing_node pos = (
  let d, ind = (ref max_float, ref (-1)) in 
  Graph.iteri_
    (fun i -> 
      let thisdist = 
	(Gworld.world())#dist_coords 
	(pos_pix_to_mtr (Read_coords.box_centeri i))
	pos 
      in
      if thisdist < !d then (
	d := thisdist;
	ind := i
      )
    ) (Read_coords.g());
  !ind
)

  
  
class epfl (owner:Node.node_t) = 
object(s)
  inherit mobility "epfl" owner
(*  val mutable target_ = (0.0, 0.0)  (* the current end-destination *)*)
  val mutable graphtarget_ = 0      (* as a graph node index *)
  val mutable graph_hops_ = []       (* remaining hops through the graph to
				       graphtarget_ *)
  val mutable current_graph_pos_ = 0


  initializer (
    current_graph_pos_ <- get_containing_node (owner#pos);
    s#get_new_target;
  )
    
  method private get_new_target = (

    let g = graphtarget_ in
    (* to make sure we pick a different one *)
    while (g = graphtarget_) do
      graphtarget_ <-  Random.int 113;
    done;

    current_graph_pos_ <- get_containing_node (owner#pos);
    graph_hops_ <- 
    List.map (fun i -> 
      pos_pix_to_mtr ( Read_coords.box_centeri i) 
    ) 
      ((Graph.routei_dij_ (Read_coords.g()) current_graph_pos_ graphtarget_) @
      [graphtarget_]);




    List.iter (fun i -> Printf.printf "%s " (Graph.node_ (Read_coords.g()) i))
     ((Graph.routei_dij_ (Read_coords.g()) current_graph_pos_ graphtarget_) @
      [graphtarget_]);
    Printf.printf "\n"; flush stdout;
  )
    
  method getnewpos ~gran = (
    let next_hop_target = List.hd graph_hops_ in
    let pos = owner#pos in
    if ((Gworld.world())#dist_coords next_hop_target pos) <= gran then (
      begin
	match graph_hops_ with
	  | hd::[] -> s#get_new_target
	  | hd::rest ->  graph_hops_ <- rest
	  | [] -> raise (Misc.Impossible_Case "Mob.epfl.getnewpos")
      end;
      next_hop_target
    ) else (
      let direction =  (Coord.normalize (next_hop_target ---. pos))   in
      (pos +++. (direction ***. gran))
    )
  )


end

let mob_array = ref ([||]: mobility_t array)
let make_waypoint_mobs() = mob_array := (Nodes.map (fun n -> new waypoint n))
let make_epfl_mobs() = mob_array := (Nodes.map (fun n -> new epfl  n))
let start_node i = !mob_array.(i)#start
let stop_node i = !mob_array.(i)#stop
let start_all() = Array.iteri (fun i n -> start_node i) !mob_array
let stop_all() = Array.iteri (fun i n -> stop_node i) !mob_array




(*

class randomJump = 
object 
  inherit mobility "rj"

  method initialize () = ()
  method getnewpos ~node = 
    (Gworld.world())#random_pos
  method move ~node  = 
    node#move (Gworld.world())#random_pos
end

class randomWalk = 
object 

  inherit mobility "rw"

  method initialize () = ()
  method getnewpos ~node = 
    (Gworld.world())#boundarize
    (* amplitude of 3 gives us a variance of 3/4 along either axis *)
    (node#pos +++. ((Random.float 3.0, Random.float 3.0) ---. (1.5, 1.5)))


end

*)

