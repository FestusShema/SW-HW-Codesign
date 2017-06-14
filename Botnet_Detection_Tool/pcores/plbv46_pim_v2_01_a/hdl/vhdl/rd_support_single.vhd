-------------------------------------------------------------------------------
-- $Id: rd_support_single.vhd,v 1.1.2.1 2008/02/14 15:22:30 mwelter Exp $
-------------------------------------------------------------------------------
-- rd_support_single.vhd
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
-- **  done at the user�s sole risk and will be unsupported.                 **
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
-- Filename:        rd_support_single.vhd
--
-- Description:
--    This VHDL design implements the read support module that is part of the
-- PLBV46 PIM. The PIM is used to interface the MPMC3 to a PLBV46.
--
--
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--              rd_support_single.vhd
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.1.2.1 $
-- Date:            $1/9/2007$
--
-- History:
--   DET   1/9/2007       Initial Version
--
--     DET     1/30/2007     Initial
-- ~~~~~~
--     - Added 32-bit NPI Support
-- ^^^^^^
--
--     DET     2/8/2007     Initial
-- ~~~~~~
--     - 1:N PLB/NPI Clk Ratio support
-- ^^^^^^
--
--     DET     3/1/2007     Initial
-- ~~~~~~
--     - Fixed read data steering bug
--     - Added additional gating to sl_rdwdaddr output
-- ^^^^^^
--
--     DET     3/7/2007     Initial
-- ~~~~~~
--     - Added more gating to sl_rdwdaddr output
--     - Modified the Steer Address counter load value
--       calculation to eliminate overflows on large
--       bursts
-- ^^^^^^
--
--     DET     3/16/2007     Initial
-- ~~~~~~
--     - Fixed a bug in the Sl_rdack FLOP clear signal for the
--       Singles request case.
-- ^^^^^^
--
--     DET     3/20/2007     Initial
-- ~~~~~~
--     - Made another correction for the Sl_rdack flops. MTI
--       simulation not working correctly for register to register
--       transfer when clock edges aligned but source and dest
--       clocks are different names.
-- ^^^^^^
--
--     DET     4/10/2007     Initial
-- ~~~~~~
--     - Made significant design changes for 1:N clocking support in lue of
--       MTI simulation problem with edge aligned clocks but with different names.
-- ^^^^^^
--
--     DET     4/11/2007     Initial
-- ~~~~~~
--     - Converted all SPLB_Clk process to PI_Clk.
--     - Fixed a cacheline rdwdaddr bug.
-- ^^^^^^
--
--     DET     4/17/2007     Initial
-- ~~~~~~
--     - Added SRL FIFO for FIFO Latency support
-- ^^^^^^
--
--     DET     5/8/2007     Initial
-- ~~~~~~
--     - Fixed a bug with the NPI Read Count Load Value calculation
--       for 64-bit NPI case
-- ^^^^^^
--     DET     5/15/2007     Initial
-- ~~~~~~
--     - Replaced the use of sm_xfer_done with sig_cmd_cmplt_reg. This
--       approach provides tighter coupling between the Address Decoder
--       and the Read Support module at the completion of a Read request.
-- ^^^^^^
--
--     MW      5/18/2007     Initial
-- ~~~~~~
--     - Added a generate statements (READ_WD_ADDR_NPI32 & READ_WD_ADDR_NPI64)
--       for the REG_PLB_RDWDADDR process.  One for the 64 bit PIM support
--       which contains the original logic and the other for the 32 bit PIM
--       support which can use rdwdaddr bit 3 directly.
-- ^^^^^^
--
--     MW      06/07/2007    Initial
-- ~~~~~~
--     - Removed all logic except that needed to support DSPLB type
-- ^^^^^^
--
--     MW      07/02/2007    Initial
-- ~~~~~~
--     - Added Ad2rd_queue_data to hold off read pops until sa_valid address
--       is promoted to pa_valid and address decoder addracks
-- ^^^^^^
--
--     MW      07/11/2007    Initial
-- ~~~~~~
--     - Added register to Rd2NPI_RdFIFO_Pop to reguce levels of logic.
--       Still anded with NPI2RD_RdFIFO_Empty
--     - Above change resulted in modifcation of RD_LATENCY_0, RD_LATENCY_1,
--       and RD_LATENCY_2 logic
--     - Above change required a delay in the sig_decr_npi_rdcnt logic
-- ^^^^^^
--
--       MW        08/27/2007   - Initial Version
-- ~~~~~~
--       - Added Ad2rd_clk_ratio_1_1 to port
--       - Removed SRL FIFOs
--       - Modified to remove combinatorial logic around empty/pop
--       - Modified to support only Singles Transactions
--          - Reduced logic
-- ^^^^^^
--     MW      10/19/2007
-- ~~~~~~
--     - Added PLB_CLK register delay to all read signals going to PLB
--       to fix false timing errors
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
use IEEE.std_logic_unsigned.CONV_INTEGER;
use IEEE.std_logic_arith.CONV_STD_LOGIC_VECTOR;

library proc_common_v2_00_a;
Use proc_common_v2_00_a.srl_fifo_f;

library plbv46_pim_v2_01_a;
Use plbv46_pim_v2_01_a.data_steer_mirror;

library unisim; -- Required for Xilinx primitives
use unisim.vcomponents.all;

-------------------------------------------------------------------------------

entity rd_support_single is
  generic (


    C_SPLB_NATIVE_DWIDTH      : integer range 32 to 128 := 64;
       --  Native Data Width of this PLB Slave


   -- PLBV46 parameterization
    C_SPLB_MID_WIDTH            : integer range 0 to 4:= 3;
       -- The width of the Master ID bus
       -- This is set to log2(C_SPLB_NUM_MASTERS)

    C_SPLB_NUM_MASTERS          : integer range 1 to 16 := 8;
       -- The number of Master Devices connected to the PLB bus
       -- Research this to find out default value

    C_SPLB_SMALLEST_MASTER      : integer range 32 to 128 := 64;
       -- The dwidth (in bits) of the smallest master that will
       -- access this Slave.

    C_SPLB_AWIDTH             : integer range 32 to 36  := 32;
       --  width of the PLB Address Bus (in bits)

    C_SPLB_DWIDTH             : integer range 32 to 128 := 128;
       --  Width of the PLB Data Bus (in bits)

    C_PLBV46_PIM_TYPE         : string := "PLB";
       --  Configuration Type (PLB, DPLB, IPLB)

    C_SPLB_SUPPORT_BURSTS     : integer range 0 to 1    := 0;
       --  Burst Support

   -- NPI Parameterization
    C_NPI_DWIDTH              : Integer range 32 to 128 := 64;
       -- Sets the NPI Read Data port width.

    C_PI_RDWDADDR_WIDTH       : Integer range 3 to 5 := 4;
       -- sets the bit width of the PI_RdWdAddr port


    C_PI_RDFIFO_LATENCY       : Integer range 0 to 2 := 0 ;
       -- Read Data latency (in NPI Clock periods) measured from
       -- assertion of PI_RdFIFO_Pop to data availability on the
       -- NPI2RD_RdFIFO_D input port.


    C_FAMILY                   : string := "virtex5"

    );
  port (

   -- System Ports
    SPLB_Clk                     : in  std_logic;
    SPLB_Rst                     : in  std_logic;

    PI_Clk                       : in  std_logic;
    PIM_Rst                      : in  std_logic;

   -- PLBV46 Interface
    PLB_rdBurst                  : in  std_logic;

    Sl_rdDAck                    : Out std_logic;
    Sl_rdDBus                    : out std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                  : out std_logic_vector(0 to 3);
    Sl_rdComp                    : Out std_logic;
    Sl_rdBTerm                   : Out std_logic;
    Sl_MRdErr                    : out std_logic_vector(0 to
                                       C_SPLB_NUM_MASTERS-1);

   -- Address Decode Interface
    Ad2Rd_PLB_NPI_Sync           : In  std_logic;
    Ad2Rd_New_Cmd                : In  std_logic;
    Ad2Rd_Strt_Addr              : in  std_logic_vector(0 to
                                       C_SPLB_AWIDTH-1);
    Ad2Rd_Xfer_Width             : in  std_logic_vector(0 to 1);
    Ad2Rd_Xfer_WdCnt             : in  std_logic_vector(0 to 7);
    Ad2Rd_Single                 : In  std_logic;
    Ad2Rd_Cacheline_4            : In  std_logic;
    Ad2Rd_Cacheline_8            : In  std_logic;
    Ad2Rd_Burst_16               : In  std_logic;
    Ad2Rd_Burst_32               : In  std_logic;
    Ad2Rd_Burst_64               : In  std_logic;
    Ad2rd_queue_data             : In  std_logic;
    Ad2rd_clk_ratio_1_1          : In  std_logic;

    Rd2Ad_Rd_Cmplt               : out std_logic;
    Rd2Ad_Rd_Data_Cmplt          : out std_logic;
    Rd2Ad_Rd_Busy                : out std_logic;
    Rd2Ad_Rd_Error               : out std_logic;

  -- NPI Read Interface
    NPI2RD_RdFIFO_Empty          : In  std_logic;
    NPI2RD_RdFIFO_Data_Available : In  std_logic;
    NPI2RD_RdFIFO_RdWdAddr       : In  std_logic_vector(C_PI_RDWDADDR_WIDTH-1 downto 0);
    NPI2RD_RdFIFO_D              : In  std_logic_vector(C_NPI_DWIDTH-1 downto 0);
    NPI2RD_RdFIFO_Latency        : In  std_logic_vector(1 downto 0);

    Rd2NPI_RdFIFO_Flush          : Out std_logic;
    Rd2NPI_RdFIFO_Pop            : Out std_logic

    );

end entity rd_support_single;


architecture implementation of rd_support_single is

  -- Temporary SRL FIFO Support

   Constant SRL_FIFO_WIDTH      : integer := C_SPLB_NATIVE_DWIDTH;







  -- Constants
  Constant STEER_ADDR_WIDTH    : integer := 10; -- allow for 9 address cntr bits

  Constant WRD_ADDR_BIT_INDEX  : integer := STEER_ADDR_WIDTH-3;
  Constant DWRD_ADDR_BIT_INDEX : integer := STEER_ADDR_WIDTH-4;

  Constant DBEAT_OF_1          : std_logic_vector(0 to 7) := "00000001";

  Constant NPI_RDCNT_SIZE        : integer := 8; -- alloted Bit width of counter

  Constant MAX_CLK_RATIO_CNT     : integer := 15; -- alloted Bit width of counter


  -- Types

       type XFER_WIDTH_TYPE is (
                 WORD,
                 DBLWRD,
                 QWRD
                 );



     type rd_state_type is (
                 IDLE,
                 PREFLUSH,
                 DATA_TO_PLB,
                 POSTFLUSH
                 );

  -- Signals

  signal Bus_Rst                     : std_logic;

  Signal sm_state_ns                 : rd_state_type;
  Signal sm_state                    : rd_state_type;

  signal sm_xfer_done_ns             : std_logic;
  signal sm_xfer_done                : std_logic;

  signal sig_doing_a_single_reg      : std_logic;

  Signal sig_plb_done                : std_logic;

  signal sig_sl_rdbterm              : std_logic;
  signal sig_sl_rdcomp               : std_logic;
  signal sig_sl_rdack                : std_logic;
  signal sig_sl_rddbus               : std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
  signal sig_sl_rddbus_int           : std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
  signal sig_plb_rd_dreg             : std_logic_vector(0 to
                                       C_SPLB_DWIDTH-1);
  Signal sig_pop_valid               : std_logic;
--  signal sig_adj_pop_valid           : std_logic;

  signal sig_rdfifo_data_reg         : std_logic_vector(0 to
                                       C_NPI_DWIDTH-1);
  signal sig_rdfifo_data_bigend      : std_logic_vector(0 to
                                       C_NPI_DWIDTH-1);

  Signal sig_fifo_dreg_has_data      : std_logic;
  signal sig_clr_fifo_read_dreg      : std_logic;
  signal sig_make_fifo_dreg_stale    : std_logic;
--  signal sig_fifo_data_willgo_to_plb : std_logic;
  signal sig_get_next_fifo_data      : std_logic;
  signal sig_need_new_fifo_data      : std_logic;

  signal sig_pop_fifo                : std_logic;
  signal sig_preflush_fifo           : std_logic;

  signal sig_rd2ad_rd_error          : std_logic;
  signal sig_xfer_go                 : std_logic;

  signal sig_plb_dbeat_cnt           : integer range 0 to 255 := 0;
  signal sig_plb_dbeat_cnt_ld_value  : integer range 0 to 255 := 0;
  signal sig_wdcnt_to_dbeats_slv     : std_logic_vector(0 to 7);
  signal sig_dbcnt_eq_0              : std_logic;
  signal sig_decr_dbeat_cnt          : std_logic;

  signal sig_clr_rdcomp              : std_logic;
  signal sig_rdcomp_reg              : std_logic;


  Signal sig_steer_addr_ld_value_slv : std_logic_vector(0 to
                                       STEER_ADDR_WIDTH-1);
  Signal sig_steer_addr_slv          : std_logic_vector(0 to
                                       STEER_ADDR_WIDTH-1);
  Signal sig_steer_addr_ld_value     : integer range 0 to
                                       (2**STEER_ADDR_WIDTH)-1 := 0;
  Signal sig_steer_addr              : integer range 0 to
                                       (2**STEER_ADDR_WIDTH)-1 := 0;
  Signal sig_steer_addr_incr         : integer range 0 to 16  := 0;
  signal sig_incr_steer_addr         : std_logic;

  signal sig_ld_new_cmd              : std_logic;

  signal sig_cmd_cmplt_reg           : std_logic;
  signal sig_cmd_busy_reg            : std_logic;

  signal sig_sl_rdack_i              : std_logic;

  signal sig_npi_rdcnt_ld_value      : integer range 0 to
                                       2**NPI_RDCNT_SIZE;
  signal sig_npi_rdcnt               : integer range 0 to
                                       2**NPI_RDCNT_SIZE;
  signal sig_decr_npi_rdcnt          : std_logic;
  signal sig_decr_npi_rdcnt_int      : std_logic;

  signal sig_npi_rdcnt_eq_0          : std_logic;
  signal sig_npi_rdcnt_neq_0         : std_logic;

  Signal sig_plb_busy_reg            : std_logic;
  signal sig_clr_plb_dreg            : std_logic;

  Signal sig_advance_data2plb_int    : std_logic;
  Signal sig_advance_data2plb        : std_logic;

  signal sig_rdfifo_rdwdaddr_reg : std_logic_vector(0 to C_PI_RDWDADDR_WIDTH-1);

  signal sig_steer_addr_loaded   : std_logic;

  signal Rd2NPI_RdFIFO_Pop_reg   : std_logic;
  Signal sig_pop_valid_reg       : std_logic;

  signal sa_xfer                 : std_logic;

  signal RdFIFO_Empty            : std_logic;
  signal RdFIFO_Empty_reg        : std_logic;

  SIGNAL Sl_rdDAck_to_plb        : std_logic;
  SIGNAL Sl_rdDBus_to_plb        : std_logic_vector(0 to C_SPLB_DWIDTH-1);
  SIGNAL Sl_rdComp_to_plb        : std_logic;
  SIGNAL Sl_rdBTerm_to_plb       : std_logic;

  signal sig_cmd_cmplt_reg_dly   : std_logic;
  signal sig_cmd_busy_reg_dly    : std_logic;

-- Register duplication attribute assignments

  Attribute KEEP : string; -- declaration
  Attribute EQUIVALENT_REGISTER_REMOVAL : string; -- declaration

  Attribute KEEP of sig_sl_rdack   : signal is "TRUE"; -- definition
  Attribute KEEP of sig_sl_rdack_i : signal is "TRUE"; -- definition

  Attribute EQUIVALENT_REGISTER_REMOVAL of sig_sl_rdack   : signal is "no";
  Attribute EQUIVALENT_REGISTER_REMOVAL of sig_sl_rdack_i : signal is "no";



  -- Component Declarations



begin --(architecture implementation)

  -- Remap the PLB Clock and Reset signal names for
  -- internal use
   --Bus_Clk <=  SPLB_Clk;
   --Bus_Rst <=  SPLB_Rst;


  -- Output s
   Sl_MRdErr           <= (others => '0') ; --(no errors to report to PLB)

   Sl_rdBTerm          <= Sl_rdBTerm_to_plb  ;--            sig_sl_rdbterm  ;
   Sl_rdComp           <= Sl_rdComp_to_plb   ;--            sig_sl_rdcomp   ;
   Sl_rdDAck           <= Sl_rdDAck_to_plb   ;--            sig_sl_rdack    ;
   Sl_rdDBus           <= Sl_rdDBus_to_plb   ;--            sig_plb_rd_dreg   ;
   Sl_rdWdAddr         <= (others => '0') ;

   Rd2Ad_Rd_Cmplt      <= sig_cmd_cmplt_reg_dly;--          sig_cmd_cmplt_reg;
   Rd2Ad_Rd_Data_Cmplt <= Sl_rdComp_to_plb   ;--            sig_sl_rdcomp;

   Rd2Ad_Rd_Busy       <= sig_plb_busy_reg ;

   Rd2Ad_Rd_Error      <= sig_rd2ad_rd_error;

   Rd2NPI_RdFIFO_Flush <= '0';  -- currently not useable by MPMC

   Rd2NPI_RdFIFO_Pop   <= Rd2NPI_RdFIFO_Pop_reg;


   sig_ld_new_cmd      <= Ad2Rd_New_Cmd and
                          Ad2Rd_PLB_NPI_Sync;


   sig_rd2ad_rd_error     <= '0';


   sig_get_next_fifo_data <= Ad2Rd_PLB_NPI_Sync     and
                             sig_need_new_fifo_data and
                             sig_steer_addr_loaded;

  sig_pop_fifo <=  sig_xfer_go and sig_npi_rdcnt_neq_0;




   RdFIFO_EMPTY_DELAY : Process(Pi_clk)
   begin

      if rising_edge(Pi_clk) then
         if (PIM_Rst = '1') then
            RdFIFO_Empty_reg <= '0';
         else
            RdFIFO_Empty_reg <= RdFIFO_Empty;
         end if;
      end if;
   end process;



   REG_RD2NPI_RDFIFO_POP : Process(Pi_clk)
   begin

      if rising_edge(Pi_clk) then
         if (PIM_Rst = '1') then
            Rd2NPI_RdFIFO_Pop_reg <= '0';
            sa_xfer               <= '0';
         else
            if sa_xfer = '1' and sig_pop_fifo = '1' and Ad2Rd_PLB_NPI_Sync = '1' and Ad2rd_queue_data = '1' then
               Rd2NPI_RdFIFO_Pop_reg <= '1';
               sa_xfer               <= '0';
            elsif RdFIFO_Empty = '0' and RdFIFO_Empty_reg = '1' and sig_pop_fifo = '1' and Ad2Rd_PLB_NPI_Sync = '1' and Ad2rd_queue_data = '1' then
               Rd2NPI_RdFIFO_Pop_reg <= '1' ;
               sa_xfer               <= '0';
            elsif RdFIFO_Empty = '0' and RdFIFO_Empty_reg = '1' then
               Rd2NPI_RdFIFO_Pop_reg <= '0';
               sa_xfer               <= '1';
            else
               Rd2NPI_RdFIFO_Pop_reg <= '0';
               sa_xfer               <= sa_xfer;
            end if;

--            Rd2NPI_RdFIFO_Pop_reg <= sig_pop_fifo and
--                          not(NPI2RD_RdFIFO_Empty) and Ad2rd_queue_data and not Rd2NPI_RdFIFO_Pop_reg;
         end if;
      end if;
   end process;

  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_RD_BUSY
  --
  -- Process Description:
  -- This process implements the logic for the Busy signal sent
  -- to the Address Decoder Module. It is set when a new
  -- command is issued and deasserted when the read Complete
  -- is asserted from the PLB Read Bus.
  --
  -------------------------------------------------------------
  DO_PLB_RD_BUSY : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_plb_busy_reg <= '0';

          Elsif (sl_rdcomp_to_plb = '1' and--sig_sl_rdcomp      = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_plb_busy_reg <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_plb_busy_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_PLB_RD_BUSY;


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_XFER_GO
  --
  -- Process Description:
  --    This process implements the Transfer Go control
  --
  -------------------------------------------------------------
  DO_XFER_GO : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst      = '1' or
              --sm_xfer_done = '1') then
              sig_cmd_cmplt_reg = '1') then
            sig_xfer_go  <= '0';
          elsif (sig_ld_new_cmd = '1') then
            sig_xfer_go  <= '1';
          else
            null; -- hold current state
          end if;
       end if;
     end process DO_XFER_GO;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_CMD_CMPLT
  --
  -- Process Description:
  -- This process implements the logic for the Command complete
  -- flop. The flop asserts its output for 1 PLB clock cycle.
  --
  -- Note:  sm_xfer_done_ns is asserted only when the signal
  -- Ad2Rd_PLB_NPI_Sync is asserted.
  --
  -------------------------------------------------------------
  DO_CMD_CMPLT : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_cmd_cmplt_reg <= '0';

          Elsif (sig_cmd_cmplt_reg  = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_cmd_cmplt_reg <= '0';


          elsif (Ad2Rd_PLB_NPI_Sync      = '1' and
                 sig_rdcomp_reg          = '1' and
                 sig_sl_rdack_i          = '1' and
                 sig_cmd_busy_reg        = '1') then

            sig_cmd_cmplt_reg <= '1';


          --elsif (sm_xfer_done_ns = '1') then
          elsif (Ad2Rd_PLB_NPI_Sync      = '1' and
                 sig_plb_done            = '1' and
                 sig_cmd_busy_reg        = '1') then

            sig_cmd_cmplt_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_CMD_CMPLT;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_CMD_BUSY
  --
  -- Process Description:
  -- This process implements the logic for the Command Busy
  -- flop. The flop asserts its output while the Read Module
  -- is actively processing a read command.
  --
  -- Note:  sig_cmd_cmplt_reg is asserted for 1 PLB clock
  -- period.
  --
  -------------------------------------------------------------
  DO_CMD_BUSY : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_cmd_busy_reg <= '0';

          Elsif (sig_cmd_cmplt_reg  = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') Then

            sig_cmd_busy_reg <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_cmd_busy_reg <= '1';

          else
            null;  -- hold current state
          end if;
       end if;
     end process DO_CMD_BUSY;





  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_DOING_CACHELINE
  --
  -- Process Description:
  --    This process implements the registers to sample and
  -- hold the input qualifiers from the Address Decode block.
  --
  -------------------------------------------------------------
  REG_DOING_CACHELINE : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst      = '1' or
              --sm_xfer_done = '1') then
              sig_cmd_cmplt_reg = '1') then

            sig_doing_a_single_reg    <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_doing_a_single_reg    <= Ad2Rd_Single;

          else
            null; -- hold current state
          end if;
       end if;
     end process REG_DOING_CACHELINE;


  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: READ_SM_COMB
  --
  -- Process Description:
  -- This process implements the combinational half of the
  -- Read state machine.
  --
  -------------------------------------------------------------
  READ_SM_COMB : process (sm_state,
                          PIM_Rst,
                          sig_ld_new_cmd,
                          sig_plb_done,
                          Ad2Rd_PLB_NPI_Sync)

     begin


       If (PIM_Rst = '1') Then

         sm_state_ns          <= IDLE;
         sm_xfer_done_ns      <= '0';

       else

        -- Default values
         sm_state_ns          <= IDLE;
         sm_xfer_done_ns      <= '0';

         case sm_state is

           -----------------------
           when IDLE =>
           -----------------------

             if (sig_ld_new_cmd       = '1') then

               sm_state_ns        <= DATA_TO_PLB;

             else

              sm_state_ns      <= IDLE;

             End if;


           -----------------------
           when DATA_TO_PLB =>
           -----------------------

             If (sig_plb_done = '1') Then

               sm_state_ns      <= POSTFLUSH;

             else

               sm_state_ns      <= DATA_TO_PLB;

             End if;



           -----------------------
           when POSTFLUSH =>
           -----------------------

             If (Ad2Rd_PLB_NPI_Sync      = '1') then

               sm_state_ns      <= IDLE;
               sm_xfer_done_ns  <= '1';

             Else

               sm_state_ns      <= POSTFLUSH;

             End if;



           -----------------------
           when others =>
           -----------------------

             sm_state_ns      <= IDLE;

         end case;

       End if;

     end process READ_SM_COMB;



  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: READ_SM_SYNC
  --
  -- Process Description:
  -- This process implements the synchronous half of the
  -- Read state machine.
  --
  -------------------------------------------------------------
  READ_SM_SYNC : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then
            sm_state          <= IDLE;
            sm_xfer_done      <= '0' ;

          else
            sm_state          <= sm_state_ns       ;
            sm_xfer_done      <= sm_xfer_done_ns   ;

          end if;
       end if;
     end process READ_SM_SYNC;



  ---------------------------------------------------------------------
  -- Read POP Counter Logic
  -- This is used for tracking the number of fifo pops that actually
  -- are required to put read data on the PLB.  This is independent of
  -- pre-flush and post-flush operations.
  --
  ---------------------------------------------------------------------



   sig_npi_rdcnt_eq_0 <= '1'
      When (sig_npi_rdcnt = 0)
      Else '0';

    sig_npi_rdcnt_neq_0 <= not(sig_npi_rdcnt_eq_0);

   REG_DECR_RDCNT : process (pi_clk)
   begin

      if rising_edge(pi_clk) then
         if (PIM_Rst = '1') then
            sig_decr_npi_rdcnt_int <= '0';
         else
            sig_decr_npi_rdcnt_int <= (sig_pop_valid and   -- fifo has data
                                       sig_npi_rdcnt_neq_0 -- reading data that will
                                                         -- go to PLB via SRL FIFO
                                                           -- SRL FIFO not Full
                                       and Ad2Rd_PLB_NPI_Sync and Ad2rd_queue_data --do not clear count prematurely


                                      );


         end if;
      end if;
   end process;

   sig_decr_npi_rdcnt <= sig_decr_npi_rdcnt_int;


   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: NPI_RD_COUNTER
   --
   -- Process Description:
   --   This process implements the counter that keeps track of
   -- the needed fifo pop operations for supplying the actual
   -- requested read data to the PLB.
   --
   -------------------------------------------------------------
   NPI_RD_COUNTER : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then
           if (PIM_Rst = '1') then

             sig_npi_rdcnt <= 0;

           elsif (sig_ld_new_cmd = '1') then

             sig_npi_rdcnt <= sig_npi_rdcnt_ld_value;

           Elsif (sig_decr_npi_rdcnt  = '1' and
                  sig_npi_rdcnt_eq_0  = '0') Then

             sig_npi_rdcnt <= sig_npi_rdcnt-1;

           else
             null;  -- hold count value
           end if;
        end if;
      end process NPI_RD_COUNTER;



      sig_npi_rdcnt_ld_value <= 1; -- Always 1 for singles

  ---------------------------------------------------------------------
  -- Conversion for NPI Little Endian format to PLB Big Endian Format
  ---------------------------------------------------------------------


  -- Verilog snippet from MPMC2 PLB PIM for NPI Read FIFO Data
  -- // Byte reordering within read data bus
  -- generate
  --   for (i = 0; i < C_PI_DATA_WIDTH; i = i + 8) begin : rddata_reorder
  --     assign PI_RdFIFO_Data_i[i:i+7] = PI_RdFIFO_Data[i+7:i];
  --   end
  -- endgenerate




  -- VHDL version

  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: DATA_ENDIAN_CONVERT
  --
  -- Process Description:
  --    This process implements the conversion from little
  -- endian format to big endian format of the Read FIFO
  -- data.
  --
  -------------------------------------------------------------
  DATA_ENDIAN_CONVERT : process (NPI2RD_RdFIFO_D)

    Variable bit_index : integer;

    begin

      for byte_index in 0 to (C_NPI_DWIDTH/8)-1 loop

        bit_index := byte_index*8;

        sig_rdfifo_data_bigend(bit_index to bit_index+7) <=
                 NPI2RD_RdFIFO_D(bit_index+7 downto bit_index);

      end loop;

    end process DATA_ENDIAN_CONVERT;


  ---------------------------------------------------------------------
  -- End Conversion for NPI Little Endian format to PLB Big Endian Format
  ---------------------------------------------------------------------





  ---------------------------------------------------------------------
  -- Start Read FIFO Data Register and Support Logic
  ---------------------------------------------------------------------



   sig_make_fifo_dreg_stale  <=  sig_advance_data2plb and
                                 sig_need_new_fifo_data;


--   sig_fifo_dreg_has_data   <= not(sig_srl_fifo_empty) and Ad2rd_queue_data;
-- mw  sig_fifo_dreg_has_data   <= not(RdFIFO_Empty) and Ad2rd_queue_data;
   sig_fifo_dreg_has_data   <= not(RdFIFO_Empty_reg) and Ad2rd_queue_data and not(sa_xfer) ;
-------------------------------------------------------------------
-------------------------------------------------------------------
-- Read FIFO Data Register logic
--
-------------------------------------------------------------------

   sig_clr_fifo_read_dreg <=  (sig_rdcomp_reg  and
                               sig_sl_rdack_i  and
                               Ad2Rd_PLB_NPI_Sync) or
                               sig_plb_done;

   ------------------------------------------------------------
   -- Process Description:
   -- This process registers sig_pop_fifo and NPI2RD_RdFIFO_Empty
   --
   --
   ------------------------------------------------------------

   REG_SIG_POP_VALID : process (Pi_clk)
   begin

      if rising_edge(Pi_clk) then
         if PIM_Rst = '1' then
            sig_pop_valid_reg <= '0';
         else
            sig_pop_valid_reg <= sig_pop_fifo and not(sa_xfer) and
                                not(RdFIFO_Empty);
         end if;
      end if;
   end process;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_0
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 0.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_0 : if (C_PI_RDFIFO_LATENCY = 0) generate

      -- local signals
      signal sig_sl_rddbus_reg         : std_logic_vector(0 to
                                                  C_SPLB_DWIDTH-1);
      signal sig_advance_data2plb_dly1 : std_logic;

      begin

         sig_pop_valid <=  sig_pop_valid_reg;

         -------------------------------------------------------------------------
         --  Delay sig_advance_data2plb appropriately if the clock ratio is 1:1 or
         --  2:1
         -------------------------------------------------------------------------
         ADVANCE_DATA_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_advance_data2plb_dly1 <= '0';
               else
                  sig_advance_data2plb_dly1 <= Rd2NPI_RdFIFO_Pop_reg;
               end if;
            end if;
         end process ADVANCE_DATA_DLY;

         -------------------------------------------------------------------------
         --  Register NPI2RD_RdFIFO_Empty
         -------------------------------------------------------------------------
         READ_FIFO_EMPTY_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  RdFIFO_Empty <= '0';
               else
                  RdFIFO_Empty <= NPI2RD_RdFIFO_Empty;
               end if;
            end if;
         end process READ_FIFO_EMPTY_DLY;

         -------------------------------------------------------------------------
         --  Delay sig_sl_rddbus_int if the clock ratio is 2:1
         -------------------------------------------------------------------------
         REG_READ_DATA : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_sl_rddbus_reg <= (others => '0');
               else
                  sig_sl_rddbus_reg <= sig_sl_rddbus_int;
               end if;
            end if;
         end process REG_READ_DATA;

         -------------------------------------------------------------------------
         --  If the clock ratio is 1:1, then mux non delayed version of data
         --  to the next register stage.  Otherwise register delay is needed
         --  to align data with rising edge of plb clock
         -------------------------------------------------------------------------
--         MUX_READ_BUS : process(Ad2rd_clk_ratio_1_1)
--         begin
--
--           if Ad2rd_clk_ratio_1_1 = '1' then
--              sig_sl_rddbus <= sig_sl_rddbus_int;
--           else
--              sig_sl_rddbus <= sig_sl_rddbus_reg;
--           end if;
--        end process;

         sig_sl_rddbus <= sig_sl_rddbus_int when Ad2rd_clk_ratio_1_1 = '1' else
                          sig_sl_rddbus_reg;

         -------------------------------------------------------------------------
         --  Mux chip enable for the sig_sl_rddbus based upon clock ratio
         -------------------------------------------------------------------------
--         MUX_READ_BUS_CHIP_ENABLE : process(Ad2rd_clk_ratio_1_1)
--         begin
--
--            if Ad2rd_clk_ratio_1_1 = '1' then
--               sig_advance_data2plb <= Rd2NPI_RdFIFO_Pop_reg;
--            else
--               sig_advance_data2plb <= sig_advance_data2plb_dly1;
--            end if;
--         end process;

         sig_advance_data2plb <= Rd2NPI_RdFIFO_Pop_reg when Ad2rd_clk_ratio_1_1 = '1' else
                                 sig_advance_data2plb_dly1;

   end generate RD_LATENCY_0;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_1
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 1.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_1 : if (C_PI_RDFIFO_LATENCY = 1) generate

      -- local signals
      signal sig_npi_rdcnt_neq_0_dly1         : std_logic;
      signal wait_next                        : std_logic;

      begin

         sig_pop_valid <= sig_pop_valid_reg;
         sig_sl_rddbus <= sig_sl_rddbus_int;

         -------------------------------------------------------------
         --  Delay read count not equal to zero appropriately
         -------------------------------------------------------------
         DELAY_READ_COUNT : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_npi_rdcnt_neq_0_dly1 <= '0';
               else
                  sig_npi_rdcnt_neq_0_dly1 <= sig_npi_rdcnt_neq_0;
               end if;
            end if;
         end process DELAY_READ_COUNT;

         -------------------------------------------------------------------------
         --  Register NPI2RD_RdFIFO_Empty
         -------------------------------------------------------------------------
         READ_FIFO_EMPTY_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  RdFIFO_Empty <= '0';
               else
                  RdFIFO_Empty <= NPI2RD_RdFIFO_Empty;
               end if;
            end if;
         end process READ_FIFO_EMPTY_DLY;

         -------------------------------------------------------------------------
         --  Delay sig_advance_data2plb appropriately if the clock ratio is 1:1 or
         --  2:1
         -------------------------------------------------------------------------
         ADVANCE_DATA_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_advance_data2plb <= '0';
               else
                  sig_advance_data2plb <= Rd2NPI_RdFIFO_Pop_reg;
               end if;
            end if;
         end process ADVANCE_DATA_DLY;

   end generate RD_LATENCY_1;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: RD_LATENCY_2
   --
   -- If Generate Description:
   -- This IfGen implements the RdFIFO Latency case of 2.
   --
   --
   ------------------------------------------------------------
   RD_LATENCY_2 : if (C_PI_RDFIFO_LATENCY = 2) generate

      -- local signals
      signal sig_npi_rdcnt_neq_0_dly1         : std_logic;
      signal sig_npi_rdcnt_neq_0_dly2         : std_logic;

      signal sig_advance_data2plb_dly1        : std_logic;
      signal sig_advance_data2plb_dly2        : std_logic;
      signal sig_advance_data2plb_dly3        : std_logic;

      signal sig_sl_rddbus_reg                : std_logic_vector(0 to
                                                  C_SPLB_DWIDTH-1);

      begin

         sig_pop_valid <= sig_pop_valid_reg;

         -------------------------------------------------------------
         --  Delay read count not equal to zero appropriately
         -------------------------------------------------------------
         DELAY_READ_COUNT : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_npi_rdcnt_neq_0_dly1 <= '0';
                  sig_npi_rdcnt_neq_0_dly2 <= '0';
               else
                  sig_npi_rdcnt_neq_0_dly1 <= sig_npi_rdcnt_neq_0;
                  sig_npi_rdcnt_neq_0_dly2 <= sig_npi_rdcnt_neq_0_dly1;
               end if;
            end if;
         end process DELAY_READ_COUNT;

         -------------------------------------------------------------------------
         --  Register NPI2RD_RdFIFO_Empty
         -------------------------------------------------------------------------
         READ_FIFO_EMPTY_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  RdFIFO_Empty <= '0';
               else
                  RdFIFO_Empty <= NPI2RD_RdFIFO_Empty;
               end if;
            end if;
         end process READ_FIFO_EMPTY_DLY;

         -------------------------------------------------------------------------
         --  Delay sig_advance_data2plb appropriately if the clock ratio is 1:1 or
         --  2:1
         -------------------------------------------------------------------------
         ADVANCE_DATA_DLY : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_advance_data2plb_dly1 <= '0';
                  sig_advance_data2plb_dly2 <= '0';
                  sig_advance_data2plb_dly3 <= '0';
               else
                  sig_advance_data2plb_dly1 <= Rd2NPI_RdFIFO_Pop_reg;
                  sig_advance_data2plb_dly2 <= sig_advance_data2plb_dly1;
                  sig_advance_data2plb_dly3 <= sig_advance_data2plb_dly2;

               end if;
            end if;
         end process ADVANCE_DATA_DLY;

         -------------------------------------------------------------------------
         --  Delay sig_sl_rddbus_int if the clock ratio is 2:1
         -------------------------------------------------------------------------
         REG_READ_DATA : process (PI_Clk)
         begin
            if (PI_Clk'event and PI_Clk = '1') then
               if (PIM_Rst = '1') then
                  sig_sl_rddbus_reg <= (others => '0');
               else
                  sig_sl_rddbus_reg <= sig_sl_rddbus_int;
               end if;
            end if;
         end process REG_READ_DATA;

         -------------------------------------------------------------------------
         --  If the clock ratio is 1:1, then mux non delayed version of data
         --  to the next register stage.  Otherwise register delay is needed
         --  to align data with rising edge of plb clock
         -------------------------------------------------------------------------
--         MUX_READ_BUS : process(Ad2rd_clk_ratio_1_1)
--         begin
--
--            if Ad2rd_clk_ratio_1_1 = '1' then
--               sig_sl_rddbus <= sig_sl_rddbus_int;
--            else
--               sig_sl_rddbus <= sig_sl_rddbus_reg;
--            end if;
--         end process;
--
           sig_sl_rddbus <= sig_sl_rddbus_int when Ad2rd_clk_ratio_1_1 = '1' else
                            sig_sl_rddbus_reg;

         -------------------------------------------------------------------------
         --  Mux chip enable for the sig_sl_rddbus based upon clock ratio
         -------------------------------------------------------------------------
--         MUX_READ_BUS_CHIP_ENABLE : process(Ad2rd_clk_ratio_1_1)
--         begin
--
--            if Ad2rd_clk_ratio_1_1 = '1' then
--               sig_advance_data2plb <= sig_advance_data2plb_dly1;
--            else
--               sig_advance_data2plb <= sig_advance_data2plb_dly2;
--            end if;
--         end process;

           sig_advance_data2plb <= sig_advance_data2plb_dly2 when Ad2rd_clk_ratio_1_1 = '1' else
                                   sig_advance_data2plb_dly3;



   end generate RD_LATENCY_2;





-------------------------------------------------------------------
-------------------------------------------------------------------
  -- Start PLB Read Bus Controls


   sig_sl_rdbterm   <='0';

   sig_sl_rdcomp    <=  sig_rdcomp_reg and
                        sig_sl_rdack_i;


-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Read Data Steering Address Counter Logic
--
-------------------------------------------------------------------


   -------------------------------------------------------------
   -- Combinational Process
   --
   -- Label: RIP_STEER_ADDR
   --
   -- Process Description:
   -- This process rips the lower 4 bits of the starting address
   -- and overlays them into the lower 4 bits of the Steering
   -- Address Load value
   --
   -------------------------------------------------------------
   RIP_STEER_ADDR : process (Ad2Rd_Strt_Addr)
     begin

       -- Init to zeros
       sig_steer_addr_ld_value_slv <= (others => '0');

       -- Now rip 4 address bits
       sig_steer_addr_ld_value_slv(STEER_ADDR_WIDTH-4 to
                                   STEER_ADDR_WIDTH-1)
           <= Ad2Rd_Strt_Addr(C_SPLB_AWIDTH-4 to
                              C_SPLB_AWIDTH-1);


     end process RIP_STEER_ADDR;





   sig_steer_addr_ld_value <=
        CONV_INTEGER('0' & sig_steer_addr_ld_value_slv);


    sig_incr_steer_addr  <= sig_advance_data2plb;


    sig_steer_addr_slv <=
        CONV_STD_LOGIC_VECTOR(sig_steer_addr,
                              STEER_ADDR_WIDTH);




   sig_steer_addr_incr <= sig_steer_addr_incr;
                          --assign sig_steer_addr_incr from generate
                          --statement to sig_steer_addr_incr outside of
                          --generate statement.  Removes modelsim
                          --warnings about multiple sources


   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: DO_STEER_ADDR_CNTR
   --
   -- Process Description:
   --   This process implements the Read Data Steering address
   -- counter.
   --
   -------------------------------------------------------------
   DO_STEER_ADDR_CNTR : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then

           if (PIM_Rst            = '1' or
              (sig_cmd_cmplt_reg  = '1' and
               Ad2Rd_PLB_NPI_Sync = '1')) then

             sig_steer_addr        <= 0;
             sig_steer_addr_loaded <= '0';

           elsif (sig_ld_new_cmd      = '1' and
                  Ad2Rd_PLB_NPI_Sync  = '1') then

             sig_steer_addr        <= sig_steer_addr_ld_value;
             sig_steer_addr_loaded <= '1';


           Elsif (sig_incr_steer_addr = '1') Then

             sig_steer_addr <= sig_steer_addr +
                               sig_steer_addr_incr;
             sig_steer_addr_loaded <= '1';

           else
             null;  -- hold current value
           end if;
        end if;
      end process DO_STEER_ADDR_CNTR;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: DATA_LOOKAHEAD_NPI32
   --
   -- If Generate Description:
   --   This IfGen implements the logic needed to request more
   -- FIFO data relative to the PLB Data transfer width.
   -- In this case the NPI width is 32 so new FIFO data will be
   -- needed every PLB data beat.
   --
   ------------------------------------------------------------
   DATA_LOOKAHEAD_NPI32 : if (C_NPI_DWIDTH = 32) generate
      signal sig_steer_addr_incr  : integer range 0 to 16  := 0;

      begin

         sig_need_new_fifo_data <= '1';
         sig_steer_addr_incr    <= 4;

      end generate DATA_LOOKAHEAD_NPI32;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: DATA_LOOKAHEAD_NPI64
   --
   -- If Generate Description:
   --   This IfGen implements the logic needed to request more
   -- FIFO data relative to the PLB Data transfer width.
   -- In this case the NPI width is 64 so new FIFO data will be
   -- needed every other PLB data beat if the transfer width is
   -- 32, or every data beat if the transfer width is 64.
   --
   ------------------------------------------------------------
   DATA_LOOKAHEAD_NPI64 : if (C_NPI_DWIDTH = 64) generate
      signal sig_steer_addr_incr  : integer range 0 to 16  := 0;

      signal lsig_xfer_mode       : XFER_WIDTH_TYPE;

      begin

         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: S_H_TRANSFER_MODE_64
         --
         -- Process Description:
         --     This process samples and holds the PLB transfer width
         -- for the ensuing Read data phase.
         --
         -------------------------------------------------------------
         S_H_TRANSFER_MODE_64 : process (PI_Clk)
            begin
              if (PI_Clk'event and PI_Clk = '1') then
                 if (PIM_Rst      = '1' or
                     --sm_xfer_done = '1') then
                     sig_cmd_cmplt_reg = '1') then

                   lsig_xfer_mode      <= WORD;
                   sig_steer_addr_incr <= 4;

                 elsif (sig_ld_new_cmd     = '1' and
                        Ad2Rd_PLB_NPI_Sync = '1') then

                   If (Ad2Rd_Xfer_Width = "00") Then

                     lsig_xfer_mode      <= WORD; -- 32 bit xfer
                     sig_steer_addr_incr <= 4;

                   else

                     lsig_xfer_mode      <= DBLWRD; -- 64 bit xfer
                     sig_steer_addr_incr <= 8;

                   End if;

                 else
                   null; -- hold current state
                 end if;
              end if;
            end process S_H_TRANSFER_MODE_64;


         sig_need_new_fifo_data <=
                    sig_steer_addr_slv(WRD_ADDR_BIT_INDEX)
          when  (lsig_xfer_mode = WORD)
          else '1';   -- DWRD Xfer


      end generate DATA_LOOKAHEAD_NPI64;



   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: DATA_LOOKAHEAD_NPI128
   --
   -- If Generate Description:
   --   This IfGen implements the logic needed to request more
   -- FIFO data relative to the PLB Data transfer width and the
   -- state of the data steering address counter.
   -- In this case the NPI width is 128 so new FIFO data will be
   -- needed on:
   --  - Every 4th PLB data beat if the transfer width is 32
   --  - Every 2nd PLB data beat if the transfer width is 64
   --  - Every PLB data beat if the transfer width is 128.
   --
   ------------------------------------------------------------
   DATA_LOOKAHEAD_NPI128 : if (C_NPI_DWIDTH = 128) generate

       signal sig_steer_addr_incr  : integer range 0 to 16  := 0;
       signal lsig_xfer_mode       : XFER_WIDTH_TYPE;
       Signal lsig_addr45_and      : std_logic;
       Signal lsig_addr4           : std_logic;


      begin


         lsig_addr45_and <= sig_steer_addr_slv(DWRD_ADDR_BIT_INDEX) and
                            sig_steer_addr_slv(WRD_ADDR_BIT_INDEX);

         lsig_addr4      <= sig_steer_addr_slv(DWRD_ADDR_BIT_INDEX);




         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: S_H_TRANSFER_MODE_128
         --
         -- Process Description:
         --     This process samples and holds the PLB transfer width
         -- for the ensuing Read data phase.
         --
         -------------------------------------------------------------
         S_H_TRANSFER_MODE_128 : process (PI_Clk)
            begin
              if (PI_Clk'event and PI_Clk = '1') then
                 if (PIM_Rst           = '1' or
                     --sm_xfer_done = '1') then
                     sig_cmd_cmplt_reg = '1') then

                   lsig_xfer_mode      <= WORD;
                   sig_steer_addr_incr <= 4;

                 elsif (sig_ld_new_cmd     = '1' and
                        Ad2Rd_PLB_NPI_Sync = '1') then

                   If (Ad2Rd_Xfer_Width = "00") Then

                     lsig_xfer_mode      <= WORD; -- 32 bit xfer
                     sig_steer_addr_incr <= 4;

                   elsif (Ad2Rd_Xfer_Width = "01") Then

                     lsig_xfer_mode      <= DBLWRD; -- 64 bit xfer
                     sig_steer_addr_incr <= 8;

                   else

                     lsig_xfer_mode      <= QWRD; -- 128 bit xfer
                     sig_steer_addr_incr <= 16;

                   End if;

                 else
                   null; -- hold current state
                 end if;
              end if;
            end process S_H_TRANSFER_MODE_128;


         sig_need_new_fifo_data <= lsig_addr45_and
          when (lsig_xfer_mode = WORD)
          Else lsig_addr4
          When (lsig_xfer_mode = DBLWRD)
          Else '1';     -- QWRD xfer


      end generate DATA_LOOKAHEAD_NPI128;

-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Data Beat Counter Logic
--
-------------------------------------------------------------------


  sig_wdcnt_to_dbeats_slv <= DBEAT_OF_1;

  sig_plb_dbeat_cnt_ld_value <= CONV_INTEGER('0' & sig_wdcnt_to_dbeats_slv);

  sig_decr_dbeat_cnt <= sig_sl_rdack_i and
                        Ad2Rd_PLB_NPI_Sync;


  sig_dbcnt_eq_0 <= '1'
    when  sig_plb_dbeat_cnt = 0
    Else '0';


  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_DBEAT_CNT
  --
  -- Process Description:
  --    This process implements the PLB Read data beat counter.
  --
  -------------------------------------------------------------
  DO_PLB_DBEAT_CNT : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst = '1') then

            sig_plb_dbeat_cnt <= 0;

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1') then

            sig_plb_dbeat_cnt <= sig_plb_dbeat_cnt_ld_value;

          Elsif (sig_decr_dbeat_cnt = '1' and
                 sig_dbcnt_eq_0     = '0') Then

            sig_plb_dbeat_cnt <= sig_plb_dbeat_cnt - 1;

          else

            null; -- hold current value

          end if;
       end if;
     end process DO_PLB_DBEAT_CNT;








-------------------------------------------------------------------
-------------------------------------------------------------------
-- PLB Read Complete Logic
--
-------------------------------------------------------------------



   sig_clr_rdcomp <= sig_rdcomp_reg   and
                     sig_sl_rdack_i   and
                     Ad2Rd_PLB_NPI_Sync;




  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_RD_COMP
  --
  -- Process Description:
  --  This process implements the flop that generates the read
  -- complete signal.
  --
  -------------------------------------------------------------
  DO_RD_COMP : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst        = '1' or
              sig_clr_rdcomp = '1') then

            sig_rdcomp_reg <= '0';

          elsif (sig_ld_new_cmd     = '1' and
                 Ad2Rd_PLB_NPI_Sync = '1' and
                 Ad2Rd_Single       = '1') then

            sig_rdcomp_reg <= '1';

          else
            null; -- hold state
          end if;
       end if;
     end process DO_RD_COMP;




  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DO_PLB_DONE
  --
  -- Process Description:
  --    This process implements the flop that generates the
  -- flag indicating the PLB Read Data Phase is complete for
  -- the last request from the Address Decoder.
  --
  -------------------------------------------------------------
  DO_PLB_DONE : process (PI_Clk)
     begin
       if (PI_Clk'event and PI_Clk = '1') then
          if (PIM_Rst             = '1' or
              (sig_ld_new_cmd     = '1' and
               Ad2Rd_PLB_NPI_Sync = '1')) then

            sig_plb_done <= '0';

          elsif (Ad2Rd_PLB_NPI_Sync = '1' and
                 sig_rdcomp_reg     = '1' and
                 sig_sl_rdack_i     = '1') then

            sig_plb_done  <= '1';

          else
            null;  -- hold state
          end if;
       end if;
     end process DO_PLB_DONE;





  sig_rdfifo_data_reg      <= sig_rdfifo_data_bigend(0 to (C_SPLB_NATIVE_DWIDTH-1));

  ------------------------------------------------------------
  -- Instance: I_DATA_SUPPORT
  --
  -- Description:
  --    This module performs the required read data bus
  -- mirroring and steering functionality for connection
  -- to the PLBV46.
  --
  ------------------------------------------------------------
   I_DATA_SUPPORT : entity plbv46_pim_v2_01_a.data_steer_mirror
   generic map (
     C_STEER_ADDR_WIDTH   =>  STEER_ADDR_WIDTH      ,
     C_SPLB_DWIDTH        =>  C_SPLB_DWIDTH         ,
     C_SPLB_NATIVE_DWIDTH =>  C_SPLB_NATIVE_DWIDTH  ,
     C_SMALLEST_MASTER    =>  C_SPLB_SMALLEST_MASTER
     )
   port map (

     Steer_Addr_In   =>  sig_steer_addr_slv ,
     Data_In         =>  sig_rdfifo_data_reg,
     Data_Out        =>  sig_sl_rddbus_int
     );


   ---------------------------------------------------------------
   --
   -- PLB Read Data Register Logic
   --
   sig_advance_data2plb_int <=  sig_steer_addr_loaded  and
                            sig_fifo_dreg_has_data and
                            Ad2Rd_PLB_NPI_Sync;




   sig_clr_plb_dreg <=  PIM_Rst or
                        sig_plb_done or
                        (
                         sig_sl_rdack_i     and
                         Ad2Rd_PLB_NPI_Sync and
                          (
                            not(sig_fifo_dreg_has_data) or
                            sig_rdcomp_reg
                          )
                        );


   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_RD_DATA
   --
   -- Process Description:
   -- This process implements the PLB Read Data Register. The
   -- PLB Read data is mirrored and Steered prior to input to
   -- this register.
   --
   -------------------------------------------------------------
   REG_PLB_RD_DATA : process (PI_Clk)
      begin
        if (PI_Clk'event and PI_Clk = '1') then
           if (sig_clr_plb_dreg = '1') then

             sig_plb_rd_dreg      <= (others => '0');
             sig_sl_rdack         <= '0';
             sig_sl_rdack_i       <= '0';

           Elsif (sig_advance_data2plb = '1') Then

             sig_plb_rd_dreg      <= sig_sl_rddbus;
             sig_sl_rdack         <= '1'; -- to bus
             sig_sl_rdack_i       <= '1'; -- internal use

           else

             null;  -- hold state

           end if;
        end if;
      end process REG_PLB_RD_DATA;

         -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_RD_DATA
   --
   -- Process Description:
   -- This process implements the PLB Read Data Register. The
   -- PLB Read data is mirrored and Steered prior to input to
   -- this register.
   --
   -------------------------------------------------------------
   REG_PLB_RD_DATA_TO_PLB : process (SPLB_Clk)
      begin
        if (SPLB_Clk'event and SPLB_Clk = '1') then
           if (pim_rst = '1') then
             Sl_rdDAck_to_plb    <= '0';
             Sl_rdDBus_to_plb    <= (others => '0');
             Sl_rdComp_to_plb    <= '0';
             Sl_rdBTerm_to_plb   <= '0';

             sig_cmd_cmplt_reg_dly <= '0';
             sig_cmd_busy_reg_dly  <= '0';
           Else
             Sl_rdDAck_to_plb    <= sig_sl_rdack;
             Sl_rdDBus_to_plb    <= sig_plb_rd_dreg;
             Sl_rdComp_to_plb    <= sig_sl_rdcomp;
             Sl_rdBTerm_to_plb   <= sig_sl_rdbterm;

             sig_cmd_cmplt_reg_dly <= sig_cmd_cmplt_reg;
             sig_cmd_busy_reg_dly  <= sig_cmd_busy_reg;
           end if;
        end if;
      end process REG_PLB_RD_DATA_TO_PLB;
end implementation;
