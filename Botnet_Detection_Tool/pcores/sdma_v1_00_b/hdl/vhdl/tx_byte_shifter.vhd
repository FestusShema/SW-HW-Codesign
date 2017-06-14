-------------------------------------------------------------------------------
-- tx_byte_shifter.vhd
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
-- Filename:        tx_byte_shifter.vhd
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
entity tx_byte_shifter is
    port(
        -- Global Inputs
        LLink_Clk            : in std_logic;                     
        LLink_Rst            : in std_logic;                     

        -- Byte Shifter Control Signals
        Byte_Sel0            : in std_logic_vector(1 downto 0);            
        Byte_Sel1            : in std_logic_vector(1 downto 0);            
        Byte_Sel2            : in std_logic_vector(1 downto 0);            
        Byte_Sel3            : in std_logic_vector(1 downto 0);            
        Byte_Reg_CE          : in std_logic_vector(3 downto 0);          

        -- Data Inputs
        Port_RdData          : in std_logic_vector(31 downto 0);         

        -- Data Output
        Port_TX_Out          : out std_logic_vector(31 downto 0)         
    );
end tx_byte_shifter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of tx_byte_shifter is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin

   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(LLink_Rst = '1') then
         Port_TX_Out(7 downto 0)  <= (others => '0');
       else
         if (Byte_Reg_CE(0) = '1') then
           case Byte_Sel0 is
             when "00"      => Port_TX_Out(7 downto 0) <= Port_RdData(31 downto 24);
             when "01"      => Port_TX_Out(7 downto 0) <= Port_RdData(23 downto 16);
             when "10"      => Port_TX_Out(7 downto 0) <= Port_RdData(15 downto 8);
             when "11"      => Port_TX_Out(7 downto 0) <= Port_RdData(7 downto 0);
             when others    => Port_TX_Out(7 downto 0) <= (others => '0');
           end case;  -- case(Byte_Sel0)
         end if;  -- if (Byte_Reg_CE(0))
       end if;  -- else =>  !if(LLink_Rst)
     end if;  -- always @ (posedge LLink_Clk)
   end process;

   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(LLink_Rst = '1') then
         Port_TX_Out(15 downto 8)                    <= (others => '0');
       else
         if (Byte_Reg_CE(1) = '1') then
           case Byte_Sel1 is
             when "00"      => Port_TX_Out(15 downto 8) <= Port_RdData(31 downto 24);
             when "01"      => Port_TX_Out(15 downto 8) <= Port_RdData(23 downto 16);
             when "10"      => Port_TX_Out(15 downto 8) <= Port_RdData(15 downto 8);
             when "11"      => Port_TX_Out(15 downto 8) <= Port_RdData(7 downto 0);
             when others    => Port_TX_Out(15 downto 8) <= (others => '0');
           end case;  -- case(Byte_Sel1)
         end if;  -- if (Byte_Reg_CE(1))
       end if;  -- else =>  !if(LLink_Rst)
     end if;  -- always @ (posedge LLink_Clk)
   end process;

   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(LLink_Rst = '1') then
         Port_TX_Out(23 downto 16) <= (others => '0');
       else
         if (Byte_Reg_CE(2) = '1') then
           case Byte_Sel2 is
             when "00"      => Port_TX_Out(23 downto 16) <= Port_RdData(31 downto 24);
             when "01"      => Port_TX_Out(23 downto 16) <= Port_RdData(23 downto 16);
             when "10"      => Port_TX_Out(23 downto 16) <= Port_RdData(15 downto 8);
             when "11"      => Port_TX_Out(23 downto 16) <= Port_RdData(7 downto 0);
             when others    => Port_TX_Out(23 downto 16) <= (others => '0');
           end case;  -- case(Byte_Sel2)
         end if;  -- if (Byte_Reg_CE(2))
       end if;  -- else =>  !if(LLink_Rst)
     end if;  -- always @ (posedge LLink_Clk)
   end process;

   process(LLink_Clk)
   begin
     if(rising_edge(LLink_Clk)) then
       if(LLink_Rst = '1') then
         Port_TX_Out(31 downto 24) <= (others => '0');
       else
         if (Byte_Reg_CE(3) = '1') then
           case Byte_Sel3 is
             when "00"      => Port_TX_Out(31 downto 24) <= Port_RdData(31 downto 24);
             when "01"      => Port_TX_Out(31 downto 24) <= Port_RdData(23 downto 16);
             when "10"      => Port_TX_Out(31 downto 24) <= Port_RdData(15 downto 8);
             when "11"      => Port_TX_Out(31 downto 24) <= Port_RdData(7 downto 0);
             when others    => Port_TX_Out(31 downto 24) <= (others => '0');
           end case;  -- case(Byte_Sel3)
         end if;  -- if (Byte_Reg_CE(3)) 
       end if;
     end if;
   end process;

end implementation;
