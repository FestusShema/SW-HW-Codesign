-------------------------------------------------------------------------------
-- $Id: bus_mux_le.vhd,v 1.3 2003/01/16 21:55:20 tise Exp $
-------------------------------------------------------------------------------
-- bus_mux_le - entity / architecture pair
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
-- Filename:        bus_mux_le.vhd
-- Version:         v1.00c
-- Description:     little-endian bus mux for intc
-- 
-------------------------------------------------------------------------------
-- Structure:
--               (used in both regs.vhd and ier_logic)
--                  bus_mux_le.vhd
-- 
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
 
entity bus_mux_le is
  generic (
           C_W  : integer := 32;
           C_SW : integer := 1;
           C_N  : integer := 2
          );
  port (
        Buses_in : in  std_logic_vector(((C_W * C_N) - 1) downto 0);
        Sel      : in  std_logic_vector(C_SW - 1 downto 0);
        Bus_out  : out std_logic_vector(C_W - 1 downto 0)
       );
 
end bus_mux_le;
 
------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------
 
architecture imp of bus_mux_le is
begin
  MUX:
  process (Buses_in, Sel)
  begin
    Bus_out <= (others => '0');
    for i in 0 to (C_N - 1)
    loop
      if Sel = Conv_Std_Logic_Vector(i, C_SW) then
        Bus_out <= Buses_in ((C_W * (i + 1)) - 1 downto C_W * i);
      end if;
    end loop;
  end process;
 
end imp;

