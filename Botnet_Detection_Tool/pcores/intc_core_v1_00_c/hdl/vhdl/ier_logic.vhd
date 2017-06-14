-------------------------------------------------------------------------------
-- $Id: ier_logic.vhd,v 1.3 2003/01/16 21:55:20 tise Exp $
-------------------------------------------------------------------------------
-- ier_logic - entity / architecture pair
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
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
-- Filename:        ier_logic.vhd.vhd
-- Version:         v1.00c
-- Description:     generate logic for ier and sie and cie
-- 
-------------------------------------------------------------------------------
-- Structure:   
--             intc.vhd
--               mb_intc_top.vhd
--                 regs.vhd
--                   ier_logic.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/20/2001  changed to little endian so regs can be reduced to
--                       the size of the number of int inputs
--  jam      11/04/2002      -- roll to rev c
-- 
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_cmb" 
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
library intc_core_v1_00_c;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity ier_logic is
  generic (
            C_WIDTH     : positive := 1;
            C_HAS_SIE   : boolean  := false;
            C_HAS_CIE   : boolean  := false;
            C_SEL_WIDTH : positive := 2
          );
  port (
         Data_in  : in  std_logic_vector(C_WIDTH - 1 downto 0);
         IER_in   : in  std_logic_vector(C_WIDTH - 1 downto 0);
         IER_sel  : in  ier_sel_type;
         IER_data : out std_logic_vector(C_WIDTH - 1 downto 0)
       );

end ier_logic;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of ier_logic is
 
  function ier_srcs(sie,cie : boolean)
   return positive is
    variable ret_val : positive := 1;
  begin
    if sie then
      ret_val := ret_val + 1;
    end if;
    if cie then
      ret_val := ret_val + 1;
    end if;
    return ret_val;
  end ier_srcs;
 
  constant NUM_IER_SRCS : positive := ier_srcs(C_HAS_SIE,C_HAS_CIE);

  signal sie_data         : std_logic_vector(C_WIDTH - 1 downto 0);
  signal cie_data         : std_logic_vector(C_WIDTH - 1 downto 0);
  signal ier_sie_cie_data : std_logic_vector(C_WIDTH*NUM_IER_SRCS - 1 downto 0);
  
  component bus_mux_le is
    generic
    (
      C_W  : integer;
      C_SW : integer;
      C_N  : integer
    );
    port
    (
      Buses_in : in  std_logic_vector(((C_W * C_N) - 1) downto 0);
      Sel      : in  std_logic_vector(C_SW - 1 downto 0);
      Bus_out  : out std_logic_vector(C_W - 1 downto 0)
    );
  end component bus_mux_le;

begin
 
  IER_DATA_MUX_I: bus_mux_le
    generic map
    (
      C_W  => C_WIDTH,
      C_SW => C_SEL_WIDTH,
      C_N  => NUM_IER_SRCS
    )
    port map
    (
      Buses_in => ier_sie_cie_data,
      Sel      => IER_sel,
      Bus_out  => IER_data
   );

  IER_1_GEN:
  if not C_HAS_SIE and not C_HAS_CIE
  generate
    ier_sie_cie_data <= Data_in;
  end generate IER_1_GEN;

  IER_2S_GEN:
  if C_HAS_SIE and not C_HAS_CIE
  generate
    sie_data <= IER_in or Data_in;
    ier_sie_cie_data <= sie_data & Data_in;
  end generate IER_2S_GEN;
 
  IER_2C_GEN:
  if not C_HAS_SIE and C_HAS_CIE
  generate
    cie_data <= IER_in and not Data_in;
    ier_sie_cie_data <= cie_data & Data_in;
  end generate IER_2C_GEN;
 
  IER_3_GEN:
  if C_HAS_SIE and C_HAS_CIE
  generate
    sie_data <= IER_in or Data_in;
    cie_data <= IER_in and not Data_in;
    ier_sie_cie_data <= cie_data & sie_data & Data_in;
  end generate IER_3_GEN;
 
end imp;
