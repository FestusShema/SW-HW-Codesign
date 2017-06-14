##############################################################################
## Filename:          /home/akzare/Projects/PICSY/Hardware/MyProcessorIPLib10/MyProcessorIPLib/drivers/measurtool_v1_00_a/data/measurtool_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Sun Feb 21 12:29:40 2010 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "measurtool" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
