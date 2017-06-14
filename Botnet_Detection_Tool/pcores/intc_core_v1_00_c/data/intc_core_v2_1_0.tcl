###############################################################################
##
## Copyright (c) 2006-2007 Xilinx, Inc. All Rights Reserved.
##
## intc_core_v2_1_0.tcl
##
###############################################################################

## @BEGIN_CHANGELOG EDK_J_SP2
##
## - compute the C_NUM_INTR_INPUTS value to 1 even when there is no 
##   interrupt input connected by users, and let platgen connect the signal
##   to net_gnd or net_vcc
## - reset the defaule of C_KIND_OF_EDGE, C_KIND_OF_LVL if the 
##   input port Intr is connected to a constant signal
##
## @END_CHANGELOG


## @BEGIN_CHANGELOG EDK_J
##
## - added update functions for the parameters
##   C_NUM_INTR_INPUTS, C_KIND_OF_INTR, C_KIND_OF_EDGE, C_KIND_OF_LVL
##
## @END_CHANGELOG


proc check_interrupt_signals {intrport mhsinst} {

    set mergedmhs [xget_hw_parent_handle        $mhsinst]
    set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]

    foreach conn $connlist {

        set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]

	foreach connport $connportlist {

	    set cpname [xget_hw_name $connport]
	    set isvec  [xget_hw_subproperty_value $connport "VEC"]

            if {$isvec != ""} {

	        error "Interrupt Port - '$cpname' cannot be a Vector"

	    } 
	}
    }
}

###############################################################################

proc update_num_intr_inputs {intrport mhsinst} {

    set num_intr_inputs 0

    set mergedmhs [xget_hw_parent_handle        $mhsinst]
    set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]

    foreach conn $connlist {

        set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]

        foreach connport $connportlist {
	
            set cpname [xget_hw_name $connport];
	    set vec [xget_hw_subproperty_value $connport "VEC"];

	    if {$vec != ""} {
	  
  		regexp {\[(.+):(.+)\]} $vec bvec fvec svec;

	  	set bwidth [expr {abs($svec - $fvec) + 1}];	

	  	incr num_intr_inputs $bwidth;

	    } else { incr num_intr_inputs }

	} 
    }
    
    # compute the value to 1 even when there is no interrupt input connected
    # by users, and let platgen connect the signal to net_gnd
    if { $num_intr_inputs == 0 } {

        return 1
    }

    return $num_intr_inputs

}

###############################################################################

proc update_kind_of_intr {intrport mhsinst} {

    set kindofintr "0b00000000000000000000000000000000"
    set kindof ""

    set mergedmhs [xget_hw_parent_handle        $mhsinst]
    set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]

    foreach conn $connlist {

        set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]

  	foreach connport $connportlist {
	
	    set cpname      [xget_hw_name $connport];
	    set vec         [xget_hw_subproperty_value $connport "VEC"];
	    set sensitivity [xget_hw_subproperty_value $connport "SENSITIVITY"];

	    # Default is 0 for LEVEL_HIGH, LEVEL_LOW
	    set sense 0
	
	    if {
		[string compare -nocase $sensitivity "EDGE_FALLING"] == 0 ||
	   	[string compare -nocase $sensitivity "EDGE_RISING"] == 0
	    } {
	  	set sense 1
	    }

	    if { $vec != "" } {
	  
		regexp {\[(.+):(.+)\]} $vec bvec fvec svec;
	  	set bwidth [expr {abs($svec - $fvec) + 1}];	

	  	for {set i 0} {$i < $bwidth} {incr i} { append kindof $sense }

	    } else { append kindof $sense; }

	} 
    }

    set len [string length $kindof];

    return [string replace $kindofintr end-[expr $len - 1] end $kindof]

}

###############################################################################

proc update_kind_of_edge {intrport mhsinst} {

    set kindofintr "0b00000000000000000000000000000000"
    set kindof ""

    set mergedmhs [xget_hw_parent_handle        $mhsinst]
    set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]

    # if port Intr is unconnected or connected to a constant signal
    if { [llength $connlist] == 0 } {

	set kindof 1
    	return [string replace $kindofintr end end $kindof]

    } elseif { [llength $connlist] == 1 } {

  	set signal [lindex $connlist 0]

	if {[string compare -nocase "net_gnd" $signal] == 0 || [string compare -nocase "0b0" $signal] == 0 } {

	    set kindof 1
    	    return [string replace $kindofintr end end $kindof]

	} elseif {[string compare -nocase "net_vcc" $signal] == 0 || [string compare -nocase "0b1" $signal] == 0 } {

	    set kindof 0
    	    return [string replace $kindofintr end end $kindof]

	} 

    }

    foreach conn $connlist {

        set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]

  	foreach connport $connportlist {
	
	    set cpname      [xget_hw_name $connport];
	    set vec         [xget_hw_subproperty_value $connport "VEC"];
	    set sensitivity [xget_hw_subproperty_value $connport "SENSITIVITY"];

	    # Default is 0 for EDGE_FALLING
	    set sense 0

	    if { [string compare -nocase $sensitivity "EDGE_RISING"] == 0 } {
	 
		set sense 1
	  
	    }

	    if { $vec != "" } {
	  
		regexp {\[(.+):(.+)\]} $vec bvec fvec svec;
	  	set bwidth [expr {abs($svec - $fvec) + 1}];	

	  	for {set i 0} {$i < $bwidth} {incr i} { append kindof $sense }

	    } else { append kindof $sense; }

	} 
    }

    set len [string length $kindof];

    return [string replace $kindofintr end-[expr $len - 1] end $kindof]

}

###############################################################################

proc update_kind_of_lvl {intrport mhsinst} {

    set kindofintr "0b00000000000000000000000000000000"
    set kindof ""

    set mergedmhs [xget_hw_parent_handle        $mhsinst]
    set connlist  [xget_hw_port_connectors_list $mhsinst $intrport]

    # if port Intr is unconnected or connected to a constant signal
    if { [llength $connlist] == 0 } {

	set kindof 1
    	return [string replace $kindofintr end end $kindof]

    } elseif { [llength $connlist] == 1 } {

  	set signal [lindex $connlist 0]

	if {[string compare -nocase "net_gnd" $signal] == 0 || [string compare -nocase "0b0" $signal] == 0 } {

	    set kindof 1
    	    return [string replace $kindofintr end end $kindof]

	} elseif {[string compare -nocase "net_vcc" $signal] == 0 || [string compare -nocase "0b1" $signal] == 0 } {

	    set kindof 0
    	    return [string replace $kindofintr end end $kindof]

	} 

    }

    foreach conn $connlist {

  	set connportlist [xget_hw_connected_ports_handle $mergedmhs $conn "SOURCE"]

  	foreach connport $connportlist {

	    set cpname      [xget_hw_name $connport];
	    set vec         [xget_hw_subproperty_value $connport "VEC"];
	    set sensitivity [xget_hw_subproperty_value $connport "SENSITIVITY"];

	    # Default is 0 for LEVEL_LOW
	    set sense 0
	
	    if { [string compare -nocase $sensitivity "LEVEL_HIGH"] == 0 } {
	  
		set sense 1
	  
	    }

	    if { $vec != "" } {
	  	
		regexp {\[(.+):(.+)\]} $vec bvec fvec svec;
	  	set bwidth [expr {abs($svec - $fvec) + 1}];	

	  	for {set i 0} {$i < $bwidth} {incr i} { append kindof $sense }
	  
	    } else { append kindof $sense; }
	
	} 
    }

    set len [string length $kindof];

    return [string replace $kindofintr end-[expr $len - 1] end $kindof]

}
