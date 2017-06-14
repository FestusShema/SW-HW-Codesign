-------------------------------------------------------------------------------
-- $Id: mer_reg.vhd,v 1.4 2003/06/29 21:25:54 jcanaris Exp $
-------------------------------------------------------------------------------
-- mer_reg - entity / architecture pair
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
-- Filename:        mer_reg.vhd
-- Version:         v1.00c
-- Description:     generate two bit register for global enable and hw int
--                  enable
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 regs.vhd
--                   mer_reg.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/20/2001  changed to little endian and added C_WIDTH generic
--  jam      09/03/2002  added Xon generic
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
library unisim;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use unisim.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity mer_reg is
  generic (C_WIDTH : positive := 1);
  port
  (
    Clk      : in  std_logic;
    Rst      : in  std_logic;
    Data_in  : in  std_logic_vector(1 downto 0);
    Ld       : in  std_logic;
    Data_out : out std_logic_vector(C_WIDTH - 1 downto 0)
  );
end mer_reg;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of mer_reg is

  component fdre is
    port
    (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic
    );
  end component fdre;

  signal glb_en_bit   : std_logic;
  signal hw_en_bit    : std_logic;
  signal hw_en_bit_ld : std_logic;
  signal upper_bits   : std_logic_vector(C_WIDTH - 1 downto 2);

begin

  hw_en_bit_ld <= Ld and not hw_en_bit;

  GLB_EN_BIT_I : fdre
    port map
    (
      Q  => glb_en_bit,
      C  => Clk,
      CE => Ld,
      D  => Data_in(0),
      R  => Rst
    );

  HW_EN_BIT_I : fdre
    port map
    (
      Q  => hw_en_bit,
      C  => Clk,
      CE => hw_en_bit_ld,
      D  => Data_in(1),
      R  => Rst
    );

  upper_bits <= (others => '0');

  Data_out <= upper_bits & hw_en_bit & glb_en_bit;

end imp;

