-------------------------------------------------------------------------------
-- address_counter.vhd
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
---------------------------------------------------------------------------
-- Filename:          address_counter.vhd
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
entity address_counter is
    port(
        LLink_Clk       : in  std_logic;      
        LLink_Rst       : in  std_logic;      
        Address_In      : in  std_logic_vector(31 downto 0); 
        Address_Out     : out std_logic_vector(31 downto 0); 
        Address_Load    : in  std_logic;      
        INC1            : in  std_logic;                         
        INC2            : in  std_logic;      
        INC3            : in  std_logic;      
        INC4            : in  std_logic       
    );

end address_counter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of address_counter is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal Carry0           : std_logic;
signal Carry1           : std_logic;
signal Carry1_d1        : std_logic;
signal Address_Temp0    : std_logic_vector(1 downto 0);
signal Address_Temp1    : std_logic_vector(4 downto 0);
signal sum0             : std_logic_vector(2 downto 0);
signal sum1             : std_logic_vector(5 downto 0);
signal address_out_i    : std_logic_vector(31 downto 0);
signal a, b, c          : std_logic;

signal addr_slice0      : std_logic_vector(2 downto 0);
signal slice0_inc       : std_logic_vector(2 downto 0);
signal addr_slice1      : std_logic_vector(5 downto 0);
signal slice1_inc       : std_logic_vector(5 downto 0);


-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin

a               <= (INC3 or INC2);
b               <= (INC3 or INC1);
c               <= (Carry0 or INC4);

addr_slice0     <= '0' & std_logic_vector(unsigned(address_out_i(1 downto 0)));
slice0_inc      <= '0' & a & b;
Sum0            <= std_logic_vector(unsigned(addr_slice0) + unsigned(slice0_inc));

addr_slice1     <= '0' & std_logic_vector(unsigned(address_out_i(6 downto 2)));
slice1_inc      <= "00000" & c;
Sum1            <= std_logic_vector(unsigned(addr_slice1) + unsigned(slice1_inc));


Carry0          <= sum0(2);
Address_Temp0   <= sum0(1 downto 0);
Carry1          <= sum1(5);
Address_Temp1   <= sum1(4 downto 0);
Address_Out     <= address_out_i;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(LLink_Rst = '1') then
        Carry1_d1 <= '0';
      else
        Carry1_d1 <= Carry1;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(LLink_Rst = '1') then
        address_out_i(1 downto 0)     <= "00";
      else
        if (Address_Load = '1') then
          address_out_i(1 downto 0)<= Address_In(1 downto 0);
        else
          if (INC1 = '1' or INC2 = '1' or INC3 = '1') then
            address_out_i(1 downto 0) <= Address_Temp0;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(LLink_Rst = '1') then
        address_out_i(6 downto 2)     <= (others => '0');
      else
        if (Address_Load = '1') then
          address_out_i(6 downto 2)   <= Address_In(6 downto 2);
        else
          if (Carry0 = '1' or INC4 = '1') then
            address_out_i(6 downto 2) <= Address_Temp1;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin
    if(rising_edge(LLink_Clk)) then
      if(LLink_Rst = '1') then
        address_out_i(31 downto 7)     <= (others => '0');
      else
        if (Address_Load = '1') then
          address_out_i(31 downto 7)   <= Address_In(31 downto 7);
        else
          if (Carry1_d1 = '1') then
            address_out_i(31 downto 7) <= std_logic_vector(unsigned(address_out_i(31 downto 7)) + 1);
          end if;
        end if;
      end if;
    end if;
  end process;

end implementation;
