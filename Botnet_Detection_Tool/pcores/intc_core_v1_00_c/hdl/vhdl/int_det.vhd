-------------------------------------------------------------------------------
-- $Id: int_det.vhd,v 1.5 2003/08/26 17:09:09 mccoyj Exp $
-------------------------------------------------------------------------------
-- int_det - entity / architecture pair
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
-- Filename:        int_det.vhd.vhd
-- Version:         v1.00c
-- Description:     interrupt detection logic
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 int_det.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/20/2001  changed to little endian for everything to allow
--                       regs to be implemented with register sizes equal
--                       to the number of interrupt inputs
--  jam      11/06/2001  changed type of C_KIND_OF_INTR, C_KIND_OF_EDGE, and
--                       C_KIND_OF_LVL from arrays of enumerated values to
--                       std_logic_vectors because platgen can't handle
--                       enumerated types and xst can't handle functions
--                       returning arrays of enumerated values
--  jam      12/04/2001  changed to C_FAMILY
--  jam      11/04/2002      -- roll to rev c
--  jam      11/19/2002  fixed enabling of hw ints for low level inputs
--  jam      07/15/2003  fixed problem with low level interrupt inputs and sw
--                       generated inputs when low level specified
--  jam      08/25/2003  fixed problem with falling edge interrupt inputs -
--                       only had half the cases covered
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
--                           anything else is n/a
--
--         C_KIND_OF_LVL  -  1 = high
--                           0 = low
--                           anything else is n/a
--
------------------------------------------------------------------------------

library ieee;
library intc_core_v1_00_c;
library unisim;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;
use unisim.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity int_det is
  generic
  (
    C_FAMILY       : string   := "virtex2";
    C_Y            : integer  := 0;
    C_X            : integer  := 0;
    C_U_SET        : string   := "intc";
    C_NUM_INTS     : positive := 2;
    C_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                           "11111111111111111111111111111111";
    C_KIND_OF_EDGE : std_logic_vector(WORD_SIZE - 1 downto 0)   :=
                                           "11111111111111111111111111111111";
    C_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0)    :=
                                           "11111111111111111111111111111111"
  );
  port
  (
    Clk           : in  std_logic;
    Rst           : in  std_logic;
    Int           : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Hw_int_enable : in  std_logic;
    Sw_ints       : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Intr_ack      : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Int_enables   : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Enabled_ints  : out std_logic_vector(C_NUM_INTS - 1 downto 0);
    Ints_pending  : out std_logic_vector(C_NUM_INTS - 1 downto 0);
    Int_status    : out std_logic_vector(C_NUM_INTS - 1 downto 0)
  );

end int_det;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of int_det is

  signal clear          : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal hw_int         : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal interrupts     : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal rst_bus        : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal sw_int         : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal active_ints    : std_logic_vector(C_NUM_INTS - 1 downto 0);

  component detect_intr
    generic
    (
      C_FAMILY       : string;
      C_Y            : integer;
      C_X            : integer;
      C_U_SET        : string;
      C_NUM_INTS     : positive;
      C_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0);
      C_KIND_OF_EDGE : std_logic_vector(WORD_SIZE - 1 downto 0);
      C_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0)
    );
    port
    (
      Clk         : in  std_logic;
      Clear       : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Intr        : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Active_ints : out std_logic_vector(C_NUM_INTS - 1 downto 0);
      Int_status  : out std_logic_vector(C_NUM_INTS - 1 downto 0)
    );
  end component;

begin

  DETECT_INTR_I: detect_intr
    generic map
    (
       C_FAMILY       => C_FAMILY,
       C_Y            => C_Y,
       C_X            => C_X,
       C_U_SET        => C_U_SET,
       C_NUM_INTS     => C_NUM_INTS,
       C_KIND_OF_INTR => C_KIND_OF_INTR,
       C_KIND_OF_EDGE => C_KIND_OF_EDGE,
       C_KIND_OF_LVL  => C_KIND_OF_LVL
    )
    port map
    (
      Clk         => Clk,
      Clear       => clear,
      Intr        => interrupts,
      Active_ints => active_ints,
      Int_status  => Int_status
    );

  HW_SW_INTS_GEN:
  for i in 0 to C_NUM_INTS - 1
  generate
    LEVEL_INTS_GEN:
    if C_KIND_OF_INTR(i) = '0'
    generate
      LOW_LEVEL_GEN:
      if C_KIND_OF_LVL(i) = '0'
      generate
        hw_int(i) <= (Hw_int_enable and Int(i)) or not Hw_int_enable;
        sw_int(i) <= (not Hw_int_enable and Sw_ints(i)) or Hw_int_enable;
      end generate LOW_LEVEL_GEN;
      HIGH_LEVEL_GEN:
      if C_KIND_OF_LVL(i) = '1'
      generate
        hw_int(i) <= Hw_int_enable and Int(i);
        sw_int(i) <= not Hw_int_enable and Sw_ints(i);
      end generate HIGH_LEVEL_GEN;
    end generate LEVEL_INTS_GEN;
    EDGE_INTS_GEN:
    if C_KIND_OF_INTR(i) = '1'
    generate
      FALLING_EDGE_GEN:
      if C_KIND_OF_EDGE(i) = '0'
      generate
        hw_int(i) <= (Hw_int_enable and Int(i)) or not Hw_int_enable;
        sw_int(i) <= (not Hw_int_enable and Sw_ints(i)) or Hw_int_enable;
      end generate FALLING_EDGE_GEN;
      RISING_EDGE_GEN:
      if C_KIND_OF_EDGE(i) = '1'
      generate
        hw_int(i) <= Hw_int_enable and Int(i);
        sw_int(i) <= not Hw_int_enable and Sw_ints(i);
      end generate RISING_EDGE_GEN;
    end generate EDGE_INTS_GEN;
  end generate HW_SW_INTS_GEN;

  interrupts <= hw_int when Hw_int_enable = '1' else sw_int;

  rst_bus <= (others => Rst);

  clear <= Intr_ack or rst_bus;

  Enabled_ints <= active_ints and Int_enables;

  Ints_pending <= active_ints and Int_enables;

end imp;

