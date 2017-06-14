##############################################################################
## Filename:          /home/akzare/Projects/PICSY/Hardware/MyProcessorIPLib/MyProcessorIPLib/drivers/hardorb_fpga10_v3_01_a/data/hardorb_fpga10_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Wed Dec 23 12:08:46 2009 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "XEmacLite" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" "C_TX_PING_PONG" "C_RX_PING_PONG" "C_INCLUDE_MDIO" "C_INCLUDE_INTERNAL_LOOPBACK"
  xdefine_config_file $drv_handle "xemaclite_g.c" "XEmacLite"  "DEVICE_ID" "C_BASEADDR" "C_TX_PING_PONG" "C_RX_PING_PONG" "C_INCLUDE_MDIO" "C_INCLUDE_INTERNAL_LOOPBACK"

  xdefine_canonical_xpars $drv_handle "xparameters.h" "EmacLite" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" "C_TX_PING_PONG" "C_RX_PING_PONG" "C_INCLUDE_MDIO" "C_INCLUDE_INTERNAL_LOOPBACK"
}


#
# Given a list of arguments, define each as a canonical constant name, using
# the driver name, in an include file.
#
proc xdefine_canonical_xpars {drv_handle file_name drv_string args} {
    # Open include file
    set file_handle [xopen_include_file $file_name]

    # Get all the peripherals connected to this driver
    set periphs [xget_periphs $drv_handle]

    # Get the names of all the peripherals connected to this driver
    foreach periph $periphs {
        set peripheral_name [string toupper [xget_hw_name $periph]]
        lappend peripherals $peripheral_name
    }

    # Get possible canonical names for all the peripherals connected to this driver
    set device_id 0
    foreach periph $periphs {
        set canonical_name [string toupper [format "%s_%s" $drv_string $device_id]]
        lappend canonicals $canonical_name
        
        # Create a list of IDs of the peripherals whose hardware instance name
        # doesn't match the canonical name. These IDs can be used later to
        # generate canonical definitions
        if { [lsearch $peripherals $canonical_name] < 0 } {
            lappend indices $device_id
        }
        incr device_id
    }

    set i 0
    foreach periph $periphs {
        set periph_name [string toupper [xget_hw_name $periph]]

        # Generate canonical definitions only for the peripherals whose
        # canonical name is not the same as hardware instance name
        if { [lsearch $canonicals $periph_name] < 0 } {
            puts $file_handle "/* Canonical definitions for peripheral $periph_name */"
            set canonical_name [format "%s_%s" $drv_string [lindex $indices $i]]

            foreach arg $args {
                set lvalue [xget_dname $canonical_name $arg]

    # The commented out rvalue is the name of the instance-specific constant
    #           set rvalue [xget_name $periph $arg]

                # The rvalue set below is the actual value of the parameter
                set rvalue [xget_param_value $periph $arg]
                if {[llength $rvalue] == 0} {
                    set rvalue 0
                }
                set rvalue [xformat_addr_string $rvalue $arg]
    
                puts $file_handle "#define $lvalue $rvalue"

            }
            puts $file_handle ""
            incr i
        }
    }

    puts $file_handle "\n/******************************************************************/\n"
    close $file_handle
}
