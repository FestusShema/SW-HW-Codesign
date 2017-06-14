###############################################################################
##
## Copyright (c) 2007 Xilinx, Inc. All Rights Reserved.
##
## plbv46_pim_v2_1_0.tcl
##
###############################################################################

## @BEGIN_CHANGELOG EDK_J_SP2
##
## - initial 1.00a version
##
## @END_CHANGELOG


#***--------------------------------***------------------------------------***
#
# 		         IPLEVEL_UPDATE_VALUE_PROC
#
#***--------------------------------***------------------------------------***

# update C_MPMC_PIM_DATA_WIDTH = C_SPLB_NATIVE_DWIDTH
#
proc iplevel_update_pim_dwidth { param_handle } {

    set mhsinst       [xget_hw_parent_handle   $param_handle]
    set pim_dwidth    [xget_hw_parameter_value $mhsinst "C_MPMC_PIM_DATA_WIDTH"]
    set native_dwidth [xget_hw_parameter_value $mhsinst "C_SPLB_NATIVE_DWIDTH"]

    if { $pim_dwidth == $native_dwidth } {

	return $pim_dwidth

    } else {

	return $native_dwidth

    }

}
