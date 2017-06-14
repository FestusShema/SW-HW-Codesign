-------------------------------------------------------------------------------
-- $Id: kind_of_edge.vhd,v 1.4 2003/06/29 21:25:20 jcanaris Exp $
-------------------------------------------------------------------------------
-- kind_of_edge - entity / architecture pair
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
-- Filename:        kind_of_edge.vhd
-- Version:         v1.00c
-- Description:     generates a rising edge or falling edge detector based on
--                  C_KIND_OF_EDGE
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 int_det.vhd
--                   detect_intr.vhd
--                     edge_det_bit.vhd
--                       kind_of_edge.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001 -- First version
--  jam      11/06/2001 changed type of C_KIND_OF_EDGE from enumerated type to
--                      std_logic
--  jam      09/03/2002 added Xon generic
--  jam      11/04/2002 changed fdc and fdc_1 to fdr and fdr_1
--  jam      11/04/2002      -- roll to rev c
--  jam      11/18/2002 changed fdr and fdr_1 back to fdc and fdc_1 since they
--                      need to be asynchronously cleared
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

entity kind_of_edge is
  generic (C_KIND_OF_EDGE : std_logic := '1');
  port
  (
    Edge_intr  : in  std_logic;
    Clear      : in  std_logic;
    Async_edge : out std_logic
  );
end kind_of_edge;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of kind_of_edge is

  component fdc is
    port
    (
      C   : in  std_logic;
      CLR : in  std_logic;
      D   : in  std_logic;
      Q   : out std_logic
    );
  end component fdc;

  component fdc_1 is
    port
    (
      C   : in  std_logic;
      CLR : in  std_logic;
      D   : in  std_logic;
      Q   : out std_logic
    );
  end component fdc_1;

begin

  RISING_EDGE_GEN:
  if C_KIND_OF_EDGE = '1'
  generate
    RISING_EDGE_DET_I : fdc
      port map
      (
        C   => Edge_intr,
        CLR => Clear,
        D   => '1',
        Q   => Async_edge
      );
  end generate RISING_EDGE_GEN;

  FALLING_EDGE_GEN:
  if C_KIND_OF_EDGE = '0'
  generate
    FALLING_EDGE_DET_I : fdc_1
      port map
      (
        C   => Edge_intr,
        CLR => Clear,
        D   => '1',
        Q   => Async_edge
      );
  end generate FALLING_EDGE_GEN;

end imp;
