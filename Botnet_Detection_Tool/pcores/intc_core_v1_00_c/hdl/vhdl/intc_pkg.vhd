-------------------------------------------------------------------------------
-- $Id: intc_pkg.vhd,v 1.3 2003/01/16 21:55:20 tise Exp $
-------------------------------------------------------------------------------
-- intc_pkg - package / package body pair
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
-- Filename:        intc_pkg.vhd
-- Version:         v1.00c
-- Description:     Big endian package for intc contains constants, types
--                  and subtypes for a big endian interrupt controller
--
-------------------------------------------------------------------------------
-- Structure:   
--             intc_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/20/2001  changed regs stuff to little endian
--  jam      11/06/2001  removed enumerated types for kind of interrupts, kind
--                       of edges, and kind of levels and the associated array
--                       types, initialization values and conversion functions
--                       because platgen can't handle enumerated types in the
--                       top level and xst couldn't handle the functions that
--                       were converting the std_logic_vector generics into
--                       arrays of enumeration values
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

------------------------------------------------------------------------------
-- Package
------------------------------------------------------------------------------

package intc_pkg is

   -- basic types for data elements
  subtype OCTLET_TYPE  is std_logic_vector(0 to 63);
  subtype QUADLET_TYPE is std_logic_vector(0 to 31);
  subtype DOUBLET_TYPE is std_logic_vector(0 to 15);
  subtype BYTE_TYPE    is std_logic_vector(0 to 7);

   -- define the data bus width
  subtype data_word_type is quadlet_type;

   -- define the address bus width
  subtype addr_type is quadlet_type;

  constant WORD_SIZE : positive := data_word_type'high + 1;
  constant ADDR_SIZE : positive := addr_type'high + 1;

   -- Function to determine number of msb address bits to decode
  function Addr_Bits(x,y : std_logic_vector) return integer;

   -- function to convert an integer to a boolean
  function int2bool(i : integer) return boolean;

   -- constants for moving one bit to the left and right
  constant ONE_BIT_LEFT  : integer := -1;   -- big endian
  constant ONE_BIT_RIGHT : integer := 1;    -- big endian

   -- define register address bus - 8 locations = 3 addr bits
  subtype reg_bus_type is std_logic_vector(WORD_SIZE-5 to WORD_SIZE-3);

   -- define IER register select type
  subtype ier_sel_type is std_logic_vector(1 downto 0);

   -- ier select values
  constant NO_IER_SEL_VAL : ier_sel_type := "11";
  constant IER_SEL_VAL    : ier_sel_type := "00";
  constant SIE_SEL_VAL    : ier_sel_type := "01";
  constant CIE_SEL_VAL    : ier_sel_type := "10";

   -- number of user registers - try to keep it to an integral power of 2
  constant NUM_REGS : positive := 8;

   -- reg sel size
  constant REG_SEL_WIDTH : positive := 3;

   -- regs mux sel type
  subtype reg_sel_type is std_logic_vector(REG_SEL_WIDTH - 1 downto 0);

   -- regs data select values
  constant ISR_DATA_SEL : reg_sel_type := "000";
  constant IPR_DATA_SEL : reg_sel_type := "001";
  constant IER_DATA_SEL : reg_sel_type := "010";
  constant IAR_DATA_SEL : reg_sel_type := "011";
  constant SIE_DATA_SEL : reg_sel_type := "100";
  constant CIE_DATA_SEL : reg_sel_type := "101";
  constant IVR_DATA_SEL : reg_sel_type := "110";
  constant MER_DATA_SEL : reg_sel_type := "111";

end package intc_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------

package body intc_pkg is

    -- function to convert an address range (base address and an upper address)
    -- into the number of upper address bits needed for decoding a device      
    -- select signal
  function Addr_Bits(x,y : std_logic_vector) return integer is
    variable addr_xor : std_logic_vector(x'range);
    variable count    : integer := 0;
  begin
    assert x'length = y'length and (x'ascending xnor y'ascending)
      report "Addr_Bits: arguments are not the same type"
      severity ERROR;
    addr_xor := x xor y;
    for i in x'range
    loop
      if addr_xor(i) = '1' then return count;
      end if;
      count := count + 1;
    end loop;
    return x'length;
  end Addr_Bits;

  function int2bool(i : integer) return boolean is                             
  begin                                                                        
    if i = 0 then return false;                                                
    else return true;                                                          
    end if;                                                                    
  end function int2bool;

end package body intc_pkg;

