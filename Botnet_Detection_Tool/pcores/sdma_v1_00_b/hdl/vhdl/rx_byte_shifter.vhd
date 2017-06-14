-------------------------------------------------------------------------------
-- rx_byte_shifter.vhd
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
-- Filename:        rx_byte_shifter.vhd
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
entity rx_byte_shifter is
  port(
    -- Global Inputs
    LLink_Clk           : in  std_logic;                      -- I
    LLink_Rst           : in  std_logic;                      -- I
    -- Control Inputs
    HoldReg_CE    : in  std_logic;                      -- I
    Byte_Sel      : in  std_logic_vector(1 downto 0);   -- I (1:0)
    CE            : in  std_logic_vector(7 downto 0);   -- I (7:0)
    -- Data Inputs
    Rx_DataIn     : in  std_logic_vector(31 downto 0);  -- I (31:0)
    -- Data Outputs
    WrDataBus_Pos : out std_logic_vector(31 downto 0);  -- O (31:0)
    WrDataBus_Neg : out std_logic_vector(31 downto 0)   -- O (31:0)
    );
end rx_byte_shifter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of rx_byte_shifter is

-------------------------------------------------------------------------------
-- Function declarations
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
signal   HoldRegData : std_logic_Vector(31 downto 0);

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
   
   process(LLink_Clk)
   begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
       if(LLink_Rst='1') then
         HoldRegData <= (others => '0');
       else
         if (HoldReg_CE='1') then
           HoldRegData <= Rx_DataIn;
         end if;
       end if;
     end if;
   end process;

RX_BYTE_SHFT_31_24_POS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Pos(31 downto 24) <= (others => '0');
            else
                if (CE(7) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Pos(31 downto 24) <= HoldRegData(31 downto 24);
                        when "01" => 
                            WrDataBus_Pos(31 downto 24) <= HoldRegData(7 downto 0);
                        when "10" => 
                            WrDataBus_Pos(31 downto 24) <= HoldRegData(15 downto 8);
                        when "11" => 
                            WrDataBus_Pos(31 downto 24) <= HoldRegData(23 downto 16);
                        when others => 
                            WrDataBus_Pos(31 downto 24) <= (others => '0');
                    end case; 
                end if;
            end if;
        end if;  
    end process RX_BYTE_SHFT_31_24_POS;

RX_BYTE_SHFT_23_16_POS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Pos(23 downto 16) <= (others => '0');
            else
                if (CE(6) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Pos(23 downto 16) <= HoldRegData(23 downto 16);
                        when "01" => 
                            WrDataBus_Pos(23 downto 16) <= HoldRegData(31 downto 24);
                        when "10" => 
                            WrDataBus_Pos(23 downto 16) <= HoldRegData(7 downto 0);
                        when "11" => 
                            WrDataBus_Pos(23 downto 16) <= HoldRegData(15 downto 8);
                        when others =>
                            WrDataBus_Pos(23 downto 16) <= (others => '0');
                    end case;  -- case(Byte_Sel)
                end if;  -- if (CE(6))
            end if;  -- else downto  !if(LLink_Rst)
        end if;  -- always @ (posedge LLink_Clk)
    end process RX_BYTE_SHFT_23_16_POS;

RX_BYTE_SHFT_15_8_POS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Pos(15 downto 8) <= (others => '0');
            else
                if (CE(5) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Pos(15 downto 8) <= HoldRegData(15 downto 8);
                        when "01" => 
                            WrDataBus_Pos(15 downto 8) <= HoldRegData(23 downto 16);
                        when "10" => 
                            WrDataBus_Pos(15 downto 8) <= HoldRegData(31 downto 24);
                        when "11" => 
                            WrDataBus_Pos(15 downto 8) <= HoldRegData(7 downto 0);
                        when others => 
                            WrDataBus_Pos(15 downto 8) <= (others => '0');
                    end case;  -- case(Byte_Sel)
                end if;  -- if (CE(5))
            end if;  -- else downto  !if(LLink_Rst)
        end if;  -- always @ (posedge LLink_Clk)
    end process RX_BYTE_SHFT_15_8_POS;

RX_BYTE_SHFT_7_0_POS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Pos(7 downto 0) <= (others => '0');
            else
                if (CE(4) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Pos(7 downto 0) <= HoldRegData(7 downto 0);
                        when "01" => 
                            WrDataBus_Pos(7 downto 0) <= HoldRegData(15 downto 8);
                        when "10" => 
                            WrDataBus_Pos(7 downto 0) <= HoldRegData(23 downto 16);
                        when "11" => 
                            WrDataBus_Pos(7 downto 0) <= HoldRegData(31 downto 24);
                        when others =>
                            WrDataBus_Pos(7 downto 0) <= (others => '0');
                    end case;  -- case(Byte_Sel)
                end if;  -- if (CE(4))
            end if;  -- else downto  !if(LLink_Rst)
        end if;  -- always @ (posedge LLink_Clk)
    end process RX_BYTE_SHFT_7_0_POS;

-------------------------------------------------------------------------------------------

RX_BYTE_SHFT_31_24_NEG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Neg(31 downto 24) <= (others => '0');
            else
                if (CE(3) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Neg(31 downto 24) <= HoldRegData(31 downto 24);
                        when "01" => 
                            WrDataBus_Neg(31 downto 24) <= HoldRegData(7 downto 0);
                        when "10" => 
                            WrDataBus_Neg(31 downto 24) <= HoldRegData(15 downto 8);
                        when "11" => 
                            WrDataBus_Neg(31 downto 24) <= HoldRegData(23 downto 16);
                        when others => 
                            WrDataBus_Neg(31 downto 24) <= (others => '0');
                    end case; 
                end if;
            end if;
        end if;  
    end process RX_BYTE_SHFT_31_24_NEG;

RX_BYTE_SHFT_23_16_NEG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Neg(23 downto 16) <= (others => '0');
            else
                if (CE(2) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Neg(23 downto 16) <= HoldRegData(23 downto 16);
                        when "01" => 
                            WrDataBus_Neg(23 downto 16) <= HoldRegData(31 downto 24);
                        when "10" => 
                            WrDataBus_Neg(23 downto 16) <= HoldRegData(7 downto 0);
                        when "11" => 
                            WrDataBus_Neg(23 downto 16) <= HoldRegData(15 downto 8);
                        when others =>
                            WrDataBus_Neg(23 downto 16) <= (others => '0');
                    end case;  
                end if;  
            end if;  
        end if;  
    end process RX_BYTE_SHFT_23_16_NEG;


RX_BYTE_SHFT_15_8_NEG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Neg(15 downto 8) <= (others => '0');
            else
                if (CE(1) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Neg(15 downto 8) <= HoldRegData(15 downto 8);
                        when "01" => 
                            WrDataBus_Neg(15 downto 8) <= HoldRegData(23 downto 16);
                        when "10" => 
                            WrDataBus_Neg(15 downto 8) <= HoldRegData(31 downto 24);
                        when "11" => 
                            WrDataBus_Neg(15 downto 8) <= HoldRegData(7 downto 0);
                        when others => 
                            WrDataBus_Neg(15 downto 8) <= (others => '0');
                    end case; 
                end if;  
            end if;  
        end if;  
    end process RX_BYTE_SHFT_15_8_NEG;

RX_BYTE_SHFT_7_0_NEG : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1') then
                WrDataBus_Neg(7 downto 0) <= (others => '0');
            else
                if (CE(0) = '1') then
                    case Byte_Sel is
                        when "00" => 
                            WrDataBus_Neg(7 downto 0) <= HoldRegData(7 downto 0);
                        when "01" => 
                            WrDataBus_Neg(7 downto 0) <= HoldRegData(15 downto 8);
                        when "10" => 
                            WrDataBus_Neg(7 downto 0) <= HoldRegData(23 downto 16);
                        when "11" => 
                            WrDataBus_Neg(7 downto 0) <= HoldRegData(31 downto 24);
                        when others =>
                            WrDataBus_Neg(7 downto 0) <= (others => '0');
                    end case;  
                end if;  
            end if;  
        end if;  
    end process RX_BYTE_SHFT_7_0_NEG;


end implementation;
