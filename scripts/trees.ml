(*                                  *)
(* mws  multihop wireless simulator *)
(*                                  *)

open GMain
open Printf
open Misc
open Script_utils


let avg_over_all_nodes f = (
  let tot = ref 0 in
  Nodes.iteri (fun nid -> tot := !tot + f nid);
  (i2f !tot) /. (i2f (Param.get Params.nodes))
)

let clear_rtabs() = 
  Array.iter 
  (fun agent -> Rtab.clear_all_entries ~rt:agent#get_rtab)
  !Diff_agent.agents_array

let clear_rtabs_and_build_trees sinklist ~ttl = (
  clear_rtabs();
  
  List.iter (fun sink ->
  let diffagent = !Diff_agent.agents_array.(sink) in
  diffagent#app_send ~ttl ~dst:123 `APP_PKT 
  ) sinklist;
  (Gsched.sched())#run();
)  

let is_connected () = (
  clear_rtabs_and_build_trees ~ttl:(Param.get Params.nodes) [0];
  let count = ref 0 in
  Nodes.iteri (fun nid -> 
    
    let diffagent = !Diff_agent.agents_array.(nid) in
    let rt = diffagent#get_rtab in 
    let nexthop = Rtab.nexthop ~rt ~dst:0 in
    match nexthop with 
      | None -> ()
      | Some n -> incr count
  );
  clear_rtabs();
  (!count = (Param.get Params.nodes))
)


let min_ttl_for_coverage sink = (
  let count = ref 0 in 
  let ttl = ref 1 in
  while (!count <> (Param.get Params.nodes)) do

      count := 0;
      clear_rtabs_and_build_trees ~ttl:!ttl [sink];
      Nodes.iteri (fun nid -> 
	
	let diffagent = !Diff_agent.agents_array.(nid) in
	let rt = diffagent#get_rtab in 
	let nexthop = Rtab.nexthop ~rt ~dst:sink in
	match nexthop with 
	  | None -> ()
	  | Some n -> incr count
      );
      incr ttl;
  done;
  (!ttl - 1)
)    



let compute_tree_length() = (
  let avgn = avg_neighbors_per_node() in
  let end_time = Common.get_time() in
  Printf.fprintf stderr "Avg neighbors per node is %f\n" avgn;
  flush stderr;

  let avg = avg_over_all_nodes (min_ttl_for_coverage ) in
  Printf.printf "average tree depth for one sink: %f\n" avg;


(*  clear_rtabs_and_build_tree ~src:0 ~ttl:1;
  let count = ref 0 in
  Nodes.iteri (fun nid -> 
    let diffagent = !Diff_agent.agents_array.(nid) in
    let rt = diffagent#get_rtab in 
    let nexthop = Rtab.nexthop ~rt ~dst:0 in
    match nexthop with 
      |	None -> ()
      | Some n -> incr count
    );
 Printf.printf "For ttl 1, there are %d connects\n" !count;
*)
 


)

  

let do_one_run() = (
  let avgn = avg_neighbors_per_node() in
  let end_time = Common.get_time() in
  Printf.fprintf stderr "Avg neighbors per node is %f\n" avgn;
  
  flush stderr;



  (Nodes.node 0)#originate_app_pkt ~dst:123;
  (Gsched.sched())#run();
  let tree = 
    Array.to_list (
      Nodes.mapi (fun nid -> 
	let diffagent = !Diff_agent.agents_array.(nid) in
	let rt = diffagent#get_rtab in 
	let nexthop = Rtab.nexthop ~rt ~dst:0 in
	match nexthop with 
	  |	None -> (0, 0)
	  | Some n -> (nid, n)
      ) 
    ) in

  Gui_ops.draw_all_nodes();
  Gui_ops.connect_nodes tree;
  Gui_ops.draw_connectivity(); 
)


let () = 

  Param.set Params.nodes 100;
  Param.set Params.rrange 6.0;
  Param.set Params.x_size (size ~avg_degree:14 ());
  Param.set Params.y_size (size ~avg_degree:14 ());
    
  dumpconfig stdout;
  Log.set_log_level ~level:Log.LOG_NOTICE;

  init_sched();
  init_world();
  make_diff_nodes();

  begin match (is_connected()) with
  | true -> print_endline "Check ok: Graph is connected" ; flush stdout;
  | false -> print_endline "Check not ok: Graph is not connected"; exit 0;
  end;
  (*  compute_tree_length();*)
  
  Gui_gtk.init ();
  Gui_ctl.create_buttons_trees();
  (*  do_one_run();*)
  Main.main();
