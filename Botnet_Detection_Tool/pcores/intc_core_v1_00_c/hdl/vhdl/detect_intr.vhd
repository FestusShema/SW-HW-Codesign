-------------------------------------------------------------------------------
-- $Id: detect_intr.vhd,v 1.3 2003/01/16 21:55:20 tise Exp $
-------------------------------------------------------------------------------
-- detect_intr - entity / architecture pair
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
-- Filename:        detect_intr.vhd.vhd
-- Version:         v1.00c
-- Description:     generate the interrupt detection logic
--
-------------------------------------------------------------------------------
-- Structure:
--
--             intc.vhd
--               mb_intc.vhd
--                 int_det.vhd
--                   detect_intr.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/20/2001  changed to little endian only to allow regs to be
--                       limited to the number of interrupt inputs
--  jam      11/06/2001  changed array of enumerated types for C_KIND_OF_INTR,
--                       C_KIND_OF_EDGE, and C_KIND_OF_LVL to std_logic_vector
--                       because platgen can't do enumerated types and xst
--                       can't handle functions that return array of enumerated
--                       values
--  jam      12/04/2001  changed to C_FAMILY
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
-- Notes:
--         C_KIND_OF_INTR -  1 = edge
--                           0 = level
--                           anything else is none
--
--         C_KIND_OF_EDGE -  1 = rising
--                           0 = falling
--                           anything else is none
--
--         C_KIND_OF_LVL  -  1 = high
--                           0 = low
--                           anything else is none
--
-------------------------------------------------------------------------------

library ieee;
library intc_core_v1_00_c;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;

-------------------------------------------------------------------------------
-- Entity
-------------------------------------------------------------------------------

entity detect_intr is
  generic
  (
    C_FAMILY       : string   := "virtex2";
    C_Y            : integer  := 0;
    C_X            : integer  := 0;
    C_U_SET        : string   := "intc";
    C_NUM_INTS     : positive := 1;
    C_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0) := X"00000001";
    C_KIND_OF_EDGE : std_logic_vector(WORD_SIZE - 1 downto 0) := X"00000001";
    C_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0) := X"00000001"
  );
  port
  (
    Clk         : in  std_logic;
    Intr        : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Clear       : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Active_ints : out std_logic_vector(C_NUM_INTS - 1 downto 0);
    Int_status  : out std_logic_vector(C_NUM_INTS - 1 downto 0)
  );
end;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of detect_intr is

  component edge_det_bit is
    generic
    (
      C_FAMILY        : string;
      C_Y             : integer;
      C_X             : integer;
      C_U_SET         : string;
      C_EDGE_POLARITY : std_logic
    );
    port
    (
      Clk         : in  std_logic;
      Clear       : in  std_logic;
      Edge_intr   : in  std_logic;
      Active_intr : out std_logic
    );
  end component edge_det_bit;

  component lvl_det_bit is
    generic
    (
      C_FAMILY       : string;
      C_Y            : integer;
      C_X            : integer;
      C_U_SET        : string;
      C_LVL_POLARITY : std_logic
    );
    port
    (
      Clk         : in  std_logic;
      Clear       : in  std_logic;
      Lvl_intr    : in  std_logic;
      Active_intr : out std_logic
    );
  end component lvl_det_bit;

  signal interrupts : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal status     : std_logic_vector(C_NUM_INTS - 1 downto 0);

begin

  INTR_DETECT_GEN:
  for i in 0 to C_NUM_INTS - 1
  generate

    EDGE_DETECT_GEN:
    if C_KIND_OF_INTR(i) = '1'
    generate
      EDGE_DET_BIT_I : edge_det_bit
        generic map
        (
          C_FAMILY        => C_FAMILY,
          C_Y             => C_Y,
          C_X             => C_X,
          C_U_SET         => C_U_SET,
          C_EDGE_POLARITY => C_KIND_OF_EDGE(i)
        )
        port map
        (
          Clk         => Clk,
          Clear       => Clear(i),
          Edge_intr   => Intr(i),
          Active_intr => interrupts(i)
        );
    end generate EDGE_DETECT_GEN;

    LVL_DETECT_GEN:
    if C_KIND_OF_INTR(i) = '0'
    generate
      LVL_DET_BIT_I : lvl_det_bit
        generic map
        (
          C_FAMILY       => C_FAMILY,
          C_Y            => C_Y,
          C_X            => C_X,
          C_U_SET        => C_U_SET,
          C_LVL_POLARITY => C_KIND_OF_LVL(i)
        )
        port map
        (
          Clk         => Clk,
          Clear       => Clear(i),
          Lvl_intr    => Intr(i),
          Active_intr => interrupts(i)
        );
    end generate LVL_DETECT_GEN;

    NO_DETECT_GEN:
    if C_KIND_OF_INTR(i) /= '1' and C_KIND_OF_INTR(i) /= '0'
    generate
      interrupts(i) <= '0';
    end generate NO_DETECT_GEN;

    status(i) <= interrupts(i);

  end generate INTR_DETECT_GEN;

  Active_ints <= interrupts;
  Int_status  <= status;

end;

