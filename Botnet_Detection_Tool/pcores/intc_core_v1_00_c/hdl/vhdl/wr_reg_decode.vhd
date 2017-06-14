-------------------------------------------------------------------------------
-- $Id: wr_reg_decode.vhd,v 1.3 2003/01/16 21:55:20 tise Exp $
-------------------------------------------------------------------------------
-- wr_reg_decode - entity / architecture pair
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
-- Filename:        wr_reg_decode.vhd
-- Version:         v1.00c
-- Description:     decode logic for writing to registers
-- 
-------------------------------------------------------------------------------
-- Structure:
-- 
--              intc.vhd
--                mb_intc_top.vhd
--                  regs.vhd
--                    wr_reg_decode.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/20/2001  changed to little endian so reg sizes are now only
--                       as wide as the number of int inputs
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

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity wr_reg_decode is
  generic
  (
    C_WIDTH : positive := 1;
    C_HAS_SIE : boolean := true;
    C_HAS_CIE : boolean := true
  );
  port
  (
    Reg_addr   : in  reg_sel_type;
    Valid_wr   : in  std_logic;
    Sw_ints_en : out std_logic_vector(C_WIDTH - 1 downto 0);
    Ier_sel    : out ier_sel_type;
    Ld_ier     : out std_logic;
    Int_ack_en : out std_logic_vector(C_WIDTH - 1 downto 0);
    Ld_mer     : out std_logic
  );
 
end wr_reg_decode;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of wr_reg_decode is
 
begin
  DECODE_WR_REG:
  process (Valid_wr, Reg_addr)
  begin
  
    Sw_ints_en <= (others => '0');
    Ier_sel    <= NO_IER_SEL_VAL;
    Ld_ier     <= '0';
    Int_ack_en <= (others => '0');
    Ld_mer     <= '0';

    if Valid_wr = '1' then
      case Reg_addr is
 
        when ISR_DATA_SEL =>
          Sw_ints_en <= (others => '1');
 
        when IPR_DATA_SEL =>
          null;
 
        when IER_DATA_SEL =>
          Ier_sel <= IER_SEL_VAL;
          Ld_ier <= '1';
 
        when IAR_DATA_SEL =>
          Int_ack_en <= (others => '1');
 
        when SIE_DATA_SEL =>
          if C_HAS_SIE then
            Ier_sel <= SIE_SEL_VAL;
            Ld_ier <= '1';
          else
            null;
          end if;
 
        when CIE_DATA_SEL =>
          if C_HAS_SIE and C_HAS_CIE then
            Ier_sel <= CIE_SEL_VAL;
            Ld_ier <= '1';
          elsif not C_HAS_SIE and C_HAS_CIE then
            Ier_sel <= SIE_SEL_VAL;  -- cie takes the place of sie in this case
            Ld_ier <= '1';
          else
            null;
          end if;
 
        when IVR_DATA_SEL =>
          null;
 
        when MER_DATA_SEL =>
          Ld_mer <= '1';
 
        when others  =>
          Sw_ints_en <= (others => '0');  -- this is probably redundant but
          Ier_sel    <= NO_IER_SEL_VAL;   -- the synthesis tool gave a warning
          Ld_ier     <= '0';              -- that there wasn't a default for
          Int_ack_en <= (others => '0');  -- the case statement
          Ld_mer     <= '0';
      end case;
    end if;
  end process;
 
end imp;

