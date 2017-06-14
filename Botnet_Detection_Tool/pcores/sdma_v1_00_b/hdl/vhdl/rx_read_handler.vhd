-------------------------------------------------------------------------------
-- rx_read_handler.vhd 
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
-- Filename:        rx_read_handler.vhd
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
entity rx_read_handler is
    port(
        -- Global Signals
        LLink_Clk                   : in  std_logic;              
        LLink_Rst                   : in  std_logic;              

        -- Port Interface Signals
        rdDataAck_Pos               : out std_logic;                    
        rdDataAck_Neg               : out std_logic;                    
        rdComp                      : out std_logic;                    
        rd_rst                      : out std_logic;                    
        rd_fifo_empty               : in  std_logic;                    

        -- Datapath Signals
        SDMA_Sel_rdData_Pos        : out  std_logic_vector(3 downto 0);

        -- Port Controller Signals
        RX_CL8R_Start               : in  std_logic;                    
        RX_CL8R_Comp                : out std_logic;                    
        RX_RdPop                    : out std_logic;                    

        -- Channel Reset Signals
        RX_ChannelRST               : in  std_logic
--        RX_RdHandlerRST             : in  std_logic                     
    );
end rx_read_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of rx_read_handler is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal RdPopCount       : std_logic_vector(2 downto 0);
signal Active           : std_logic;
signal Toggle           : std_logic;
signal Rd_Rst_Pending   : std_logic;
signal rx_rdpop_i       : std_logic;
signal rd_rst_i         : std_logic;
signal rx_cl8r_comp_i   : std_logic;
signal rd_rst_d1        : std_logic;
signal rd_rst_strb      : std_logic;
-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------
begin

RX_RdPop                <= rx_rdpop_i;
rd_rst                  <= rd_rst_strb;
RX_CL8R_Comp            <= rx_cl8r_comp_i;
rx_rdpop_i              <= Active and (not rd_fifo_empty or Toggle);
rdDataAck_Pos           <= rx_rdpop_i and not Toggle;
rdDataAck_Neg           <= rx_rdpop_i and Toggle;
rdComp                  <= '1' when rx_rdpop_i = '1' and (RdPopCount = "111") else '0';
SDMA_Sel_rdData_Pos     <= not (Toggle & Toggle & Toggle & Toggle);
rd_rst_i                <= LLink_Rst or RX_ChannelRST;


--  process(LLink_Clk)
--  begin
--    if(LLink_Clk'event and LLink_Clk = '1')then
--      if (LLink_Rst = '1' or Rd_Rst_Pending = '1') then
--        Rd_Rst_Pending <= '0';
--      elsif (rd_rst_i = '1') then
--        Rd_Rst_Pending <= '1';
--      end if;
--    end if;
--  end process;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
        rd_rst_d1 <= rd_rst_i;
    end if;
  end process;

  rd_rst_strb <= rd_rst_i and not rd_rst_d1;
    
  rx_cl8r_comp_i <= '1' when (rx_rdpop_i = '1' and (RdPopCount = "111")) 
                            or(rd_rst_strb='1')
                else '0';

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1' or rx_cl8r_comp_i = '1' or RX_ChannelRST='1') then
        Active <= '0';
      elsif (RX_CL8R_Start = '1') then
        Active <= '1';
      end if;
    end if;
  end process;

-- Read Pop Counter
  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1' or RX_ChannelRST='1') then
        RdPopCount <= (others => '0');
      elsif (rx_rdpop_i = '1') then
        RdPopCount <= std_logic_vector(unsigned(RdPopCount) + 1);
      end if;
    end if;
  end process;

-- Toggle Pops Between Pos and Neg
  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1')then
      if (LLink_Rst = '1' or RX_ChannelRST='1') then
        Toggle <= '0';
      elsif (rx_rdpop_i = '1') then
        Toggle <= not Toggle;
      end if;
    end if;
  end process;

end implementation;
