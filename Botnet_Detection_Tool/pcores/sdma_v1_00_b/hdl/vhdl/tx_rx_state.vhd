-------------------------------------------------------------------------------
-- tx_rx_state.vhd
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
-- Filename:        tx_rx_state.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
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
-- Author:      Jeff Hao
-- History:
--  JYH     02/04/05
-- ~~~~~~
--  - Initial EDK Release
-- ^^^^^^
--  GAB     10/02/06
-- ~~~~~~
--  - Converted from verilog to vhdl
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
use sdma_v1_00_b.sdma_pkg.all;

-------------------------------------------------------------------------------
entity tx_rx_state is
  port(
    -- Global Signals
    LLink_Clk               : in  std_logic; 
    LLink_Rst               : in  std_logic; 
    -- Request Types
    CL8R                    : out std_logic; 
    B16                     : out std_logic; 
    CL8W                    : out std_logic; 
    -- Controls
    Channel_Reset           : in  std_logic;
    Channel_Start           : in  std_logic; 
    Channel_Read_Desc_Done  : in  std_logic; 
    Channel_Data_Done       : in  std_logic; 
    Channel_Continue        : in  std_logic; 
    Channel_Stop            : in  std_logic  
);
end tx_rx_state;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of tx_rx_state is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
type states is (IDLE, READ_DESC, RW_DATA, WRITE_DESC);
signal CS : states;

-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin


   CL8R <= '1' when CS=READ_DESC    else '0';
   B16  <= '1' when CS=RW_DATA      else '0';
   CL8W <= '1' when CS=WRITE_DESC   else '0';
   
   -- Transmit/Receive State Machine
   process(LLink_Clk)
   begin
     if(LLink_Clk'event and LLink_Clk = '1')then
       if (LLink_Rst = '1') then
         CS         <= IDLE;
       else
         case (CS) is
           when IDLE       =>
             if (Channel_Start = '1' and Channel_Reset = '0') then
               CS   <= READ_DESC;
             else
               CS   <= IDLE;
             end if;
           when READ_DESC  =>
             if(Channel_Reset='1')then
                CS <= IDLE;
             elsif (Channel_Read_Desc_Done = '1') then
               CS   <= RW_DATA;
             else
               CS   <= READ_DESC;
             end if;
           when RW_DATA    =>
             if (Channel_Data_Done = '1') then
               CS   <= WRITE_DESC;
             else
               CS   <= RW_DATA;
             end if;
           when WRITE_DESC =>
             if (Channel_Stop = '1') then
               CS   <= IDLE;
             else
               if(Channel_Reset = '1')then
                 CS <= IDLE;
               elsif (Channel_Continue = '1') then
                 CS <= READ_DESC;
               else
                 CS <= WRITE_DESC;
               end if;
             end if;
           when others =>
            CS <= IDLE;
         end case; -- case(CS)
       end if;
     end if;
     end process;

   end implementation;
