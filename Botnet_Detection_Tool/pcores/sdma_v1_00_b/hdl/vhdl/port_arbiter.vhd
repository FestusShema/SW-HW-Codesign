---------------------------------------------------------------------------
-- port_arbiter
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
-- Filename:          port_arbiter.vhd
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
entity port_arbiter is
    generic(
        TIMEOUTPERIOD           : integer := 255  -- Default to 256 Clock Cycles
    );
    port(
        LLink_Clk               : in  std_logic;
        LLink_Rst               : in  std_logic;
        TX_Port_Request         : in  std_logic;      
        TX_Port_Grant           : out std_logic;      
        TX_Port_Busy            : in  std_logic;      
        RX_Port_Request         : in  std_logic;      
        RX_Port_Grant           : out std_logic;      
        RX_Port_Busy            : in  std_logic;      
        TXNRX_Active            : out std_logic;      
        Timeout                 : out std_logic       
    );
end port_arbiter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of port_arbiter is


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal busy                 : std_logic;
signal timeoutcounter       : std_logic_vector(9 downto 0);
signal tx_port_grant_i      : std_logic;
signal rx_port_grant_i      : std_logic;
signal txnrx_active_i       : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

TX_Port_Grant   <= tx_port_grant_i  ;
RX_Port_Grant   <= rx_port_grant_i  ;
TXNRX_Active    <= txnrx_active_i   ;


  Busy <= tx_port_grant_i or TX_Port_Busy or rx_port_grant_i or RX_Port_Busy;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1' or tx_port_grant_i = '1') then
        tx_port_grant_i   <= '0';
      else
        if (Busy = '0' and TX_Port_Request = '1' and (txnrx_active_i = '0' or RX_Port_Request = '0')) then
          tx_port_grant_i <= '1';

        end if;
      end if;
    end if;
  end process;

  process(LLink_Clk)
  begin

    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1' or rx_port_grant_i = '1') then
        rx_port_grant_i   <= '0';
      else
        if (Busy = '0' and RX_Port_Request = '1' and (txnrx_active_i = '1' or TX_Port_Request = '0')) then
          rx_port_grant_i <= '1';
        end if;
      end if;
    end if;
  end process;


  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1') then
      if (LLink_Rst = '1') then
        txnrx_active_i   <= '0';
      else
        if (tx_port_grant_i = '1' or rx_port_grant_i = '1') then
          txnrx_active_i <= tx_port_grant_i;
        end if;
      end if;
    end if;
  end process;

  Timeout <= '1' when (to_integer(unsigned(TimeoutCounter)) = TIMEOUTPERIOD) else '0';
-- Timeout = 0;

  process(LLink_Clk)
  begin
    if(LLink_Clk'event and LLink_Clk = '1' )then
      if (LLink_Rst = '1') then
        TimeoutCounter <= (others => '0');
      elsif ((TX_Port_Busy = '1' and RX_Port_Request = '1') or (RX_Port_Busy = '1' and TX_Port_Request = '1')) then
        TimeoutCounter    <= std_logic_vector(unsigned(TimeoutCounter) + 1);
      else
        TimeoutCounter <= (others => '0');
      end if;
    end if;
  end process;
end implementation;
