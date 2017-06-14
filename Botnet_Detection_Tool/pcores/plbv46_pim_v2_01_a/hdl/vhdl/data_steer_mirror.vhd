-------------------------------------------------------------------------------
-- $Id: data_steer_mirror.vhd,v 1.1.2.1 2008/02/14 15:22:29 mwelter Exp $
-------------------------------------------------------------------------------
-- data_steer_mirror.vhd
-------------------------------------------------------------------------------
--
-- ****************************************************************************
-- **  DISCLAIMER OF LIABILITY                                               **
-- **                                                                        **
-- **  This text/file contains proprietary, confidential                     **
-- **  information of Xilinx, Inc., is distributed under                     **
-- **  license from Xilinx, Inc., and may be used, copied                    **
-- **  and/or disclosed only pursuant to the terms of a valid                **
-- **  license agreement with Xilinx, Inc. Xilinx hereby                     **
-- **  grants you a license to use this text/file solely for                 **
-- **  design, simulation, implementation and creation of                    **
-- **  design files limited to Xilinx devices or technologies.               **
-- **  Use with non-Xilinx devices or technologies is expressly              **
-- **  prohibited and immediately terminates your license unless             **
-- **  covered by a separate agreement.                                      **
-- **                                                                        **
-- **  Xilinx is providing this design, code, or information                 **
-- **  "as-is" solely for use in developing programs and                     **
-- **  solutions for Xilinx devices, with no obligation on the               **
-- **  part of Xilinx to provide support. By providing this design,          **
-- **  code, or information as one possible implementation of                **
-- **  this feature, application or standard, Xilinx is making no            **
-- **  representation that this implementation is free from any              **
-- **  claims of infringement. You are responsible for obtaining             **
-- **  any rights you may require for your implementation.                   **
-- **  Xilinx expressly disclaims any warranty whatsoever with               **
-- **  respect to the adequacy of the implementation, including              **
-- **  but not limited to any warranties or representations that this        **
-- **  implementation is free from claims of infringement, implied           **
-- **  warranties of merchantability or fitness for a particular             **
-- **  purpose.                                                              **
-- **                                                                        **
-- **  Xilinx products are not intended for use in life support              **
-- **  appliances, devices, or systems. Use in such applications is          **
-- **  expressly prohibited.                                                 **
-- **                                                                        **
-- **  Any modifications that are made to the Source Code are                **
-- **  done at the user’s sole risk and will be unsupported.                 **
-- **  The Xilinx Support Hotline does not have access to source             **
-- **  code and therefore cannot answer specific questions related           **
-- **  to source HDL. The Xilinx Hotline support of original source          **
-- **  code IP shall only address issues and questions related               **
-- **  to the standard Netlist version of the core (and thus                 **
-- **  indirectly, the original core source).                                **
-- **                                                                        **
-- **  Copyright (c) 2007, 2008 Xilinx, Inc. All rights reserved.            **
-- **                                                                        **
-- **  This copyright and support notice must be retained as part            **
-- **  of this text at all times.                                            **
-- ****************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        data_steer_mirror.vhd
--
-- Description:
--   This file implements the logic needed to mirror a Slave's Read Data
-- bus to a 32/64/128 bit PLBV46 Bus. This module also provides the required
-- read data steering logic when interfaceing with masters that are narrower
-- than the Slave's Native Data Width.
--
--
-- Notes:
-- 1) The PLBV46 Bus Width cannot be narrower than the Slave's Native Dwidth.
--
-- 2) Byte and Half-word transfers are not supported in the Xilinx PLBV46
--    simplifications so the associated steering mux logic for those transfer
--    widths is omitted.
--
-- 3) Data Steering has been simplified by omitting the requesting Master's
--    size (PLB_msize(0:1) from the mux control logic. Steering is implemented
--    only as a function of the address of the Data Beat presented to the PLB.
--    This implementation is more general and less resource intensive.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--    -- data_steer_mirror.vhd
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
-- Revision:        $Revision: 1.1.2.1 $
-- Date:            $01/18/2007$
--
-- History:
--   DET   01/18/2007       Initial Version
--
--
--    MW   08/09/2007       Initial Version
-- ~~~~~~
--     - Added data_out_i in CASE_B128_S64 to properly mirror readd data.
-- ^^^^^^
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

entity data_steer_mirror is
    generic (
        C_STEER_ADDR_WIDTH   : integer range  1 to 36  := 8;
        C_SPLB_DWIDTH        : integer range 32 to 128 := 32;
        C_SPLB_NATIVE_DWIDTH : integer range 32 to 128 := 32;
        C_SMALLEST_MASTER    : integer range 32 to 128 := 32
    );
    port (

        Steer_Addr_In   : in  std_logic_vector(0 to
                              C_STEER_ADDR_WIDTH-1);

        Data_In         : in  std_logic_vector(0 to
                              C_SPLB_NATIVE_DWIDTH-1);
        Data_Out        : out std_logic_vector(0 to
                              C_SPLB_DWIDTH-1)

    );

end entity data_steer_mirror;


architecture implementation of data_steer_mirror is

  -- Constants
  Constant WRD_OFFSET_BIT  : integer := 3;
  Constant DWRD_OFFSET_BIT : integer := 4;

  -- Signals
  signal sig_addr_bits_dwrd_wrd : std_logic_vector(0 to 1);
  signal sig_addr_bit_wrd       : std_logic;
  signal sig_addr_bit_dwrd      : std_logic;


begin --(architecture implementation)

-- GEN_SAME : if C_SPLB_DWIDTH = C_SPLB_NATIVE_DWIDTH
--           and C_SPLB_DWIDTH = C_SMALLEST_MASTER generate
--
--     Data_Out <= Data_In;
--
-- end generate GEN_SAME;



-- GEN_NOTSAME : if C_SPLB_DWIDTH /= C_SPLB_NATIVE_DWIDTH
--               or C_SPLB_DWIDTH /= C_SMALLEST_MASTER
--               or C_SPLB_NATIVE_DWIDTH /= C_SMALLEST_MASTER generate



   sig_addr_bits_dwrd_wrd <=  Steer_Addr_In(C_STEER_ADDR_WIDTH -
                                            DWRD_OFFSET_BIT)
                            &
                              Steer_Addr_In(C_STEER_ADDR_WIDTH -
                                            WRD_OFFSET_BIT);


   sig_addr_bit_wrd      <=  Steer_Addr_In(C_STEER_ADDR_WIDTH -
                                           WRD_OFFSET_BIT);
   sig_addr_bit_dwrd     <=  Steer_Addr_In(C_STEER_ADDR_WIDTH -
                                           DWRD_OFFSET_BIT);



   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_S128
   --
   -- If Generate Description:
   --  Bus Data width is 128 bits and the Slave Data width is
   -- 128 bits.
   --
   ------------------------------------------------------------
   CASE_B128_S128 : if (C_SPLB_DWIDTH        = 128 and
                        C_SPLB_NATIVE_DWIDTH = 128) generate

      begin

       -- direct connect for byte lanes 8 - 15
        Data_Out(64 to 127) <= Data_In(64 to 127);



        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: STEER_MUX_0_3
        --
        -- Process Description:
        -- Steering Mux for byte lanes 0-3.
        --
        -------------------------------------------------------------
        STEER_MUX_0_3 : process (sig_addr_bits_dwrd_wrd,
                                  Data_In)
           begin

             case sig_addr_bits_dwrd_wrd is
               -- when "00" =>
               --   Data_Out(0 to 31) <= Data_In(0 to 31);
               when "01" =>
                 Data_Out(0 to 31) <= Data_In(32 to 63);
               when "10" =>
                 Data_Out(0 to 31) <= Data_In(64 to 95);
               when "11" =>
                 Data_Out(0 to 31) <= Data_In(96 to 127);
               when others => -- '00' case
                 Data_Out(0 to 31) <= Data_In(0 to 31);
             end case;

           end process STEER_MUX_0_3;


        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: STEER_MUX_4_7
        --
        -- Process Description:
        -- Steering Mux for byte lanes 4-7.
        --
        -------------------------------------------------------------
        STEER_MUX_4_7 : process (sig_addr_bit_dwrd,
                                  Data_In)
           begin

             If (sig_addr_bit_dwrd = '1') Then

               Data_Out(32 to 63) <= Data_In(96 to 127);

             else

               Data_Out(32 to 63) <= Data_In(32 to 63);

             End if;

           end process STEER_MUX_4_7;


      end generate CASE_B128_S128;




   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_S64
   --
   -- If Generate Description:
   --  Bus is 128 bits and Slave is 64 bits
   --
   --
   ------------------------------------------------------------
--   CASE_B128_S64 : if (C_SPLB_DWIDTH        = 128 and
--                       C_SPLB_NATIVE_DWIDTH = 64) generate
--
--      begin
--
--       -- direct connect for byte lanes 4 - 15
--        Data_Out(96 to 127) <= Data_In(32 to 63);
--        Data_Out(32 to 63)  <= Data_In(32 to 63);
--
--
--
--        -------------------------------------------------------------
--        -- Combinational Process
--        --
--        -- Label: STEER_MUX_0_3
--        --
--        -- Process Description:
--        -- Steering Mux for byte lanes 0-3.
--        --
--        -------------------------------------------------------------
--        STEER_MUX_0_3 : process (sig_addr_bit_wrd,
--                                 Data_In)
--           begin
--
--
--             If (sig_addr_bit_wrd = '1') Then
--
--               Data_Out(0 to 31) <= Data_In(32 to 63);
--               Data_Out(64 to 95) <= Data_In(32 to 63);
--
--             else
--
--               Data_Out(0 to 31) <= Data_In(0 to 31);
--               Data_Out(64 to 95) <= Data_In(0 to 31);
--
--             End if;
--
--           end process STEER_MUX_0_3;
--
--
--      end generate CASE_B128_S64;
--
   CASE_B128_S64 : if (C_SPLB_DWIDTH        = 128 and
                       C_SPLB_NATIVE_DWIDTH = 64) generate

      signal data_out_i             : std_logic_vector(0 to
                                    C_SPLB_DWIDTH-1);

      begin

       -- direct connect for byte lanes 4 - 15
        Data_Out( 0 to 31)    <= data_out_i( 0 to 31);
        Data_Out(32 to 63)    <= data_out_i(32 to 63);
        Data_Out(64 to 127)   <= data_out_i( 0 to 63);

        data_out_i(32 to 63)  <= Data_In(32 to 63);


        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: STEER_MUX_0_3
        --
        -- Process Description:
        -- Steering Mux for byte lanes 0-3.
        --
        -------------------------------------------------------------
        STEER_MUX_0_3 : process (sig_addr_bit_wrd,
                                 Data_In)
           begin


             If (sig_addr_bit_wrd = '1') Then

               data_out_i(0 to 31) <= Data_In(32 to 63);

             else

               data_out_i(0 to 31) <= Data_In(0 to 31);

             End if;

           end process STEER_MUX_0_3;


      end generate CASE_B128_S64;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_S32
   --
   -- If Generate Description:
   --  Bus is 128 bits and Slave is 32 bits
   --
   --
   ------------------------------------------------------------
   CASE_B128_S32 : if (C_SPLB_DWIDTH        = 128 and
                       C_SPLB_NATIVE_DWIDTH = 32) generate

      begin

       -- Just mirror the data
       -- no steering is required
        Data_Out(96 to 127) <= Data_In(0 to 31);
        Data_Out(64 to 95)  <= Data_In(0 to 31);
        Data_Out(32 to 63)  <= Data_In(0 to 31);
        Data_Out(0  to 31)  <= Data_In(0 to 31);

      end generate CASE_B128_S32;







   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_S64_B64
   --
   -- If Generate Description:
   --  Bus Data width is 64 bits and the Slave Data width is
   -- 64 bits.
   --
   ------------------------------------------------------------
--   CASE_S64_B64 : if (C_SPLB_DWIDTH        = 64 and
--                      C_SPLB_NATIVE_DWIDTH = 64) generate
--
--      begin
--
--       -- direct connect for byte lanes 4 - 7
--        Data_Out(32 to 63) <= Data_In(32 to 63);
--
--
--        -------------------------------------------------------------
--        -- Combinational Process
--        --
--        -- Label: STEER_MUX_0_3
--        --
--        -- Process Description:
--        -- Steering Mux for byte lanes 0-3.
--        --
--        -------------------------------------------------------------
--        STEER_MUX_0_3 : process (sig_addr_bit_wrd,
--                                  Data_In)
--           begin
--
--
--             If (sig_addr_bit_wrd = '1') Then
--
--               Data_Out(0 to 31) <= Data_In(32 to 63);
--
--             else
--
--               Data_Out(0 to 31) <= Data_In(0 to 31);
--
--             End if;
--
--           end process STEER_MUX_0_3;
--
--
--      end generate CASE_S64_B64;
--
   CASE_S64_B64 : if (C_SPLB_DWIDTH        = 64 and
                      C_SPLB_NATIVE_DWIDTH = 64) generate

      begin

       -- direct connect for byte lanes 4 - 7
        Data_Out(32 to 63) <= Data_In(32 to 63);


        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: STEER_MUX_0_3
        --
        -- Process Description:
        -- Steering Mux for byte lanes 0-3.
        --
        -------------------------------------------------------------
        STEER_MUX_0_3 : process (sig_addr_bit_wrd,
                                  Data_In)
           begin


             If (sig_addr_bit_wrd = '1') Then

               Data_Out(0 to 31) <= Data_In(32 to 63);

             else

               Data_Out(0 to 31) <= Data_In(0 to 31);

             End if;

           end process STEER_MUX_0_3;


      end generate CASE_S64_B64;





   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B64_S32
   --
   -- If Generate Description:
   --  Bus is 64 bits and Slave is 32 bits
   --
   --
   ------------------------------------------------------------
   CASE_B64_S32 : if (C_SPLB_DWIDTH        = 64 and
                      C_SPLB_NATIVE_DWIDTH = 32) generate

      begin

       -- Mirror byte lanes 0 to 3 to byte lanes 4 - 7
       -- No steering required
        Data_Out(32 to 63)  <= Data_In(0 to 31);
        Data_Out(0  to 31)  <= Data_In(0 to 31);


      end generate CASE_B64_S32;









   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B32_S32
   --
   -- If Generate Description:
   --  Bus Data width is 32 bits and the Slave Data width is
   -- 32 bits.
   --
   ------------------------------------------------------------
   CASE_B32_S32 : if (C_SPLB_DWIDTH        = 32 and
                           C_SPLB_NATIVE_DWIDTH = 32) generate

      begin

       -- direct connect for byte lanes 0 - 3
        Data_Out(0 to 31) <= Data_In(0 to 31);


      end generate CASE_B32_S32;






-- end generate GEN_NOTSAME;

end implementation;
