-------------------------------------------------------------------------------
-- $Id: edge_det_bit.vhd,v 1.5 2007/10/03 06:16:14 nitink Exp $
-------------------------------------------------------------------------------
-- edge_det_bit - entity / architecture pair
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
-- Filename:        edge_det_bit.vhd
-- Version:         v1.00c
-- Description:     detect an edge on one signal
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 int_det.vhd
--                   detect_intr.vhd
--                     edge_det_bit.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed to target_family_type in common
--  jam      11/06/2001  changed C_EDGE_POLARITY type from edge_pol_type to
--                       std_logic because platgen doesn't do enumerated types
--                       and xst couldn't handle functions returning arrays of
--                       enumerated values.
--  jam      12/04/2001  changed to C_FAMILY
--  jam      09/03/2002  added Xon generic
--  jam      11/04/2002  changed fdc to fdr
--  jam      11/04/2002      -- roll to rev c
-- ~~~~~~~
--   NSK      10/03/2007
-- ^^^^^^^
-- Updated to fix CR #446745.
-- 1. In the original code Edge_intr is passed as a clock to the kind_of_edge 
--    module. Modified this detect the one-shot on Edge_intr and used as CE.
-- 2. Removed the components kind_of_edge, fdr.
-- 3. Removed the signals async_edge & sync_edge.
-- 4. Added the signals edge_d1 & edge.
-- 5. Removed the instance of kind_of_edge & fdr as now unused.
-- ~~~~~~~
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
--          C_EDGE_POLARITY -  1 = rising
--                             0 = falling
--                             anything else is n/a
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

entity edge_det_bit is
  generic (
           C_FAMILY        : string    := "virtex2";
           C_Y             : integer   := 0;
           C_X             : integer   := 0;
           C_U_SET         : string    := "intc";
           C_EDGE_POLARITY : std_logic := '1'
           );
  port (
        Clk         : in  std_logic;
        Clear       : in  std_logic;
        Edge_intr   : in  std_logic;
        Active_intr : out std_logic
        );

end edge_det_bit;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of edge_det_bit is

  signal edge_d1    : std_logic;
  signal edge       : std_logic;

begin

    RISING_EDGE_GEN: if C_EDGE_POLARITY = '1' generate

        DETECT_RISE_EDGE_P : process (Clk) is
            begin
                if(Clk'event and Clk='1') then
                    if (Clear = '1') then
                        edge_d1 <= '0';
                    else
                        edge_d1 <= Edge_intr;
                    end if;
                end if;
        end process DETECT_RISE_EDGE_P;

        edge <= '1' when Edge_intr = '1' and edge_d1 = '0' else '0';

        DETECT_INTR_P : process (Clk) is
            begin
                if(Clk'event and Clk='1') then
                    if (Clear = '1') then
                        Active_intr <= '0';
                    elsif (edge = '1') then
                        Active_intr <= '1';
                    end if;
                end if;
        end process DETECT_INTR_P;

    end generate RISING_EDGE_GEN;


    FALLING_EDGE_GEN: if C_EDGE_POLARITY = '0' generate

        DETECT_FALL_EDGE_P : process (Clk) is
            begin
                if(Clk'event and Clk='1') then
                    if (Clear = '1') then
                        edge_d1 <= '1';
                    else
                        edge_d1 <= Edge_intr;
                    end if;
                end if;
        end process DETECT_FALL_EDGE_P;

        edge <= '1' when Edge_intr = '0' and edge_d1 = '1' else '0';

        DETECT_INTR_P : process (Clk) is
            begin
                if(Clk'event and Clk='1') then
                    if (Clear = '1') then
                        Active_intr <= '0';
                    elsif (edge = '1') then
                        Active_intr <= '1';
                    end if;
                end if;
        end process DETECT_INTR_P;

    end generate FALLING_EDGE_GEN;


end imp;