-------------------------------------------------------------------------------
-- $Id: lvl_det_bit.vhd,v 1.4 2003/06/29 21:25:38 jcanaris Exp $
-------------------------------------------------------------------------------
-- lvl_det_bit - entity / architecture pair
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
-- Filename:        lvl_det_bit.vhd
-- Version:         v1.00c
-- Description:     generate level detector for a bit
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 int_det.vhd
--                   detect_intr.vhd
--                     lvl_det_bit.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/20/2001  fixed active low generate
--  jam      11/06/2001  changed type of C_LVL_POLARITY from enumerationt type
--                       to std_logic
--  jam      12/04/2001  changed to C_FAMILY
--  jam      09/03/2002  added Xon generic
--  jam      11/04/2002  changed fdce to fdre
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
library unisim;
library intc_core_v1_00_c;
use ieee.std_logic_1164.all;
use unisim.all;
use intc_core_v1_00_c.intc_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity lvl_det_bit is
  generic
  (
    C_FAMILY       : string;
    C_Y            : integer;
    C_X            : integer;
    C_U_SET        : string;
    C_LVL_POLARITY : std_logic := '1'
  );
  port
  (
    Lvl_intr    : in  std_logic;
    Clk         : in  std_logic;
    Clear       : in  std_logic;
    Active_intr : out std_logic
  );

end lvl_det_bit;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of lvl_det_bit is

  component fdre is
    port
    (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      R  : in  std_logic;
      D  : in  std_logic
    );
  end component fdre;

  signal int_sig    : std_logic;
  signal clk_enable : std_logic;

begin

  clk_enable <= not int_sig;

  ACTIVE_HIGH_GEN:
  if C_LVL_POLARITY = '1'
  generate
    ACTIVE_HIGH_LVL_I : fdre
      port map
      (
        Q  => int_sig,
        C  => Clk,
        CE => clk_enable,
        R  => Clear,
        D  => Lvl_intr
      );
  end generate ACTIVE_HIGH_GEN;

  ACTIVE_LOW_GEN:
  if C_LVL_POLARITY = '0'
  generate
    signal int_in : std_logic;
  begin
    int_in <= not Lvl_intr;
    ACTIVE_LOW_LVL_I : fdre
      port map
      (
        Q  => int_sig,
        C  => Clk,
        CE => clk_enable,
        R  => Clear,
        D  => int_in
      );
  end generate ACTIVE_LOW_GEN;

  Active_intr <= int_sig;

end imp;
