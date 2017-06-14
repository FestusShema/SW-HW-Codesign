-------------------------------------------------------------------------------
-- $Id: rd_wr_controller.vhd,v 1.9 2007/07/13 23:39:59 dougt Exp $
-------------------------------------------------------------------------------
-- rd_wr_controller.vhd
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
-- Filename:        rd_wr_controller.vhd
--
-- Description:     
--                  
--      This VHDL design file implements the Read Control logic for the
--  PLB Master Burst.
--  This Read Controller is optimized based on the following criteria:
--      - Only Single Data Beats and Fixed Length bursts of 2 to 16 data 
--        beats are supported.
--      - A PLB Slave premature burst terminate is completed with a LLink
--        destination discontinue and a command error status back to the
--        requesting User Logic. No automatic request respawning.               
--      - Premature burst termination is detected if a Slave Burst terminate
--        occurs before an internal data beat counter reaches completion.            
--      - This Master does not generate cacheline requests            
-- 
--
--                 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              rd_wr_controller.vhd
--               |   
--               |-- rd_wr_calc_burst.vhd     
--                  
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $$
-- Date:            $$
--
-- History:
--   DET   10/11/2006       Initial Version
--                      
--
--
--     DET     12/11/2006     Initial
-- ~~~~~~
--     - Added timeout condition to keep both read and write state machines in
--       the IDLE state until a detected timeout is cleared from the timeout 
--       sample and hold flop at Command compete status assertion.
-- -- ^^^^^^
--
--     DET     12/15/2006     Initial
-- ~~~~~~
--     - Fixed a problem where the make request flop didn't get cleared
--       when a PLB_MTimeout assertion occured. This caused an error with
--       an ensuing command after the Timout.
-- ^^^^^^
--
--     DET     1/12/2007     Initial
-- ~~~~~~
--     - Added additional state machine state to check for Timeout completion
--       before looking at request input from User Logic.
-- ^^^^^^
--
--     DET     2/1/2007     Initial
-- ~~~~~~
--     - Disabled premature burst termination detection logic
--     - Added Bus Lock Assertion FLOP to meet PLB Assertion requirments
-- ^^^^^^
--
--
--     DET     2/14/2007     Initial
-- ~~~~~~
--     - Added register output stage for M_RNW, M_BE, and M_size.
-- ^^^^^^
--
--     DET     7/13/2007     jm.13+
-- ~~~~~~
--     - Corrected missing reset from various flops and registers.
--     - Removed the IP2Bus_Mst_Reset from the port list. Bus_rst
--       port is now the only reset input for this module.
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
use ieee.std_logic_unsigned.all;  
use ieee.std_logic_arith.all;  

library proc_common_v2_00_a; -- Proc IP Common lib
use proc_common_v2_00_a.proc_common_pkg.log2;

library plbv46_master_burst_v1_00_a; -- Proc IP Common lib
use plbv46_master_burst_v1_00_a.rd_wr_calc_burst;

library unisim; -- Required for Xilinx primitives
use unisim.vcomponents.all;  


-------------------------------------------------------------------------------

entity rd_wr_controller is
  generic (
     C_LENGTH_WIDTH      : Integer := 12;
     C_AWIDTH            : Integer := 32;
     C_NATIVE_DWIDTH     : Integer := 32;
     C_LLINK_REM_WIDTH   : Integer := 4 ;   
     C_LLINK_DWIDTH      : Integer := 32     
    );
  port (

   -- System Ports
     Bus_Clk                  : in  std_logic;
     Bus_Rst                  : in  std_logic;
     MD_Error                 : Out std_logic;
     
   -- Master Request/Qualifiers to PLB V4.6 (outputs)
     M_request                : out std_logic;
     M_priority               : out std_logic_vector(0 to 1);
     M_busLock                : out std_logic;
     M_RNW                    : out std_logic;
     M_BE                     : out std_logic_vector(0 to 
                                    (C_NATIVE_DWIDTH/8)-1);
     M_MSize                  : out std_logic_vector(0 to 1);
     M_size                   : out std_logic_vector(0 to 3);
     M_type                   : out std_logic_vector(0 to 2);
     M_ABus                   : out std_logic_vector(0 to 31);
     M_wrBurst                : out std_logic;
     M_rdBurst                : out std_logic;
     M_wrDBus                 : out std_logic_vector(0 to 
                                    C_NATIVE_DWIDTH-1);

   -- PLB Reply to Master (inputs)
     PLB_MAddrAck             : in  std_logic;
     PLB_MSSize               : in  std_logic_vector(0 to 1);
     PLB_MRearbitrate         : in  std_logic;
     PLB_MTimeout             : in  std_logic;
     PLB_MBusy                : in  std_logic;
     PLB_MRdErr               : in  std_logic;
     PLB_MWrErr               : in  std_logic;
     PLB_MRdDBus              : in  std_logic_vector(0 to 
                                    C_NATIVE_DWIDTH-1);
     PLB_MRdDAck              : in  std_logic;
     PLB_MRdBTerm             : in  std_logic;
     PLB_MWrDAck              : in  std_logic;
     PLB_MWrBTerm             : in  std_logic;


   -- IP Master Request/Qualifiers
     IP2Bus_MstRd_Req         : in  std_logic;
     IP2Bus_MstWr_Req         : in  std_logic;
     IP2Bus_Mst_Addr          : in  std_logic_vector(0 to C_AWIDTH-1);
     IP2Bus_Mst_Length        : in  std_logic_vector(0 to 11);
     IP2Bus_Mst_BE            : in  std_logic_vector(0 to 
                                   (C_NATIVE_DWIDTH/8)-1);     
     IP2Bus_Mst_Type          : in  std_logic;
     IP2Bus_Mst_Lock          : in  std_logic;
     -- IP2Bus_Mst_Reset         : in  std_logic;
     
   -- IP Master Primary Read Request Status Reply
     Bus2IP_Mst_CmdAck        : out std_logic;
     Bus2IP_Mst_Cmplt         : out std_logic;
     Bus2IP_Mst_Error         : out std_logic;
     Bus2IP_Mst_Rearbitrate   : out std_logic;
     Bus2IP_Mst_Cmd_Timeout   : out std_logic;
   
   
   -- Read LocalLink Backend Control  
     Rd_PLB2LL_Init           : Out std_logic;                                
     Rd_PLB2LL_Activate       : out std_logic;                                
     Rd_PLB2LL_Src_Dsc        : out std_logic;                                
     Rd_LL2PLB_Rdy            : in  std_logic;                                
     Rd_LL2PLB_Done           : in  std_logic;                                
     Rd_LL2PLB_Dest_Dsc       : in  std_logic;
                                     
   
   -- Read LLink Flow Control
     Rd_LL2PLB_FIFO_Full        : in  std_logic;
     Rd_LL2PLB_FIFO_Almost_Full : in  std_logic;
                                                                            
   -- Read LocalLink Backend Data  
     Rd_PLB2LL_Fifo_Wen       : out std_logic;                               
     Rd_PLB2LL_Fifo_Sop       : out std_logic;                               
     Rd_PLB2LL_Fifo_Eop       : out std_logic;                               
     Rd_PLB2LL_Fifo_Rem       : out std_logic_vector(0 to C_LLINK_REM_WIDTH-1);
     Rd_PLB2LL_Fifo_Data      : out std_logic_vector(0 to C_LLINK_DWIDTH- 1);  
    
    
     
   -- Write LocalLink Backend Control  
     Wr_PLB2LL_Init           : out std_logic;                               
     Wr_PLB2LL_Activate       : out std_logic;                               
     Wr_PLB2LL_Dst_Dsc        : out std_logic;                               
     Wr_LL2PLB_Rdy            : in  std_logic;
     Wr_LL2PLB_Done           : in  std_logic;
     Wr_LL2PLB_Src_Dsc_Rcvd   : in  std_logic;
     
   -- Write LocalLink Backend Data  
     Wr_PLB2LL_Clr_Data_Valid : out std_logic;                               
     Wr_PLB2LL_Fifo_Ren       : out std_logic;                               
     Wr_LL2PLB_Fifo_Sof       : in  std_logic;                               
     Wr_LL2PLB_Fifo_Eof       : in  std_logic;                               
     Wr_LL2PLB_Fifo_Sop       : in  std_logic;                               
     Wr_LL2PLB_Fifo_Eop       : in  std_logic;                               
     Wr_LL2PLB_Fifo_Rem       : in  std_logic_vector(0 to C_LLINK_REM_WIDTH-1);
     Wr_LL2PLB_Fifo_Data      : in  std_logic_vector(0 to C_LLINK_DWIDTH- 1);  
     Wr_LL2PLB_Rddata_Valid   : in  std_logic                               
      
      );

end entity rd_wr_controller;


architecture implementation of rd_wr_controller is


   -- Functions Declarations
     -------------------------------------------------------------------
     -- Function
     --
     -- Function Name: encode_mstr_size
     --
     -- Function Description:
     --     This function encodes the Master Native Data Width into 
     -- a 2-bit field for PLB_Msize output.
     --
     -------------------------------------------------------------------
     function encode_mstr_size(native_dwidth : integer) 
              return std_logic_vector is
     
       variable temp_size : std_logic_vector(0 to 1);
     
     begin
     
       case native_dwidth is
         when 64 =>
           temp_size := "01"; -- 64 bits wide
         when 128 =>
           temp_size := "10"; -- 128 bits wide
         when others =>
           temp_size := "00"; -- 32 bits wide
       end case;
       
       Return(temp_size);
        
     end function encode_mstr_size;
     
      
      
     
   -- Types Declarations        
 
      type RD_CNTL_STATES is (RD_IDLE,
                              RD_CMD_CALC,
                              RD_WAIT_ADDRACK,
                              RD_DPHASE,
                              RD_CHK_DONE,
                              RD_LLINK_DISCONTINUE,
                              RD_WAIT_ON_TMOUT_CLR
                            );
       
      type WR_CNTL_STATES is (WR_IDLE,
                              WR_CMD_CALC,
                              WR_WAIT_ADDRACK,
                              WR_DPHASE,
                              WR_CHK_DONE,
                              WR_LLINK_DISCONTINUE,
                              WR_WAIT_ON_TMOUT_CLR
                             );

       
         
   -- Constants Declarations
      
      Constant MAX_FLBURST_DB_CNT  : Integer := 16; 
      --Constant BE_WIDTH            : integer := C_NATIVE_DWIDTH/8;
      Constant REM_WIDTH           : integer := C_LLINK_REM_WIDTH;
      Constant REM_ALL_ASSERT      : std_logic_vector(0 to REM_WIDTH-1)
                                             := (others => '1'); 
 
 
    
   -- Signals Declarations
                              
    -- plb inputs registered  
      Signal plb_mrderr_reg          : std_logic;
      Signal plb_mrddack_reg         : std_logic;
      Signal plb_mrddbus_reg         : std_logic_vector(0 to 
                                       C_NATIVE_DWIDTH-1);
      Signal plb_mwrerr_reg          : std_logic;                            
      Signal plb_mwrdack_reg         : std_logic;                            
                                                 
    
                             
     -- Read State machine signals
      Signal sm_rdcntl_state_ns      : RD_CNTL_STATES;
      Signal sm_rdcntl_state         : RD_CNTL_STATES;
      Signal sm_rd_get_new_cmd       : std_logic;
      Signal sm_rd_get_new_cmd_ns    : std_logic;
      Signal sm_post_rdreq_ns        : std_logic;
      Signal sm_post_rdreq           : std_logic;
      Signal sm_set_rd_err_ns        : std_logic;
      Signal sm_set_rd_err           : std_logic;
      Signal sm_rdllink_dsc_ns       : std_logic;
      Signal sm_rdllink_dsc          : std_logic; 
      Signal sm_ip_rd_cmplt_ns       : std_logic;
      Signal sm_ip_rd_cmplt          : std_logic;
      Signal sm_rd_llink_init        : std_logic;
      Signal sm_rd_llink_init_ns     : std_logic;
      Signal sm_rd_llink_activate    : std_logic;
      Signal sm_rd_llink_activate_ns : std_logic;
      
      
     -- Write State machine signals
      Signal sm_wrcntl_state_ns      : WR_CNTL_STATES;
      Signal sm_wrcntl_state         : WR_CNTL_STATES;
      Signal sm_wr_get_new_cmd       : std_logic;
      Signal sm_wr_get_new_cmd_ns    : std_logic;
      Signal sm_post_wrreq_ns        : std_logic;
      Signal sm_post_wrreq           : std_logic;
      Signal sm_set_wr_err_ns        : std_logic;
      Signal sm_set_wr_err           : std_logic;
      Signal sm_wrllink_dsc_ns       : std_logic;
      Signal sm_wrllink_dsc          : std_logic; 
      Signal sm_ip_wr_cmplt_ns       : std_logic;
      Signal sm_ip_wr_cmplt          : std_logic;
      Signal sm_wr_llink_init        : std_logic;
      Signal sm_wr_llink_init_ns     : std_logic;
      Signal sm_wr_llink_activate    : std_logic;
      Signal sm_wr_llink_activate_ns : std_logic;
      signal sm_plb_ld_wrdata_reg    : std_logic;
      signal sm_plb_ld_wrdata_reg_ns : std_logic;
      
      
      
     -- Request/Reply signals 
      Signal sig_cmd_timeout_reg      : std_logic;
      Signal sig_clr_cmd_timeout_reg  : std_logic;
   
     
      -- Misc signals
      Signal sig_data_xfer_done       : std_logic;
      Signal deassert_rderr           : std_logic;
      Signal set_rderr                : std_logic;
      Signal sig_mstrd_error          : std_logic;
      
    -- Request Generation Flop 
      Signal m_request_i              : std_logic;
      Signal sig_clr_request_flop     : std_logic;
      signal sig_set_request_flop     : std_logic;
 
    -- Read Burst Generation Flop 
      Signal m_rdburst_i              : std_logic;
      Signal clear_rdburst            : std_logic;
      signal sig_rdburst_flop_en      : std_logic;
      signal sig_length_rdterm_event  : std_logic;
      Signal sig_slave_rdterm_event   : std_logic;
 
    -- Write Burst Generation Flop 
      Signal m_wrburst_i              : std_logic;
      Signal clear_wrburst            : std_logic;
      signal sig_wrburst_flop_en      : std_logic;
      signal sig_length_wrterm_event  : std_logic;
      Signal sig_slave_wrterm_event   : std_logic;
 
    -- Bus Lock Request Generation Flop 
      Signal m_buslock_i              : std_logic;
      Signal sig_clr_buslock_flop     : std_logic;
      signal sig_set_buslock_flop     : std_logic;
 
 
  
    -- General signals

      Signal sig_rdllink_dst_rdy          : std_logic;
      --Signal sig_internal_bterm_n         : std_logic;
      Signal sig_premature_slave_term_reg : std_logic;
      --Signal sig_clr_premature_slave_term : std_logic;
      Signal sig_flop_clear               : std_logic;
      Signal sig_reply2ip_inhibit         : std_logic;
 
      Signal sig_cmd_addr_out          : std_logic_vector(0 to 
                                         C_AWIDTH-1);     
      Signal sig_cmd_rnw_out           : std_logic;     
      Signal sig_cmd_be_out            : std_logic_vector(0 to 
                                         (C_NATIVE_DWIDTH/8)-1);
      Signal sig_cmd_size_out          : std_logic_vector(0 to 3); 
      Signal sig_cmd_burst_out         : std_logic;  
      Signal sig_cmd_lock_out          : std_logic;                                 
      Signal sig_make_bus_req          : std_logic;
      Signal sig_new_ip_req            : std_logic;
      Signal sig_clr_ip_req            : std_logic;
      Signal sig_req_error             : std_logic;
      Signal sig_cmd_valid             : std_logic;
      Signal sig_this_cmd_done         : std_logic;
      Signal sig_this_cmd_almost_done  : std_logic;
      Signal sig_flburst_term_internal : std_logic;
      Signal sig_length_is_zero        : std_logic;
      signal sig_length_is_one         : std_logic;
      signal sig_length_is_two         : std_logic;
      Signal sig_single_in_progress    : std_logic;
      Signal sig_flburst_in_progress   : std_logic;
      Signal sig_parent_is_single      : std_logic;
      Signal sig_parent_is_flburst     : std_logic;
      Signal m_wrdbus_i                : std_logic_vector(0 to 
                                         C_NATIVE_DWIDTH-1);
      Signal sig_wrdata_reg            : std_logic_vector(0 to 
                                         C_NATIVE_DWIDTH-1);
      Signal sig_ld_wrdata_reg         : std_logic;
      Signal enable_plbwrack_fifo_rd   : std_logic;
      Signal set_wrack_fifo_rd_en      : std_logic;
      signal sig_fifo_ren              : std_logic;
      signal sig_invalidate_fifo_data  : std_logic;
      signal clr_plbwrack_fifo_rd      : std_logic;
      signal sig_clr_rd_sop            : std_logic;
      signal sig_set_rd_sop            : std_logic;
      signal sig_rd_sop                : std_logic;
      signal sig_clr_rd_eop            : std_logic;
      signal sig_set_rd_eop            : std_logic;
      signal sig_rd_eop                : std_logic;
      signal sig_rdburst_eop_event     : std_logic;
      signal sig_rdsngl_eop_event      : std_logic;
      signal sig_mstwr_burst           : std_logic;
      signal sig_wrll2plb_done_reg     : std_logic;
      signal sig_rdll2plb_done_reg     : std_logic;
      signal sig_calc_new_req          : std_logic;
      signal set_wrerr                 : std_logic;
      signal deassert_wrerr            : std_logic;
      Signal sig_mstwr_error           : std_logic;
      signal sig_wrllink_src_rdy       : std_logic;
      signal sig_set_md_error          : std_logic;
      signal sig_clr_md_error_reg      : std_logic;
      signal sig_md_error_reg          : std_logic;
      signal sig_new_ip_req_done       : std_logic;
      signal sig_rdllink_rem_reg       : std_logic_vector(0 to 
                                         REM_WIDTH-1);
      signal sig_wr_last_dbeat_queued  : std_logic;
      signal sig_clr_last_dbeat_queued : std_logic;
      
      
      Signal sig_cmd_rnw_out_reg       : std_logic;     
      Signal sig_cmd_be_out_reg        : std_logic_vector(0 to 
                                         (C_NATIVE_DWIDTH/8)-1);
      Signal sig_cmd_size_out_reg      : std_logic_vector(0 to 3); 
      signal sig_clr_reply2ip_inhibit  : std_logic;
      
      
        
   -- Component Declarations
     

     

     
     -- component FDRE
     --    port(
     --       Q  :  out   std_logic;
     --       D  :  in    std_logic;
     --       C  :  in    std_logic;
     --       CE :  in    std_logic;
     --       R  :  in    std_logic);
     -- end component;
     
     -- component FDRSE
     --    port(
     --       Q  :  out   std_logic;
     --       D  :  in    std_logic;
     --       C  :  in    std_logic;
     --       CE :  in    std_logic;
     --       R  :  in    std_logic;
     --       S  :  in    std_logic);
     -- end component;

     


begin --(architecture implementation)


  
  
  
  --===================================================================
  -- Master Detected Error Output              
  --===================================================================
     MD_ERROR   <= sig_md_error_reg;  
  
  
  
  --===================================================================
  -- Outputs to PLB Master Request Ports              
  --===================================================================
     
     
     M_request                    <=  m_request_i;
     M_priority                   <=  "01"; -- fixed priority of 1
     M_busLock                    <=  m_buslock_i;
     M_RNW                        <=  sig_cmd_rnw_out_reg;
     M_BE                         <=  sig_cmd_be_out_reg  ;
     M_MSize                      <=  encode_mstr_size(C_NATIVE_DWIDTH); 
     M_size                       <=  sig_cmd_size_out_reg;
     M_type                       <=  "000";  -- memory tranfer
     M_ABus                       <=  sig_cmd_addr_out;
     M_wrBurst                    <=  m_wrburst_i;      
     M_rdBurst                    <=  m_rdburst_i;                 
     M_wrDBus                     <=  m_wrdbus_i;
     
     
                     
                      
  --===================================================================
  -- Output Status Reply To IP Command Interface Ports
  --===================================================================
   
     Bus2IP_Mst_CmdAck          <=  PLB_MAddrAck  and
                                    not(sig_reply2ip_inhibit);
                                     
     Bus2IP_Mst_Cmplt           <=  sm_ip_rd_cmplt or
                                    sm_ip_wr_cmplt;
     
     Bus2IP_Mst_Error           <=  sig_mstrd_error or
                                    sig_mstwr_error; 
     
     Bus2IP_Mst_Rearbitrate     <=  PLB_MRearbitrate  and
                                    not(sig_reply2ip_inhibit);
                                     
     Bus2IP_Mst_Cmd_Timeout     <=  sig_cmd_timeout_reg; 
     


   
  --==================================================================
  -- Write LocalLink Backend Interface output signal assignments 
  --==================================================================
   
     Wr_PLB2LL_Init           <= sm_wr_llink_init    ;           
     Wr_PLB2LL_Activate       <= sm_wr_llink_activate;           
     Wr_PLB2LL_Dst_Dsc        <= sm_wrllink_dsc; -- discontinue not allowed 
                                                 -- except for PLB Timeout
    
     Wr_PLB2LL_Clr_Data_Valid  <= sig_invalidate_fifo_data;
     Wr_PLB2LL_Fifo_Ren        <= sig_fifo_ren;
    
     sig_wrllink_src_rdy       <= Wr_LL2PLB_Rddata_Valid;
      
                                                            
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: REG_WRLL_DONE
    --
    -- Process Description:
    --   Sample and hold the fact that the Write LLink backend 
    -- has asserted it's done signal.
    --
    -------------------------------------------------------------
    REG_WRLL_DONE : process (Bus_Clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst              = '1' or
                sm_wr_llink_init     = '1' or
                sm_wr_llink_activate = '1') then
              sig_wrll2plb_done_reg <= '0';
            elsif (WR_LL2PLB_Done = '1') then
              sig_wrll2plb_done_reg <= '1';
            else
              null;  -- hold current state
            end if;        
         end if;
       end process REG_WRLL_DONE; 
  
 
                                                            
                                                            
                                                            
      
  --==================================================================
  -- Read LocalLink Backend Interface signal assignments 
  --==================================================================
 
     Rd_PLB2LL_Init       <= sm_rd_llink_init    ;
     Rd_PLB2LL_Activate   <= sm_rd_llink_activate;
     Rd_PLB2LL_Src_Dsc    <= sm_rdllink_dsc; -- discontinue not allowed
                                             -- except for PLB Timeout
    
     Rd_PLB2LL_Fifo_Wen    <=  plb_mrddack_reg  ;
     Rd_PLB2LL_Fifo_Sop    <=  sig_rd_sop       ;
     Rd_PLB2LL_Fifo_Eop    <=  sig_rd_eop       ;
     Rd_PLB2LL_Fifo_Data   <=  plb_mrddbus_reg  ;
     
     
     Rd_PLB2LL_Fifo_Rem        <=  sig_rdllink_rem_reg
        when  (sig_parent_is_single = '1')
        else  REM_ALL_ASSERT ;
     
  
     sig_rdllink_dst_rdy      <= not(Rd_LL2PLB_FIFO_Full);
     
     
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: REG_RD_REM
     --
     -- Process Description:
     --     This process samples and holds the RD REM value to be 
     -- used during single data beat read operations.
     --
     -------------------------------------------------------------
     REG_RD_REM : process (Bus_Clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst        = '1' or
                 sig_clr_ip_req = '1') then
               sig_rdllink_rem_reg <= (others => '0');
             elsif (IP2Bus_MstRd_Req  = '1') then
               sig_rdllink_rem_reg  <= sig_cmd_be_out;
             else
               null;  -- hold last state
             end if;        
          end if;
        end process REG_RD_REM; 
     
     
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: REG_RDLL_DONE
     --
     -- Process Description:
     --   Sample and hold the fact that the read LLink backend 
     -- has asserted it's done signal.
     --
     -------------------------------------------------------------
     REG_RDLL_DONE : process (Bus_Clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst              = '1' or
                 sm_rd_llink_init     = '1' or
                 sm_rd_llink_activate = '1') then
               sig_rdll2plb_done_reg <= '0';
             elsif (Rd_LL2PLB_Done = '1') then
               sig_rdll2plb_done_reg <= '1';
             else
               null;  -- hold current state
             end if;        
          end if;
        end process REG_RDLL_DONE; 
   
   
       
       
     
                                                             
 
 
 
     
--=============================================================================
-- Write Data Bus houskeeping 
--  
-- Note:  Write data mirroring has been moved out of this module
--=============================================================================
       
   m_wrdbus_i <= sig_wrdata_reg;       
      
                                 
  -- PLB Write Data register load control
   sig_ld_wrdata_reg   <=  Wr_LL2PLB_Rddata_Valid   and
                           (sm_plb_ld_wrdata_reg    or   
                           (enable_plbwrack_fifo_rd and     
                            PLB_MWrDAck));

  -- FIFO Read control
   set_wrack_fifo_rd_en     <= sm_plb_ld_wrdata_reg;  

   sig_fifo_ren             <=  sig_ld_wrdata_reg;
   
   sig_invalidate_fifo_data <= '0';  
   
   --clr_plbwrack_fifo_rd     <= sig_clr_ip_req; 
   clr_plbwrack_fifo_rd     <= sig_flop_clear; 
        
   sig_mstwr_burst          <= sig_flburst_in_progress and
                               not(sig_cmd_rnw_out);
   
   
   
   ------------------------------------------------------------
   -- Instance: I_FIFO_REN_WRACK_REG 
   --
   -- Description:
   -- This FLOP generates the enable for using the 
   -- PLB WrAck to read the LocalLink Backend. This is only used
   -- during a write burst. Singles have the state machine
   -- read the FIFO.
   ------------------------------------------------------------
   I_FIFO_REN_WRACK_REG :  FDRE                
       port map(                      
          Q  =>  enable_plbwrack_fifo_rd,       
          D  =>  sig_mstwr_burst,
          C  =>  Bus_Clk,           
          CE =>  set_wrack_fifo_rd_en,      
          R  =>  clr_plbwrack_fifo_rd   
          );
         

                                
                   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_WR_DATA
   --
   -- Process Description:
   --      This process implements the write data register which
   -- drives the PLB Write data bus.
   --
   -------------------------------------------------------------
   REG_WR_DATA : process (Bus_Clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst        = '1' or
               sm_ip_wr_cmplt = '1') then

              sig_wrdata_reg    <= (others => '0');
              
           elsif (sig_ld_wrdata_reg = '1') then
           
              sig_wrdata_reg    <= Wr_LL2PLB_Fifo_Data;
              
           else
             
              null;  -- hold state
             
           end if;        
        end if;
      end process REG_WR_DATA; 

   
   
   sig_clr_last_dbeat_queued <=  Bus_Rst or
                                 sm_ip_wr_cmplt or
                                 (sig_wr_last_dbeat_queued and 
                                  PLB_MWrDAck);      
    
    
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_LAST_DBEAT_FLAG
   --
   -- Process Description:
   --
   --
   -------------------------------------------------------------
   REG_LAST_DBEAT_FLAG : process (Bus_Clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (sig_clr_last_dbeat_queued = '1') then
             sig_wr_last_dbeat_queued <= '0';
           elsif (sig_ld_wrdata_reg = '1') then
             sig_wr_last_dbeat_queued <= Wr_LL2PLB_Fifo_Eof;
           else
             null; 
           end if;        
        end if;
      end process REG_LAST_DBEAT_FLAG; 
    
  --=========================================================================================
     
   
   
  
    
     
                       
  --===================================================================
  -- General flop clear generation Logic
  --===================================================================
    
     
    sig_flop_clear   <=  Bus_Rst or
                         sm_ip_rd_cmplt or
                         sm_ip_wr_cmplt;
   
   
     
    
  --===================================================================
  -- PLB Request signal generation Logic
  --===================================================================
    
    sig_clr_request_flop    <= Bus_Rst      or 
                               PLB_MAddrAck or
                               PLB_MTimeout;
    
    sig_set_request_flop    <= sm_post_rdreq_ns or
                               sm_post_wrreq; -- write delayed 1 clock
 
    
    I_REQUEST_REG :  FDRE                
        port map(                      
           Q  =>  m_request_i,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_set_request_flop,     
           R  =>  sig_clr_request_flop            
           );
        
    
    
     
  --===================================================================
  -- Command Qualifier Register Logic
  --===================================================================
    
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_CMD_QUAL
  --
  -- Process Description:
  -- This process registers output command qualifiers prior
  -- to PLB interface.
  --
  -------------------------------------------------------------
  REG_CMD_QUAL : process (Bus_Clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst          = '1' or
              sig_calc_new_req = '0') then
          
            sig_cmd_rnw_out_reg   <= '0';
            sig_cmd_be_out_reg    <= (others => '0');
            sig_cmd_size_out_reg  <= (others => '0');

          elsif (sig_set_request_flop = '1') then
          
            sig_cmd_rnw_out_reg   <= sig_cmd_rnw_out;
            sig_cmd_be_out_reg    <= sig_cmd_be_out;
            sig_cmd_size_out_reg  <= sig_cmd_size_out;

          else
            null; -- hold current state
          end if; 
       end if;       
     end process REG_CMD_QUAL; 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  --===================================================================
  -- RdBurst signal generation Logic
  --===================================================================
    
    sig_slave_rdterm_event   <=  PLB_MRdBTerm;
                                    
    sig_length_rdterm_event  <=  sig_flburst_term_internal and
                                 PLB_MRdDAck;
    
    clear_rdburst            <= Bus_Rst                 or 
                                sig_slave_rdterm_event  or
                                sig_length_rdterm_event or
                                PLB_MTimeout;
           
    
    
    sig_rdburst_flop_en      <= PLB_MAddrAck and  
                                sig_flburst_in_progress and
                                sig_cmd_rnw_out;
 
    
    I_RDBURST_REG :  FDRE                
        port map(                      
           Q  =>  m_rdburst_i,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_rdburst_flop_en,     
           R  =>  clear_rdburst            
           );
        
    
    
     
  --===================================================================
  -- WrBurst signal generation Logic
  --===================================================================
    
    sig_slave_wrterm_event   <=  PLB_MWrBTerm;
                                    
    sig_length_wrterm_event  <=  sig_flburst_term_internal and
                                 PLB_MWrDAck;
    
    clear_wrburst            <= Bus_Rst                 or 
                                sig_slave_wrterm_event  or
                                sig_length_wrterm_event or
                                PLB_MTimeout;
           
    
    
    sig_wrburst_flop_en      <= sig_flburst_in_progress and
                                not(sig_cmd_rnw_out)    and
                                sig_set_request_flop;
 
    
    I_WRBURST_REG :  FDRE                
        port map(                      
           Q  =>  m_wrburst_i,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_wrburst_flop_en,     
           R  =>  clear_wrburst            
           );
        
    
  
  
    
  --===================================================================
  -- PLB Bus Lock signal generation Logic
  --===================================================================
    
    -- Bus Lock must be asserted in alignment with a Master Request assertion
    sig_set_buslock_flop    <= (sm_post_rdreq_ns or
                                sm_post_wrreq) and  -- write delayed 1 clock
                                sig_cmd_lock_out;   -- Lock requested
 
    -- Bus Lock is deasserted when a command is indicated as commplete
    -- and the User IP is no Longer asserting a Bus Lock request.
    sig_clr_buslock_flop    <= Bus_Rst      or 
                               ((sm_ip_rd_cmplt  or
                                 sm_ip_wr_cmplt) and
                                not(sig_cmd_lock_out));
    
    I_BUSLOCK_REG :  FDRE                
        port map(                      
           Q  =>  m_buslock_i,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_set_buslock_flop,     
           R  =>  sig_clr_buslock_flop            
           );
        
    
    
     
     
    
    
  --===================================================================
  -- Premature PLB Slave Burst Terminate detection Logic
  --===================================================================
    
   -- Disabled  
   sig_premature_slave_term_reg <= '0'; 
    
    
    -- sig_clr_premature_slave_term  <=  sig_flop_clear;                     
    -- 
    -- sig_internal_bterm_n  <= not(sig_flburst_term_internal);
    -- 
    --     
    -- I_PREM_TERM_REG :  FDRE                
    --     port map(                      
    --        Q  =>  sig_premature_slave_term_reg,         
    --        D  =>  sig_internal_bterm_n,     
    --        C  =>  Bus_Clk,                     
    --        CE =>  PLB_MRdBTerm,                 
    --        R  =>  sig_clr_premature_slave_term    
    --        );
        
    
    
  --===================================================================
  -- Read Error detection Logic
  -- sig_mstrd_error is set by an error received from the PLB Slave
  -- during a data transfer acknowledge or a state machine set.
  --===================================================================
    
    set_rderr      <= (plb_mrddack_reg and 
                       plb_mrderr_reg) or 
                       sm_set_rd_err_ns;     
    
    
    deassert_rderr <= sig_flop_clear;
        
        
    I_RDERR_REG :  FDRE                
        port map(                      
           Q  =>  sig_mstrd_error,   
           D  =>  '1',               
           C  =>  Bus_Clk,           
           CE =>  set_rderr,         
           R  =>  deassert_rderr     
           );
   
    
 
 
  --===================================================================
  -- Write Error detection Logic
  -- sig_mstwr_error is set by an error received from the PLB Slave
  -- during a data transfer acknowledge or a state machine set.
  --===================================================================
    
    set_wrerr      <= (plb_mwrdack_reg and 
                       plb_mwrerr_reg) or 
                       sm_set_wr_err_ns;     
    
    
    deassert_wrerr <= sig_flop_clear;
        
        
    I_WRERR_REG :  FDRE                
        port map(                      
           Q  =>  sig_mstwr_error,   
           D  =>  '1',               
           C  =>  Bus_Clk,           
           CE =>  set_wrerr,         
           R  =>  deassert_wrerr     
           );
   
    
 
 
   
  --===================================================================
  -- Cmd Reply Inhibit Logic
  -- Reply Inhibit is set by the receipt of the CmdAck from the first
  -- PLB request and cleared when the parent commad has completed all 
  -- data transfers.
  --===================================================================
    
    sig_clr_reply2ip_inhibit <= sig_flop_clear;   
 
                                  
    I_CMD_REPLY_INHIB_REG :  FDRE                
        port map(                      
           Q  =>  sig_reply2ip_inhibit,       
           D  =>  '1',                       
           C  =>  Bus_Clk,                   
           CE =>  PLB_MAddrAck,         
           --R  =>  sig_clr_ip_req    
           R  =>  sig_clr_reply2ip_inhibit    
           );
        

  
  

 
 
  --=================================================================
  -- Command Timeout Logic
  -- This Flop Samples and Holds the assertion of the PLB timeout
  -- reply signal for the IP Cmd Interface status.
  --=================================================================
  
    sig_clr_cmd_timeout_reg  <=  sig_flop_clear;
     
 
    I_CMD_TIMEOUT_REG :  FDRE                
        port map(                      
           Q  =>  sig_cmd_timeout_reg,       
           D  =>  '1',                       
           C  =>  Bus_Clk,                   
           CE =>  PLB_MTimeout,         
           R  =>  sig_clr_cmd_timeout_reg    
           );
  
  
  
  
        
  --=================================================================
  -- Master Detected Error Logic
  -- This Flop Samples and Holds the assertion of the PLB timeout
  -- reply signal or the PLB_MRdErr or PLB_MWrErr .
  --=================================================================
  
    sig_set_md_error      <=  sig_cmd_timeout_reg or
                              set_rderr           or
                              set_wrerr           or
                              sig_premature_slave_term_reg;
                              
                              
    -- sig_clr_md_error_reg  <=  Bus_Rst or
    --                           IP2Bus_Mst_Reset;
    
    sig_clr_md_error_reg  <=  Bus_Rst;
 
    I_MD_ERROR_REG :  FDRE                
        port map(                      
           Q  =>  sig_md_error_reg,       
           D  =>  '1',                       
           C  =>  Bus_Clk,                   
           CE =>  sig_set_md_error,         
           R  =>  sig_clr_md_error_reg    
           );
        
  
  
  --===================================================================
  -- Read LLink Backend SOP Generation 
  --===================================================================
    
    sig_clr_rd_sop    <= Bus_Rst         or 
                         plb_mrddack_reg or
                         sm_ip_wr_cmplt  or
                         (Rd_LL2PLB_Done and
                          sm_rdllink_dsc);
    
    sig_set_rd_sop    <= sm_post_rdreq and
                         not(sig_reply2ip_inhibit);
 
    
    I_RDSOP_REG :  FDRE                
        port map(                      
           Q  =>  sig_rd_sop,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_set_rd_sop,     
           R  =>  sig_clr_rd_sop            
           );
        
    
    
  --===================================================================
  -- Read LLink Backend EOP Generation 
  --===================================================================
    
    
    sig_rdburst_eop_event <=  plb_mrddack_reg and
                              sig_length_is_two;
    
    sig_rdsngl_eop_event  <=  sm_post_rdreq and
                              (sig_parent_is_single or
                               sig_length_is_one);
    
    
    sig_clr_rd_eop        <=  Bus_Rst         or 
                              sm_ip_rd_cmplt  or
                             (plb_mrddack_reg and
                              sig_this_cmd_done);
    
    sig_set_rd_eop        <= sig_rdburst_eop_event or
                             sig_rdsngl_eop_event ;
 
    
    I_RDEOP_REG :  FDRE                
        port map(                      
           Q  =>  sig_rd_eop,             
           D  =>  '1',                    
           C  =>  Bus_Clk,                 
           CE =>  sig_set_rd_eop,     
           R  =>  sig_clr_rd_eop            
           );
        
    
    
     
   
   
     
   
   
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_PLB_INPUTS
   --
   -- Process Description:
   --   This process registers the PLB Bus inputs associated with
   -- reads.
   --
   -------------------------------------------------------------
   REG_PLB_INPUTS : process (Bus_Clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst = '1') then
             
              plb_mrderr_reg           <= '0'            ;
              plb_mrddack_reg          <= '0'            ;
              plb_mrddbus_reg          <= (others => '0');
              plb_mwrerr_reg           <= '0'            ;
              plb_mwrdack_reg          <= '0'            ;
                         
           else
             
              plb_mrderr_reg           <= PLB_MRdErr   ;
              plb_mrddack_reg          <= PLB_MRdDAck  ;
              plb_mrddbus_reg          <= PLB_MRdDBus  ;
              plb_mwrerr_reg           <= PLB_MWrErr   ;
              plb_mwrdack_reg          <= PLB_MWrDAck  ;
                          
           end if;        
        end if;
      end process REG_PLB_INPUTS; 
    
    
  
     
      
      
      
   
   

     
         
         
         
         
         
  --===================================================================
  -- Read Controller State Machine
  --===================================================================

  
      -------------------------------------------------------------
      -- Combinational Process
      --
      -- Label: RD_CONTROL_SM_COMB
      --
      -- Process Description:
      --      This process implements the combinational portion of the
      -- Read Control State Machine. 
      --
      -------------------------------------------------------------
      RD_CONTROL_SM_COMB : process (Bus_Rst,
                                    sm_rdcntl_state,
                                    PLB_MAddrAck,
                                    IP2Bus_MstRd_Req,
                                    sig_rdllink_dst_rdy,
                                    sig_cmd_valid,
                                    sig_this_cmd_done,
                                    sig_data_xfer_done,
                                    sig_rdll2plb_done_reg,
                                    sig_cmd_timeout_reg
                                    )
         begin
      
           
           if (Bus_Rst = '1') then
           
            -- Reset states
               sm_rdcntl_state_ns        <= RD_IDLE;
               sm_rd_get_new_cmd_ns      <= '0';
               sm_post_rdreq_ns          <= '0';    
               sm_set_rd_err_ns          <= '0';    
               sm_rdllink_dsc_ns         <= '0';    
               sm_ip_rd_cmplt_ns         <= '0';    
               sm_rd_llink_init_ns       <= '0';
               sm_rd_llink_activate_ns   <= '0';
  
              
           else
           
            -- Default states
               sm_rdcntl_state_ns        <= RD_IDLE;
               sm_rd_get_new_cmd_ns      <= '0';
               sm_post_rdreq_ns          <= '0';    
               sm_set_rd_err_ns          <= '0';    
               sm_rdllink_dsc_ns         <= '0';    
               sm_ip_rd_cmplt_ns         <= '0';    
               sm_rd_llink_init_ns       <= '0';
               sm_rd_llink_activate_ns   <= '0';
           
              
              case sm_rdcntl_state is
      
                -------------------------------
                When RD_IDLE     =>
                -------------------------------
                
                  if (IP2Bus_MstRd_Req  = '1') then  
                  
                     sm_rdcntl_state_ns        <= RD_CMD_CALC;
                     sm_rd_get_new_cmd_ns      <= '1';
                     sm_rd_llink_activate_ns   <= '1';
                     
                  else 
                  
                     sm_rdcntl_state_ns   <= RD_IDLE;
                     
                  end if;
                   
                
                
                -------------------------------
                When RD_CMD_CALC =>
                -------------------------------
               
                  if (sig_cmd_valid           = '1' and 
                      sig_rdllink_dst_rdy     = '1' ) then
                     
                     sm_rdcntl_state_ns      <= RD_WAIT_ADDRACK;
                     sm_post_rdreq_ns        <= '1';
                  
                  else
      
                     sm_rdcntl_state_ns      <= RD_CMD_CALC; 
                     sm_rd_get_new_cmd_ns   <= '1';
                      
                  End if;
                   
                
                
                -------------------------------
                When RD_WAIT_ADDRACK =>
                -------------------------------
                   
                   if (PLB_MAddrAck = '1') then
                   
                     sm_rdcntl_state_ns      <= RD_DPHASE; 
                   
                   elsif (sig_cmd_timeout_reg = '1') then
                   
                     sm_rdcntl_state_ns      <= RD_LLINK_DISCONTINUE;
                     sm_rdllink_dsc_ns       <= '1';
                     sm_set_rd_err_ns        <= '1';
                   
                   else
                   
                     sm_rdcntl_state_ns      <= RD_WAIT_ADDRACK;
                   
                   end if;
                   
                
                
                -------------------------------
                When RD_DPHASE =>
                -------------------------------
                 
                  if (sig_this_cmd_done = '1') Then
                      -- PLB data phase has completed   
     
                     sm_rdcntl_state_ns    <= RD_CHK_DONE;
                     
                  else
                  
                     sm_rdcntl_state_ns    <= RD_DPHASE;
                     
                  end if;
                   
                
                
                -------------------------------
                When RD_CHK_DONE =>
                -------------------------------
                
                  if (sig_data_xfer_done    = '1'and     
                      sig_rdll2plb_done_reg = '1') Then
                        -- IP Command has completed and   
                        -- LocalLink has signaled done 
     
                     sm_rdcntl_state_ns    <= RD_IDLE;
                     sm_ip_rd_cmplt_ns     <= '1';
                     
                  Elsif (sig_data_xfer_done    = '1' and    
                         sig_rdll2plb_done_reg = '0') Then  
                        -- IP Command has completed
                        -- but LocalLink still active       
                        -- so wait
                        
                     sm_rdcntl_state_ns    <= RD_CHK_DONE; 
                  
                  else  -- spawn a new command
                  
                     sm_rdcntl_state_ns    <= RD_CMD_CALC; 
                     sm_rd_get_new_cmd_ns  <= '1';
                     
                  end if;
                   
                
                
                -------------------------------
                When RD_LLINK_DISCONTINUE =>
                -------------------------------
                  
                  if (sig_rdll2plb_done_reg = '1') then
                  
                     sm_rdcntl_state_ns    <= RD_WAIT_ON_TMOUT_CLR;
                     sm_ip_rd_cmplt_ns     <= '1';
                     
                      
                  else 
                     
                     sm_rdcntl_state_ns    <= RD_LLINK_DISCONTINUE;
                     sm_rdllink_dsc_ns       <= '1';
                  
                  end if;
                   
                
                
                -------------------------------
                When RD_WAIT_ON_TMOUT_CLR =>
                -------------------------------
                  
                  if (sig_cmd_timeout_reg = '1') then
                  
                     sm_rdcntl_state_ns    <= RD_WAIT_ON_TMOUT_CLR;
                      
                  else 
                     
                     sm_rdcntl_state_ns    <= RD_IDLE;
                  
                  end if;
                   
                
                
                -------------------------------
                When others  =>
                -------------------------------
               
                  sm_rdcntl_state_ns     <= RD_IDLE;
                    
              end case;
             
           
           end if;
      
         end process RD_CONTROL_SM_COMB; 
      
      
      
                  
                  
  
     -------------------------------------------------------------    
     -- Synchronous Process with Sync Reset                           
     --                                                               
     -- Label: RD_CONTROL_SM_SYNC                                   
     --                                                               
     -- Process Description:                                          
     --   This process implements the synchronous portion of the      
     -- Read Control State Machine.                                
     --                                                               
     -------------------------------------------------------------    
     RD_CONTROL_SM_SYNC : process (Bus_Clk)                         
       begin                                                         
         if (Bus_Clk'event and Bus_Clk = '1') then                   
           if (Bus_Rst = '1') then                                  
                                                                    
             sm_rdcntl_state         <= RD_IDLE;
             sm_rd_get_new_cmd       <= '0';
             sm_post_rdreq           <= '0';    
             sm_set_rd_err           <= '0';    
             sm_rdllink_dsc          <= '0';    
             sm_ip_rd_cmplt          <= '0';    
             sm_rd_llink_init        <= '0';
             sm_rd_llink_activate    <= '0';
                
           else                                                     
                                                                   
             sm_rdcntl_state        <= sm_rdcntl_state_ns     ;
             sm_rd_get_new_cmd      <= sm_rd_get_new_cmd_ns   ;
             sm_post_rdreq          <= sm_post_rdreq_ns       ;  
             sm_set_rd_err          <= sm_set_rd_err_ns       ;  
             sm_rdllink_dsc         <= sm_rdllink_dsc_ns      ;  
             sm_ip_rd_cmplt         <= sm_ip_rd_cmplt_ns      ;  
             sm_rd_llink_init       <= sm_rd_llink_init_ns    ;
             sm_rd_llink_activate   <= sm_rd_llink_activate_ns;
                
              
           end if;                                                  
         end if;                                                     
       end process RD_CONTROL_SM_SYNC;                             
   
   
                        
                        
                        
                        
                        
                        
                        
  --===================================================================
  -- Write Controller State Machine
  --===================================================================

  
      -------------------------------------------------------------
      -- Combinational Process
      --
      -- Label: WR_CONTROL_SM_COMB
      --
      -- Process Description:
      --      This process implements the combinational portion of the
      -- Write Control State Machine. 
      --
      -------------------------------------------------------------
      WR_CONTROL_SM_COMB : process (Bus_Rst,
                                    sm_wrcntl_state,
                                    PLB_MAddrAck,
                                    IP2Bus_MstWr_Req,
                                    sig_wrllink_src_rdy,
                                    sig_cmd_valid,
                                    sig_this_cmd_done,
                                    sig_data_xfer_done,
                                    sig_wrll2plb_done_reg,
                                    sig_reply2ip_inhibit,
                                    sig_wr_last_dbeat_queued,
                                    sig_cmd_timeout_reg
                                    )
         begin
      
           
           if (Bus_Rst = '1') then
           
            -- Reset states
               sm_wrcntl_state_ns        <= WR_IDLE;
               sm_wr_get_new_cmd_ns      <= '0';    
               sm_post_wrreq_ns          <= '0';    
               sm_set_wr_err_ns          <= '0';    
               sm_wrllink_dsc_ns         <= '0';    
               sm_ip_wr_cmplt_ns         <= '0';    
               sm_wr_llink_init_ns       <= '0';    
               sm_wr_llink_activate_ns   <= '0';    
               sm_plb_ld_wrdata_reg_ns   <= '0';
              
           else
           
            -- Default states
               sm_wrcntl_state_ns        <= WR_IDLE;
               sm_wr_get_new_cmd_ns      <= '0';    
               sm_post_wrreq_ns          <= '0';    
               sm_set_wr_err_ns          <= '0';    
               sm_wrllink_dsc_ns         <= '0';    
               sm_ip_wr_cmplt_ns         <= '0';    
               sm_wr_llink_init_ns       <= '0';    
               sm_wr_llink_activate_ns   <= '0';    
               sm_plb_ld_wrdata_reg_ns   <= '0';
           
              
              case sm_wrcntl_state is
      
                -------------------------------
                When WR_IDLE          =>
                -------------------------------
                
                  if (IP2Bus_MstWr_Req     = '1') then  
                                                        
                     sm_wrcntl_state_ns        <= WR_CMD_CALC;
                     sm_wr_get_new_cmd_ns      <= '1';
                     sm_wr_llink_activate_ns   <= '1';
                     
                  else 
                  
                     sm_wrcntl_state_ns   <= WR_IDLE;
                     
                  end if;
                   
                
                
                -------------------------------
                When WR_CMD_CALC =>
                -------------------------------
                
                  if (sig_cmd_valid           = '1' and 
                      sig_wrllink_src_rdy     = '1' ) then
                     
                     sm_wrcntl_state_ns       <= WR_WAIT_ADDRACK;
                     sm_post_wrreq_ns         <= '1';
                     sm_plb_ld_wrdata_reg_ns  <= not(sig_reply2ip_inhibit);
                     
                  Elsif (sig_cmd_valid     = '1' and
                         sig_wr_last_dbeat_queued = '1') Then
                  
                     sm_wrcntl_state_ns       <= WR_WAIT_ADDRACK;
                     sm_post_wrreq_ns         <= '1';
                  
                  else
      
                     sm_wrcntl_state_ns      <= WR_CMD_CALC; 
                     sm_wr_get_new_cmd_ns   <= '1';
                      
                  End if;
                   
                
                
                -------------------------------
                When WR_WAIT_ADDRACK =>
                -------------------------------
                   
                   if (PLB_MAddrAck = '1') then
                   
                     sm_wrcntl_state_ns      <= WR_DPHASE; 
                   
                   elsif (sig_cmd_timeout_reg = '1') then
                   
                     sm_wrcntl_state_ns      <= WR_LLINK_DISCONTINUE;
                     sm_wrllink_dsc_ns       <= '1';
                     sm_set_wr_err_ns        <= '1';
                   
                   else
                   
                     sm_wrcntl_state_ns      <= WR_WAIT_ADDRACK;
                   
                   end if;
                   
                
                
                -------------------------------
                When WR_DPHASE =>
                -------------------------------
                 
                  if (sig_this_cmd_done = '1') Then   
                      -- PLB data phase has completed
     
                     sm_wrcntl_state_ns    <= WR_CHK_DONE;
                     
                  else
                  
                     sm_wrcntl_state_ns    <= WR_DPHASE;
                     
                  end if;
                   
                
                
                -------------------------------
                When WR_CHK_DONE =>
                -------------------------------
                
                  if (sig_data_xfer_done    = '1' and    
                      sig_wrll2plb_done_reg = '1') Then
                      -- IP Command has completed and 
                      -- LocalLink has completed   
     
                     sm_wrcntl_state_ns    <= WR_IDLE;
                     sm_ip_wr_cmplt_ns     <= '1';
                     
                  elsif (sig_data_xfer_done    = '1' and    
                         sig_wrll2plb_done_reg = '0') Then 
                       -- IP Command has completed
                       -- but LocalLink still active        
     
                     sm_wrcntl_state_ns    <= WR_CHK_DONE;
                  
                  else  -- spawn a new command
                  
                     sm_wrcntl_state_ns    <= WR_CMD_CALC; 
                     sm_wr_get_new_cmd_ns  <= '1';
                     
                  end if;
                   
                
                
                -------------------------------
                When WR_LLINK_DISCONTINUE =>
                -------------------------------
                  
                   if (sig_wrll2plb_done_reg = '1') then
                   
                      sm_wrcntl_state_ns    <= WR_WAIT_ON_TMOUT_CLR;
                      sm_ip_wr_cmplt_ns     <= '1';
                      
                       
                   else 
                      
                      sm_wrcntl_state_ns    <= WR_LLINK_DISCONTINUE;
                      sm_wrllink_dsc_ns       <= '1';
                   
                   end if;
                   
                
                
                -------------------------------
                When WR_WAIT_ON_TMOUT_CLR =>
                -------------------------------
                  
                   if (sig_cmd_timeout_reg = '1') then
                   
                      sm_wrcntl_state_ns    <= WR_WAIT_ON_TMOUT_CLR;
                       
                   else 
                      
                      sm_wrcntl_state_ns    <= WR_IDLE;
                   
                   end if;
                   
                
                
                -------------------------------
                When others  =>
                -------------------------------
               
                    sm_wrcntl_state_ns     <= WR_IDLE;
                     
               end case;
             
           
           end if;
      
         end process WR_CONTROL_SM_COMB; 
      
      
      
                  
                  
  
     -------------------------------------------------------------    
     -- Synchronous Process with Sync Reset                           
     --                                                               
     -- Label: WR_CONTROL_SM_SYNC                                   
     --                                                               
     -- Process Description:                                          
     --   This process implements the synchronous portion of the      
     -- Write Control State Machine.                                
     --                                                               
     -------------------------------------------------------------    
     WR_CONTROL_SM_SYNC : process (Bus_Clk)                         
        begin                                                         
          if (Bus_Clk'event and Bus_Clk = '1') then                   
             if (Bus_Rst = '1') then                                  
                                                                      
               sm_wrcntl_state         <= WR_IDLE; 
               sm_wr_get_new_cmd       <= '0';      
               sm_post_wrreq           <= '0';     
               sm_set_wr_err           <= '0';     
               sm_wrllink_dsc          <= '0';     
               sm_ip_wr_cmplt          <= '0';     
               sm_wr_llink_init        <= '0';     
               sm_wr_llink_activate    <= '0';     
               sm_plb_ld_wrdata_reg    <= '0';     

             else                                                     
                                                                     
               sm_wrcntl_state         <= sm_wrcntl_state_ns;
               sm_wr_get_new_cmd       <= sm_wr_get_new_cmd_ns;
               sm_post_wrreq           <= sm_post_wrreq_ns;  
               sm_set_wr_err           <= sm_set_wr_err_ns;  
               sm_wrllink_dsc          <= sm_wrllink_dsc_ns;  
               sm_ip_wr_cmplt          <= sm_ip_wr_cmplt_ns;  
               sm_wr_llink_init        <= sm_wr_llink_init_ns;
               sm_wr_llink_activate    <= sm_wr_llink_activate_ns;
               sm_plb_ld_wrdata_reg    <= sm_plb_ld_wrdata_reg_ns;  
                
             end if;                                                  
          end if;                                                     
        end process WR_CONTROL_SM_SYNC;                             
   
   
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
 --===========================================================================                       
 -- Command Calculator Logic
 --
 -- This logic is shared between the Read and Write State Machines.
 --===========================================================================                       
     
     sig_make_bus_req <= sm_rd_get_new_cmd_ns  or
                         sm_wr_get_new_cmd_ns;                 
                       
     sig_clr_ip_req   <=  sm_ip_rd_cmplt or
                          sm_ip_wr_cmplt;                    
                        
                        
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: GEN_NEW_CMD_CALC
     --
     -- Process Description:
     --     This process implementsa flop that generates the
     -- request to make a new command calculation. The calc 
     -- request is held until the associated PLB command is
     -- AddrAcked.
     --
     -------------------------------------------------------------
     GEN_NEW_CMD_CALC : process (Bus_Clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst      = '1' or
                 PLB_MAddrAck = '1' or
                 PLB_MTimeout = '1') then
               
               sig_calc_new_req <= '0';
                     
             elsif (sig_make_bus_req = '1') then
               
               sig_calc_new_req <= '1';
               
             else
               null; -- hold last state
             end if;        
          end if;
        end process GEN_NEW_CMD_CALC; 
                                                                
      
      
                        
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: GEN_NEW_IP_REQ
     --
     -- Process Description:
     --     This process implementsa flop that generates a
     -- qualifier that indicates that the inital request calculation
     -- for an IP Command. This qualifier is not set for any
     -- child calculation requests related to the parent IP 
     -- command. This flop is set for 1 PLB Clock.
     --
     -------------------------------------------------------------
     GEN_NEW_IP_REQ : process (Bus_Clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst              = '1' or
                 sig_clr_ip_req       = '1' or
                 sig_reply2ip_inhibit = '1') then
               
               sig_new_ip_req      <= '0';
               sig_new_ip_req_done <= '0';
                     
             Elsif (sig_new_ip_req_done = '1') Then
               
               sig_new_ip_req      <= '0';
               sig_new_ip_req_done <= '1';
             
             elsif (sig_make_bus_req    = '1' and
                    sig_new_ip_req_done = '0') then
               
               sig_new_ip_req      <= '1';
               sig_new_ip_req_done <= '1';
               
             else
               null; -- hold last state
             end if;        
          end if;
        end process GEN_NEW_IP_REQ; 
                                                                
                        
                        
                        
                        
                        
         
     ------------------------------------------------------------
     -- Instance: I_REQ_CALCULATOR 
     --
     -- Description:
     --     This HDL instantiates the request calculator function.    
     --
     ------------------------------------------------------------
      I_REQ_CALCULATOR : entity plbv46_master_burst_v1_00_a.rd_wr_calc_burst
      generic map (
        C_LENGTH_WIDTH            =>  C_LENGTH_WIDTH    ,  
        C_MAX_FBURST_DBCNT        =>  MAX_FLBURST_DB_CNT,  
        C_PLB_AWIDTH              =>  C_AWIDTH          ,  
        C_NATIVE_DWIDTH           =>  C_NATIVE_DWIDTH      
        )
      port map (
   
       -- System Inputs
       -- (synchronous to Bus_clk)
        Bus_Clk                   =>  Bus_Clk   ,  
        Bus_Rst                   =>  Bus_Rst   ,  
     
      -- Control Inputs
        Make_Bus_Req              =>  sig_calc_new_req,  
        New_IP_Req                =>  sig_new_ip_req  ,  
        Clr_IP_Req                =>  sig_clr_ip_req  ,  
        WrAck                     =>  PLB_MWrDAck     ,  
        RdAck                     =>  PLB_MRdDAck     ,  
                                                                                                                          
      -- Command Generation Status (outputs)  
        Cmd_Valid                 =>  sig_cmd_valid             ,                                                                          
        Cmd_Error                 =>  sig_req_error             ,                                                                          
        IP_Req_Done               =>  sig_data_xfer_done        ,                                                                          
        Xfer_Done                 =>  sig_this_cmd_done         ,                                                                          
        Xfer_Almost_Done          =>  sig_this_cmd_almost_done  ,                                                                          
        FLBurst_term              =>  sig_flburst_term_internal ,                                                                          
        Length_is_Zero            =>  sig_length_is_zero        ,                                                                          
        Length_is_One             =>  sig_length_is_one         ,  
        Length_is_Two             =>  sig_length_is_two         ,  
        Single_In_Prog            =>  sig_single_in_progress    ,  
        FLBurst_In_Prog           =>  sig_flburst_in_progress   ,  
        Parent_Is_Single          =>  sig_parent_is_single      ,  
        Parent_Is_FLBurst         =>  sig_parent_is_flburst     ,  
        
      
      -- IP Request Qualifiers (inputs)
        IP2Mst_Rd                 =>  IP2Bus_MstRd_Req  ,  
        IP2Mst_Wr                 =>  IP2Bus_MstWr_Req  ,  
        IP2Mst_Addr               =>  IP2Bus_Mst_Addr   ,  
        IP2Mst_Length             =>  IP2Bus_Mst_Length ,  
        IP2Mst_BE                 =>  IP2Bus_Mst_BE     ,       
        IP2Mst_Type               =>  IP2Bus_Mst_Type   ,  
        IP2Mst_Lock               =>  IP2Bus_Mst_Lock   ,  
                                  
      -- PLB Request qualifiers (outputs)                         
        Mst_RNW_Out               =>  sig_cmd_rnw_out   ,  
        Mst_Addr_Out              =>  sig_cmd_addr_out  ,  
        Mst_BE_Out                =>  sig_cmd_be_out    ,  
        Mst_Size_Out              =>  sig_cmd_size_out  ,  
        Mst_Burst_Out             =>  sig_cmd_burst_out ,  
        Mst_Lock_Out              =>  sig_cmd_lock_out     
                               
        );
    


   
   
end implementation;
