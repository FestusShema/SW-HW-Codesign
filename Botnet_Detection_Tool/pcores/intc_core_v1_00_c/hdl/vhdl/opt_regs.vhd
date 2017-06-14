-------------------------------------------------------------------------------
-- $Id: opt_regs.vhd,v 1.6 2004/03/30 17:48:11 jcanaris Exp $
-------------------------------------------------------------------------------
-- opt_regs - entity / architecture pair
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
-- Filename:        opt_regs.vhd
-- Version:         v1.00c
-- Description:     generate optional registers IPR and IVR
-- 
-------------------------------------------------------------------------------
-- Structure:
-- 
--              intc.vhd
--                mb_intc_top.vhd
--                  regs.vhd
--                    opt_regs.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/06/2001  changed to unisim version of plain_reg
--  jam      08/20/2001  changed to little endian and added C_WIDTH generic
--  jam      11/05/2001  changed component instantiation for le_reg to generate
--                       using xilinx primitive register
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use intc_core_v1_00_c.intc_pkg.all;
use unisim.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity opt_regs is
  generic
  (
    C_WIDTH   : positive := 1;
    C_HAS_IPR : boolean  := false;
    C_HAS_IVR : boolean  := false
  );
  port
  (
    Clk          : in  std_logic;
    Rst          : in  std_logic;
    Pending_ints : in  std_logic_vector(C_WIDTH - 1 downto 0);
    IPR_out      : out std_logic_vector(C_WIDTH - 1 downto 0);
    IVR_out      : out std_logic_vector(C_WIDTH - 1 downto 0);
    IVR_empty    : out boolean := true
  );

end opt_regs;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of opt_regs is

  component fdr
    port
    (
      Q  : out std_logic;
      D  : in std_logic;
      C  : in std_logic;
      R  : in std_logic
    );
  end component;

  signal ipr : std_logic_vector(C_WIDTH - 1 downto 0);
  signal ivr : std_logic_vector(C_WIDTH - 1 downto 0) := (others => '1');

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin

  NO_IPR_GEN:
  if not C_HAS_IPR
  generate
    ipr <= (others => '0');
  end generate NO_IPR_GEN;

  IPR_GEN:
  if C_HAS_IPR
  generate

    IPR_REG_GEN:
    for i in Pending_ints'range
    generate
      IPR_REG_BIT_I : fdr
      port map
      (
        Q  => ipr(i),
        D  => Pending_ints(i),
        C  => Clk,
        R  => Rst
      );
    end generate IPR_REG_GEN;

  end generate IPR_GEN;

  IPR_out <= ipr;


NO_IVR_GEN:
if not C_HAS_IVR
generate
ivr <= (others => '1');
IVR_empty <= true;
end generate NO_IVR_GEN;

  IVR_GEN:
    if C_HAS_IVR
    generate
    signal ivr_data : std_logic_vector(C_WIDTH - 1 downto 0);
  begin
    COMPUTE_IVR:
    process (Pending_ints)
      variable tmp   : unsigned(C_WIDTH - 1 downto 0);
      variable count : integer range 0 to C_WIDTH - 1;
    begin
      ivr_data <= (others => '1');
      IVR_empty <= true;
      tmp := unsigned(Pending_ints);
      for count in 0 to C_WIDTH - 1
      loop
        if tmp(tmp'right) = '1' then
          ivr_data <= conv_std_logic_vector(count,ivr_data'length);
          IVR_empty <= false;
          exit;
        end if;
        tmp := shr(tmp,conv_unsigned(1,tmp'length));
      end loop;
    end process COMPUTE_IVR;

    IVR_REG_GEN:
    for i in ivr_data'range
    generate
      IVR_REG_BIT_I : fdr
        port map
        (
          Q  => ivr(i),
          D  => ivr_data(i),
          C  => Clk,
          R  => Rst
        );
    end generate IVR_REG_GEN;

  end generate IVR_GEN;

  IVR_out <= ivr;

end imp;
