-------------------------------------------------------------------------------
-- $Id: data_width_adapter.vhd,v 1.2 2006/10/23 23:03:08 dougt Exp $
-------------------------------------------------------------------------------
-- data_width_adapter.vhd
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2006 by Xilinx, Inc. All rights reserved.               **
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
-- Filename:        data_width_adapter.vhd
--
-- Description:     
--   This file implements the logic needed to adapt 32/64/128 bit PLBV46 to
-- a 32, 64, or 128 bit Master. There are theoretically 9 combinations (3 master
-- data widths and 3 Bus Data widths) but it is not allowed that a Master to be
-- wider than the PLB Bus.               
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              data_width_adapter.vhd
--
-------------------------------------------------------------------------------
-- Change Log:
--
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.2 $
-- Date:            $6/14/2006$
--
-- History:
--   DET   6/14/2006       Initial Version
--                      
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
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library unisim; -- Required for Xilinx primitives
use unisim.all;  


-------------------------------------------------------------------------------

entity data_width_adapter is
  generic (
    C_MPLB_DWIDTH  : Integer range 32 to 128 := 128;
    C_MIPIF_DWIDTH : Integer range 32 to 128 := 64
    );
  port (
    Bus2Adptr_RdDBus   : in  std_logic_vector(0 to C_MPLB_DWIDTH-1) ;
    Adptr2Mstr_RdDBus  : out std_logic_vector(0 to C_MIPIF_DWIDTH-1);

    Mstr2Adptr_WrDBus  : in  std_logic_vector(0 to C_MIPIF_DWIDTH-1);
    Adptr2Bus_WrDBus   : out std_logic_vector(0 to C_MPLB_DWIDTH-1) ;
    
    Mstr2Adptr_BE      : in  std_logic_vector(0 to C_MIPIF_DWIDTH/8-1);
    Adptr2Bus_BE       : out std_logic_vector(0 to C_MPLB_DWIDTH/8-1)
    
    );

end entity data_width_adapter;


architecture implementation of data_width_adapter is

  -- Constants
  -- Types
  -- Signals
  -- Component Declarations



begin --(architecture implementation)


   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_EQUAL_WIDTH
   --
   -- If Generate Description:
   --  Bus Data width is the same as the Master Data width
   --
   --
   ------------------------------------------------------------
   CASE_EQUAL_WIDTH : if (C_MPLB_DWIDTH = C_MIPIF_DWIDTH) generate
   
      begin
   
         Adptr2Mstr_RdDBus <= Bus2Adptr_RdDBus ;
         Adptr2Bus_WrDBus  <= Mstr2Adptr_WrDBus;
         Adptr2Bus_BE      <= Mstr2Adptr_BE    ;    
         
      end generate CASE_EQUAL_WIDTH;
  
  
   
   
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_M64
   --
   -- If Generate Description:
   --  Bus is 128 bits and Master is 64 bits
   --
   --
   ------------------------------------------------------------
   CASE_B128_M64 : if (C_MPLB_DWIDTH = 128 and C_MIPIF_DWIDTH = 64) generate
   
      begin
   
         Adptr2Mstr_RdDBus           <= Bus2Adptr_RdDBus(0 to 63);
         Adptr2Bus_WrDBus(0 to 63)   <= Mstr2Adptr_WrDBus;
         Adptr2Bus_WrDBus(64 to 127) <= Mstr2Adptr_WrDBus;
         Adptr2Bus_BE(0 to 7)        <= Mstr2Adptr_BE    ;
         Adptr2Bus_BE(8 to 15)       <= Mstr2Adptr_BE    ;
         
      end generate CASE_B128_M64;
  
  
  
  
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_M32
   --
   -- If Generate Description:
   --  Bus is 128 bits and Master is 64 bits
   --
   --
   ------------------------------------------------------------
   CASE_B128_M32 : if (C_MPLB_DWIDTH = 128 and C_MIPIF_DWIDTH = 32) generate
   
      begin
   
         Adptr2Mstr_RdDBus           <= Bus2Adptr_RdDBus(0 to 31);
         Adptr2Bus_WrDBus(0 to 31)   <= Mstr2Adptr_WrDBus;
         Adptr2Bus_WrDBus(32 to 63)  <= Mstr2Adptr_WrDBus;
         Adptr2Bus_WrDBus(64 to 95)  <= Mstr2Adptr_WrDBus;
         Adptr2Bus_WrDBus(96 to 127) <= Mstr2Adptr_WrDBus;
         Adptr2Bus_BE(0 to 3)        <= Mstr2Adptr_BE    ;
         Adptr2Bus_BE(4 to 7)        <= Mstr2Adptr_BE    ;
         Adptr2Bus_BE(8 to 11)       <= Mstr2Adptr_BE    ;
         Adptr2Bus_BE(12 to 15)      <= Mstr2Adptr_BE    ;
         
      end generate CASE_B128_M32;
  
  
  
  
  
  
   
   
   
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B64_M32
   --
   -- If Generate Description:
   --  Bus is 64 bits and Master is 32 bits
   --
   --
   ------------------------------------------------------------
   CASE_B64_M32 : if (C_MPLB_DWIDTH = 64 and C_MIPIF_DWIDTH = 32) generate
   
      begin
   
         Adptr2Mstr_RdDBus           <= Bus2Adptr_RdDBus(0 to 31);
         Adptr2Bus_WrDBus(0 to 31)   <= Mstr2Adptr_WrDBus;
         Adptr2Bus_WrDBus(32 to 63)  <= Mstr2Adptr_WrDBus;
         Adptr2Bus_BE(0 to 3)        <= Mstr2Adptr_BE    ;
         Adptr2Bus_BE(4 to 7)        <= Mstr2Adptr_BE    ;
         
      end generate CASE_B64_M32;
  



end implementation;
