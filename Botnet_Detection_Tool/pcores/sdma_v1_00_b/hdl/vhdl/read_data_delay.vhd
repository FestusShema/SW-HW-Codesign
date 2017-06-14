---------------------------------------------------------------------------
-- read_data_delay 
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
-- Filename:          read_data_delay.vhd
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
entity read_data_delay is
    generic(
        C_PI_RDDATA_DELAY           : integer:= 0;
        C_PI2LL_CLK_RATIO           : integer:= 1
    );
    port(
        LLink_Clk                   : in std_logic;        
        LLink_Rst                   : in std_logic;        
        PI_RdPop                    : out std_logic;       
        PI_Empty                    : in std_logic;        
        SDMA_RdPop                  : in std_logic;        
        SDMA_Empty                  : out std_logic;       
        SDMA_CL8R_Start             : in std_logic;        
        SDMA_B16R_Start             : in std_logic;        
        Delay_Reg_CE                : out std_logic;       
        Delay_Reg_Sel               : out std_logic_Vector(1 downto 0)           
    );
end read_data_delay;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of read_data_delay is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant DLY_TC             :  std_logic_vector(1 downto 0) 
                                := std_logic_vector(
                                to_unsigned(C_PI_RDDATA_DELAY 
                                / C_PI2LL_CLK_RATIO,2));
  
-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal popcount             : std_logic_vector(4 downto 0);
signal delaycount           : std_logic_vector(1 downto 0);
signal delay_cnt_inc        : std_logic;
signal delay_cnt_dec        : std_logic;

signal early_pop            : std_logic;
signal early_pop1           : std_logic;
signal early_pop2           : std_logic;
signal pop_d1               : std_logic;
signal pop_d2               : std_logic;
signal delay_reg_ce_i       : std_logic;
signal pi_rdpop_i           : std_logic;
signal sdma_empty_i         : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
Delay_Reg_CE <= delay_reg_ce_i;
PI_RdPop     <= pi_rdpop_i;
  
GEN_rx_rddata_delay2 : if ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) generate
          sdma_empty_i   <= '0' when (PI_Empty='0' and early_pop2='0') or (popcount = "00010") or (popcount = "00001")
                     else  '1';
          pi_rdpop_i      <= (early_pop2 or SDMA_RdPop) and not PI_Empty;
          delay_reg_ce_i<= pop_d2;
          Delay_Reg_Sel <= delaycount;
          early_pop     <= early_pop2;
end generate;

GEN_rx_drdata_delay1 : if (((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                        or ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
          sdma_empty_i   <='0' when(PI_Empty='0' and early_pop1='0') or (popcount = "00001")
                     else '1';
                   
          pi_rdpop_i      <= (early_pop1 or SDMA_RdPop) and not PI_Empty;
          delay_reg_ce_i<= pop_d1;
          Delay_Reg_Sel <= delaycount;
          early_pop     <= early_pop1;
end generate;

GEN_rddata_delay0 : if not((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 1)) 
                  and not(((C_PI_RDDATA_DELAY = 1) and (C_PI2LL_CLK_RATIO = 1)) 
                  or      ((C_PI_RDDATA_DELAY = 2) and (C_PI2LL_CLK_RATIO = 2))) generate
          sdma_empty_i   <= PI_Empty;
          pi_rdpop_i      <= SDMA_RdPop;
          delay_reg_ce_i<= '0';
          Delay_Reg_Sel <= (others => '0');
          early_pop     <= '0';
end generate;

REG_EMPTY : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                SDMA_Empty <= '1';
            else
              SDMA_Empty <= sdma_empty_i;
            end if;
        end if;
    end process REG_EMPTY; 

EARLY_POP1_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                early_pop1 <= '0';
            elsif(SDMA_B16R_Start = '1' or SDMA_CL8R_Start='1')then
                early_pop1 <= '1';
            elsif(PI_Empty='0')then
                early_pop1 <= '0';
            end if;
        end if;
    end process EARLY_POP1_PROCESS;
            
EARLY_POP2_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                early_pop2 <= '0';
            elsif(SDMA_B16R_Start = '1' or SDMA_CL8R_Start = '1')then
                early_pop2 <= '1';
            elsif(PI_Empty='0' and early_pop1='0')then
                early_pop2 <= '0';
            end if;
        end if;
    end process EARLY_POP2_PROCESS;
        

POP_COUNT_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                popcount <= (others => '0');
            elsif (SDMA_B16R_Start='1')then
                popcount <= "10000";    --16
            elsif (SDMA_CL8R_Start='1')then
                popcount <= "00100";     --4
            elsif (SDMA_RdPop='1')then
                popcount <= std_logic_vector(unsigned(popcount) - 1);
   
            end if;
        end if;
    end process POP_COUNT_PROCESS;

REG_POP : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1')then
                pop_d1 <= '0';
                pop_d2 <= '0';
            else
                pop_d1 <= pi_rdpop_i;
                pop_d2 <= pop_d1;
            end if;
        end if;
    end process REG_POP;
    

delay_cnt_inc <= delay_reg_ce_i when (delaycount < DLY_TC)
            else '0';



delay_cnt_dec <= SDMA_RdPop when (delaycount /= "00")
           else '0';
   
DELAY_COUNTER : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(llink_rst = '1' 
            or SDMA_B16R_Start = '1' 
            or SDMA_CL8R_Start = '1')then
                delaycount <= (others => '0');
            elsif(delay_cnt_inc = '1' and delay_cnt_dec = '0')then
                delaycount <= std_logic_vector(unsigned(delaycount) + 1);
            elsif(delay_cnt_inc = '0' and delay_cnt_dec = '1')then
                delaycount <= std_logic_vector(unsigned(delaycount) - 1);
            end if;
        end if;
    end process DELAY_COUNTER;
    
end implementation;          
