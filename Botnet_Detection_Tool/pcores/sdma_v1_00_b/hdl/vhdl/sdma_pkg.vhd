-------------------------------------------------------------------------------
-- cdmac_pkg.vhd
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2006 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        sdma_pkg.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  sdma.vhd
--                      |- sample_cycle.vhd
--                      |- sdma_cntl.vhd
--                      |   |- ipic_if.vhd
--                      |   |   |-sample_cycle.vhd
--                      |   |- interrupt_register.vhd
--                      |   |- dmac_regfile_arb.vhd
--                      |   |- read_data_delay.vhd
--                      |   |- addr_arbiter.vhd
--                      |   |- port_arbiter.vhd
--                      |   |- tx_write_handler.vhd
--                      |   |- tx_read_handler.vhd
--                      |   |- tx_port_controller.vhd
--                      |   |- rx_read_handler.vhd
--                      |   |- rx_write_handler.vhd
--                      |   |- rx_port_controller.vhd
--                      |   |- tx_rx_state.vhd
--                      |
--                      |
--                      |- sdma_datapath.vhd
--                      |   |- reset_module.vhd
--                      |   |- channel_status_reg.vhd
--                      |   |- address_counter.vhd
--                      |   |- length_counter.vhd
--                      |   |- tx_byte_shifter.vhd
--                      |   |- rx_byte_shifter.vhd
--                  sdma_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:      Gary Burch
-- History:
--  GAB     10/02/06
-- ~~~~~~
--  Initial Release
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "LLink_Clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_com"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    
use ieee.std_logic_misc.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.proc_common_pkg.log2;
use proc_common_v2_00_a.proc_common_pkg.max2;
use proc_common_v2_00_a.family_support.all;
use proc_common_v2_00_a.ipif_pkg.all;

library unisim;
use unisim.vcomponents.all;

library sdma_v1_00_b;
use sdma_v1_00_b.all;

package sdma_pkg is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- Register Offsets
constant TX_NXTDESC_PTR             : std_logic_vector(0 to 3) := "0000"; -- offset=0x00
constant TX_CURBUF_ADDR             : std_logic_vector(0 to 3) := "0001"; -- offset=0x04
constant TX_CURBUF_LENGTH           : std_logic_vector(0 to 3) := "0010"; -- offset=0x08
constant TX_CURDESC_PTR             : std_logic_vector(0 to 3) := "0011"; -- offset=0x0C
constant TX_TAILDESC_PTR            : std_logic_vector(0 to 3) := "0100"; -- offset=0x10
constant TX_CHNL_CTRL               : std_logic_vector(0 to 3) := "0101"; -- offset=0x14
constant TX_IRQ_REG                 : std_logic_vector(0 to 3) := "0110"; -- offset=0x18
constant TX_TX_CHNL_STS             : std_logic_vector(0 to 3) := "0111"; -- offset=0x1C    

constant RX_NXTDESC_PTR             : std_logic_vector(0 to 3) := "1000"; -- offset=0x20
constant RX_CURBUF_ADDR             : std_logic_vector(0 to 3) := "1001"; -- offset=0x24
constant RX_CURBUF_LENGTH           : std_logic_vector(0 to 3) := "1010"; -- offset=0x28
constant RX_CURDESC_PTR             : std_logic_vector(0 to 3) := "1011"; -- offset=0x2C
constant RX_TAILDESC_PTR            : std_logic_vector(0 to 3) := "1100"; -- offset=0x20
constant RX_CHNL_CTRL               : std_logic_vector(0 to 3) := "1101"; -- offset=0x24
constant RX_IRQ_REG                 : std_logic_vector(0 to 3) := "1110"; -- offset=0x28
constant RX_TX_CHNL_STS             : std_logic_vector(0 to 3) := "1111"; -- offset=0x2C    


-- Register CE Indecies
constant TX_NXTDESC_PTR_CE          : integer := 0; -- RegFile (LUTRAM)
constant TX_CURBUF_ADDR_CE          : integer := 1; -- RegFile (LUTRAM)
constant TX_CURBUF_LENGTH_CE        : integer := 2; -- RegFile (LUTRAM)
constant TX_CURDESC_PTR_CE          : integer := 3; -- RegFile (LUTRAM)
constant TX_TAILDESC_PTR_CE         : integer := 4; -- RegFile (LUTRAM)
constant TX_CHNL_CTRL_CE            : integer := 5; -- Discrete
constant TX_IRQ_CE                  : integer := 6; -- Discrete
constant TX_CHNL_STS_CE             : integer := 7; -- Discrete
constant RX_NXTDESC_PTR_CE          : integer := 8; -- RegFile (LUTRAM)
constant RX_CURBUF_ADDR_CE          : integer := 9; -- RegFile (LUTRAM)
constant RX_CURBUF_LENGTH_CE        : integer := 10;-- RegFile (LUTRAM)
constant RX_CURDESC_PTR_CE          : integer := 11;-- RegFile (LUTRAM)
constant RX_TAILDESC_PTR_CE         : integer := 12;-- RegFile (LUTRAM)
constant RX_CHNL_CTRL_CE            : integer := 13;-- Discrete
constant RX_IRQ_CE                  : integer := 14;-- Discrete
constant RX_CHNL_STS_CE             : integer := 15;-- Discrete
constant DMA_CNTRL_CE               : integer := 16;-- Discrete


-- Channel Control Register Bit map
constant CHNL_CNTRL_IRQCOALEN_BIT   : integer := 31;
constant CHNL_CNTRL_IRQDLYEN_BIT    : integer := 30;
constant CHNL_CNTRL_IRQERREN_BIT    : integer := 29;
constant CHNL_CNTRL_IRQEN_BIT       : integer := 24;
constant CHNL_CNTRL_IRQLDCNT_BIT    : integer := 23;
constant CHNL_CNTRL_USEIOE_BIT      : integer := 22;
constant CHNL_CNTRL_USE1BIT_BIT     : integer := 21; --current not used

-- Interrupt Register Bit map
constant IRQ_REG_COALIRQ_BIT        : integer := 31;
constant IRQ_REG_DLYIRQ_BIT         : integer := 30;
constant IRQ_REG_ERRIRQ_BIT         : integer := 29;

-- DMA Control Register Bit map
constant DMA_CNTRL_SWRESET_BIT      : integer := 31;
constant DMA_CNTRL_RESERVED30       : integer := 30;
constant DMA_CNTRL_TAILPTR_BIT      : integer := 29;
constant DMA_CNTRL_TXOFERRDIS_BIT   : integer := 28; --Hard DMA Tx Overflow Err Disable
constant DMA_CNTRL_RXOFERRDIS_BIT   : integer := 27;

-- Channel Status Register Bit map
constant CHNL_STS_CMPERR_BIT        : integer := 10;
constant CHNL_STS_ADDRERR_BIT       : integer := 11;
constant CHNL_STS_NXTPERR_BIT       : integer := 12;
constant CHNL_STS_CURPERR_BIT       : integer := 13;
constant CHNL_STS_TAILPERR_BIT      : integer := 14;
constant CHNL_STS_BSYWR_BIT         : integer := 15;
constant CHNL_STS_ERROR_BIT         : integer := 24;
constant CHNL_STS_IOE_BIT           : integer := 25;
constant CHNL_STS_SOE_BIT           : integer := 26;
constant CHNL_STS_CMPLT_BIT         : integer := 27;
constant CHNL_STS_SOP_BIT           : integer := 28;
constant CHNL_STS_EOP_BIT           : integer := 29;
constant CHNL_STS_ENGBUSY_BIT       : integer := 30;
constant CHNL_STS_RESERVED31        : integer := 31;

end sdma_pkg;


-------------------------------------------------------------------------------
-- Type Declarations
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- PACKAGE BODY
-------------------------------------------------------------------------------
package body sdma_pkg is



end package body sdma_pkg;


