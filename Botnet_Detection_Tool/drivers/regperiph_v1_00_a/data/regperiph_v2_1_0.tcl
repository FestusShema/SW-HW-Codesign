##############################################################################
## Filename:          /home/jupiter/Desktop/Hard_ORB_Client_14.4_Virtex5/drivers/regperiph_v1_00_a/data/regperiph_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Tue May 14 11:16:58 2013 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "regperiph" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
