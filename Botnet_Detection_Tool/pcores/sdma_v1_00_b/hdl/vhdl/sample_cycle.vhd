---------------------------------------------------------------------------
-- sample_cycle.vhd - Clock Ratio and Phase detection Logic
---------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2005 by Xilinx, Inc. All rights reserved.               **
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
-- Filename:          sample_cycle.vhd
-- Description:
--       This sample cycle generator counts the number of clock edges
--       of the fast_clk in two slow_clk cycles and uses half of that as
--       the slow_clk/fast_clk ratio to generate the slow_clk sample cycle
--       signal in the next two slow_clk cycles. This scheme is used mainly to
--       provide a robust mechanism to accomocate for a 1:1 ratio between
--       slow_clk and fast_clks. The sample cycle signal is aligned to the
--       rising edge of the fast clock and is asserted for 1 fast_clk in the
--       cycle prior to the rising edge of slow_clk.            
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
-- Author:      KD
-- History:
--  KD        01/10/2007      - Initial Version
--
--  GAB       01/24/2007      - converted to vhdl
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;


-------------------------------------------------------------------------------
entity sample_cycle is
    port(
        fast_clk        : in  std_logic;
        slow_clk        : in  std_logic;
        sample_cycle    : out std_logic
    );

end sample_cycle;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of sample_cycle is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal/Type Declarations
-------------------------------------------------------------------------------

signal clear_count          : std_logic;
signal clear_count_p1       : std_logic;
signal new_count            : std_logic_vector(0 to 4) := (others => '0');
signal count                : std_logic_vector(0 to 4) := (others => '0');
signal ratio                : std_logic_vector(0 to 4) := (others => '0');
signal ratio_minus1         : std_logic_vector(0 to 4) := (others => '0');
signal slow_clk_div2        : std_logic := '0'; -- slow_clk_div2 = half freq. of slow_clk Clock
signal slow_clk_div2_del    : std_logic := '0';
signal clk_1_to_1           : std_logic := '0';
signal scnd_slwclk_pair     : std_logic_vector(0 to 4) := (others => '0');
signal frst_slwclk_pair     : std_logic_vector(0 to 4) := (others => '0');

-------------------------------------------------------------------------------
begin
   
-- #1 is for simulation, build a toggle FF in
-- slow_clk. This creates a half frequency signal.
SLOW_CLOCK_TGL : process(slow_clk)
    begin
        if(slow_clk'EVENT and slow_clk='1')then
            slow_clk_div2 <= not slow_clk_div2;
        end if;
    end process SLOW_CLOCK_TGL;
    
-- align slow clocked toggle signal into fast clk.
ALIGN_TO_FAST : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            slow_clk_div2_del <= slow_clk_div2; 
        end if;
    end process ALIGN_TO_FAST;

-- Detect the rising edge of the slow_clk_div2 to clear the slow_clk sample counter.
clear_count <= (slow_clk_div2 and not slow_clk_div2_del); 
            
SMPL_COUNTER : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(clear_count = '1')then
                count <= (others => '0');
            else
                count <= std_logic_vector(unsigned(count) + 1);
            end if;
        end if;
    end process SMPL_COUNTER;

GRAB_RATIO : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(clear_count = '1')then
                ratio <= count;
            end if;
        end if;
    end process GRAB_RATIO;

-- Create a new counter that runs earlier than above counter.
-- This counter runs ahead to find the cycle just before
-- the slow clock's rising edge transitions

RATIO_SUB1 : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            ratio_minus1 <= std_logic_vector(unsigned(ratio) - 1);
        end if;
    end process RATIO_SUB1;

clear_count_p1 <= '1' when count(0 to 4) = ratio_minus1
             else '0';

NEW_COUNTER : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clear_count_p1='1')then
                new_count <= "00001";
            else       
                new_count <= std_logic_vector(unsigned(new_count) + 1);
            end if;
        end if;
    end process NEW_COUNTER;
       

CLK1TO1 : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if(ratio(0 to 3) = "0000")then 
                clk_1_to_1 <= '1';
            else
                clk_1_to_1 <= '0';
            end if;
        end if;
    end process CLK1TO1;

-- Generate sample_cycle signal and drive from the output of a FF for better timing.
-- implement sample_cycle as a Flip Flop with Set input

scnd_slwclk_pair <= ratio(0 to 3) & '1';
frst_slwclk_pair <= '0' & ratio(0 to 3);

SMPL_CYCLE : process(fast_clk)
    begin
        if(fast_clk'EVENT and fast_clk='1')then
            if (clk_1_to_1 = '1')then
                sample_cycle <= '1';                       -- 1:1 slow_clk/fast_clk ratios
            elsif(new_count = scnd_slwclk_pair or          -- Second slow_clk cycle in the pair
                  new_count = frst_slwclk_pair)then        -- First slow_clk cycle in the pair
                sample_cycle <= '1';
            else
                sample_cycle <= '0';
            end if;
        end if;
    end process SMPL_CYCLE;

    
end implementation;

