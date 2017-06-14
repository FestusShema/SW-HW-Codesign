-------------------------------------------------------------------------------
-- $Id: llink_wr_backend_no_fifo.vhd,v 1.2 2006/10/23 23:03:08 dougt Exp $
-------------------------------------------------------------------------------
-- llink_wr_backend_no_fifo.vhd
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
-- Filename:        llink_wr_backend_no_fifo.vhd
--
-- Description:     
--   This LocalLink interface module is designed for the PLB Master LLink write                 
-- side. It is taylored for application in the PLB TEMAC application and has
-- features and functions stripped out that are deemed too general purpose.                 
-- The primary element removed is the Write FIFO. As such, related features 
-- that the fifo afforded are removed such as unaligned start and end packet 
-- transfer detection. Unaligned transfer cases must be covered with the 
-- appropriate Write Command Starting Address and the Command Length Qualifier.               
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              llink_wr_backend_no_fifo.vhd
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $$
-- Date:            $$
--
-- History:
--   DET   11/01/2005       Initial Version
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
use IEEE.std_logic_unsigned.all;  -- used for CONV_INTEGER


library unisim; -- Required for Xilinx primitives
use unisim.vcomponents.all;  


-------------------------------------------------------------------------------

entity llink_wr_backend_no_fifo is
  generic (
     C_PLB_DWIDTH             : Integer  := 64;
     C_SG_IS_PRESENT          : Integer  range 0 to 1 := 1; -- 0 = no S/G, 1 = S/G is present
     C_WR_HDR_SIZE_BYTES      : Integer  := 16; -- 0 = no hdr else the hdr size (bytes)
     C_WR_FTR_SIZE_BYTES      : Integer  := 8 ; -- 0 = no ftr else the ftr size (bytes)
     C_REM_WIDTH              : Integer  range 1 to 16 := 8; -- 3 or C_PLB_DWIDTH/8
     C_REM_POLARITY           : Integer  := 0; -- 0 = acitve low, 1 = active high
     C_DISREGARD_OCCUPANCY    : boolean  := True; -- False = use occupancy, True = ignore occupancy
     C_WRFIFO_OCCUPANCY_WIDTH : Integer  := 1;
     C_FAMILY                 : String   := "virtex4" 
    );
  port (

     -- System Inputs
     -- (syncronous to Bus_clk)
        Bus_Clk                   : In  std_logic;
        Bus_Rst                   : In  std_logic;
        Bus_Freeze                : In  std_logic;
     
     -- LL FIFO Read I/O with Write Master
     -- (syncronous to Bus_clk)
        PLB2LL_Clr_Data_Valid     : In  std_logic; 
        PLB2LL_FIFO_REN           : In  std_logic;
        LL2PLB_FIFO_SOF           : Out std_logic;
        LL2PLB_FIFO_EOF           : Out std_logic;
        LL2PLB_FIFO_SOP           : Out std_logic;
        LL2PLB_FIFO_EOP           : Out std_logic;
        LL2PLB_FIFO_REM           : Out std_logic_vector(0 to C_REM_WIDTH-1);
        LL2PLB_FIFO_Data          : Out std_logic_vector(0 to C_PLB_DWIDTH- 1);
        LL2PLB_RdData_Valid       : Out std_logic;
 
     -- LL FIFO Read I/O with Scatter Gather Service
     -- (syncronous to Bus_clk)
        SG2LL_FIFO_REN            : in  std_logic;
     
     -- LL FIFO Read Status
     -- (syncronous to Bus_clk)
        LL2PLB_FIFO_Almost_Empty  : Out std_logic;
        LL2PLB_FIFO_Empty         : Out std_logic;
        LL2PLB_WRFIFO_Occupancy   : out std_logic_vector(0 to C_WRFIFO_OCCUPANCY_WIDTH-1);
        
     -- PLB Write Controller inputs
     -- (syncronous to Bus_clk)
        PLB2LL_Init               : In  std_logic;
        PLB2LL_Activate           : In  std_logic;
        PLB2LL_Dst_Dsc            : In  std_logic;
        PLB2LL_Rdy_For_Ftr        : In  std_logic; -- Used during MEWS condition to request
                                                   -- final data value load into the FIFO 
        PLB2LL_HdrFtr_Sel         : in  std_logic; -- 1=Header or Footer, 0=Payload
     
     -- Status Outputs to PLB Write Controller 
     -- (syncronous to Bus_clk)
        LL2PLB_Rdy                : Out std_logic; -- LLink ready Flag
        LL2PLB_Done               : out std_logic; -- LLink receive done Flag
        LL2PLB_Src_Dsc_Rcvd       : out std_logic; -- Source Discontinue Received Flag
        LL2PLB_SOF_Rcvd           : out std_logic; -- Start of Frame Received Flag
        LL2PLB_EOF_Rcvd           : out std_logic; -- End of Frame Received Flag
        LL2PLB_SOP_Rcvd           : out std_logic; -- Start of Payload Received Flag
        LL2PLB_EOP_Rcvd           : out std_logic; -- End of Payload Received Flag
        LL2PLB_MSWS               : Out std_logic; -- Must Start With Single output flag
        LL2PLB_MEWS               : Out std_logic; -- Must End With Single output flag
        
     -- Local Link Data Destination Interface Outputs
     -- (syncronous to Bus_clk for this version)
        Bus2IP_MstWr_dst_rdy_n    : out std_logic;
        Bus2IP_MstWr_dst_dsc_n    : out std_logic;
     
     -- Local Link Source Interface inputs
     -- (syncronous to Bus_clk for this version)
        --IP2Bus_MstWr_clk          : in  std_logic;
        IP2Bus_MstWr_sof_n        : in  std_logic;
        IP2Bus_MstWr_eof_n        : in  std_logic;
        IP2Bus_MstWr_sop_n        : in  std_logic;
        IP2Bus_MstWr_eop_n        : in  std_logic;
        IP2Bus_MstWr_rem          : in  std_logic_vector(0 to C_REM_WIDTH-1);
        IP2Bus_MstWr_d            : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
        IP2Bus_MstWr_src_rdy_n    : in  std_logic;
        IP2Bus_MstWr_src_dsc_n    : in  std_logic;
        
      
      -- WrFIFO Occupancy Status  
     -- (syncronous to Bus_clk for this version)
        IP2Bus_MstWr_Occupancy    : in  std_logic_vector(0 to C_WRFIFO_OCCUPANCY_WIDTH-1)  
    );

end entity llink_wr_backend_no_fifo;


architecture implementation of llink_wr_backend_no_fifo is

  
  
  -- Constants
  -- Types
  
  
     type LL_CNTL_STATES_TYPE is (
                                  LL_IDLE,
                                  LL_GO,
                                  LL_SRC_DISCONTINUE,
                                  LL_DST_DISCONTINUE
                                 );

  -- Signals
  
     -- local link signals
     signal  sig_mstwr_rem            : std_logic_vector(0 to C_REM_WIDTH-1);
     signal  sig_mstwr_d              : std_logic_vector(0 to C_PLB_DWIDTH-1);
     signal  sig_mstwr_sof            : std_logic;
     signal  sig_mstwr_eof            : std_logic;
     signal  sig_mstwr_sop            : std_logic;
     signal  sig_mstwr_eop            : std_logic;
     signal  sig_mstwr_src_rdy        : std_logic;
     signal  sig_mstwr_src_dsc        : std_logic;
     signal  sig_mstwr_dst_rdy        : std_logic;
     signal  sig_mstwr_dst_dsc        : std_logic;
     
     
     -- backend state machine signals
     Signal  llsm_cntl_state_ns         : LL_CNTL_STATES_TYPE;
     Signal  llsm_cntl_state            : LL_CNTL_STATES_TYPE;
     signal  sig_llsm_dst_dsc_ns        : std_logic;
     signal  sig_llsm_dst_dsc           : std_logic;
     signal  sig_llsm_2plb_src_dsc_ns   : std_logic;
     Signal  sig_llsm_2plb_src_dsc      : std_logic;
     signal  sig_llsm_force_dst_rdy_ns  : std_logic;
     signal  sig_llsm_force_dst_rdy     : std_logic;
     signal  sig_llsm_done_ns           : std_logic;
     signal  sig_llsm_done              : std_logic;
     signal  sig_llsm_rdy               : std_logic;
     signal  sig_llsm_rdy_ns            : std_logic;
     
     
     -- backend clock to frontend clock synchronized signals from Bus clk to rd_clk
     Signal sig_ll2plb_done           : std_logic;
     Signal sig_ll2plb_s_h_done       : std_logic;
     Signal sig_ll2plb_src_dsc        : std_logic;
     Signal sig_ll2plb_s_h_src_dsc    : std_logic;
     
     
     -- frontend clock to backend clock synchronized signals from Bus clk to rd_clk
     Signal sig_plb2ll_init           : std_logic;
     Signal sig_plb2ll_activate       : std_logic;
     Signal sig_plb2ll_dst_dsc        : std_logic;
     
     -- Other stuff
     Signal sig_sop_rcvd_pulse        : std_logic;
     
     -- backend fifo read ack sample and hold
     Signal sig_llink_src_data_valid  : std_logic;

     -- data hold register stuff
     Signal payload_start             : std_logic;
     Signal payload_end               : std_logic;
      
      
      
      
      
            
  
  -- Component Declarations

    
    -- ----- component FDRE -----
    --   component FDRE is
    --     port (
    --       Q  : out std_logic;
    --       C  : in  std_logic;
    --       CE : in  std_logic;
    --       D  : in  std_logic;
    --       R  : in  std_logic
    --     );
    --   end component FDRE;




begin --(architecture implementation)


    -- Misc. Connections
  
   ----------------------------------------------------------------------------   
   -- Data transfer signals and flags  (to PLB Write Controller)
   ----------------------------------------------------------------------------   
      LL2PLB_FIFO_Almost_Empty    <= '0';
      LL2PLB_FIFO_Empty           <= IP2Bus_MstWr_src_rdy_n;
      LL2PLB_FIFO_SOF             <= sig_mstwr_sof and sig_llink_src_data_valid;
      LL2PLB_FIFO_EOF             <= sig_mstwr_eof and sig_llink_src_data_valid;
      LL2PLB_FIFO_Data            <= sig_mstwr_d  ;
      LL2PLB_FIFO_REM             <= (others => '1'); -- REM not usable in no-fifo configuration
      LL2PLB_RdData_Valid         <= sig_llink_src_data_valid ;
  
      
    
   ----------------------------------------------------------------------------   
    -- Local Link Controller Status out  (to PLB Write Controller)                             
   ----------------------------------------------------------------------------   
      LL2PLB_Done                 <= sig_ll2plb_done or 
                                     sig_ll2plb_s_h_done;
      
      LL2PLB_Src_Dsc_Rcvd         <= sig_ll2plb_src_dsc or 
                                     sig_ll2plb_s_h_src_dsc;
      
            
      
   ----------------------------------------------------------------------------   
   -- In the no-fifo mode, it is assumed that the User fifo contains the full
   -- packet prior to the Write command being given to the master (TEMAC op mode).
   -- Therefore these two signals are not needed for threshold override in the 
   -- Write Controller  (to PLB Write Controller).   
   ----------------------------------------------------------------------------   
      LL2PLB_SOF_Rcvd             <= '1';
                                     
      LL2PLB_EOF_Rcvd             <= '1';    
            
    
    
      
   ----------------------------------------------------------------------------   
   -- Local Link Interface with User IP
   ----------------------------------------------------------------------------   
                               
      sig_mstwr_sop             <=  not(IP2Bus_MstWr_sop_n);                         
      sig_mstwr_eop             <=  not(IP2Bus_MstWr_eop_n);                         
      sig_mstwr_sof             <=  not(IP2Bus_MstWr_sof_n);     
      sig_mstwr_eof             <=  not(IP2Bus_MstWr_eof_n);     
      sig_mstwr_rem             <=  IP2Bus_MstWr_rem       ;       
      sig_mstwr_d               <=  IP2Bus_MstWr_d         ;         
      sig_mstwr_src_rdy         <=  not(IP2Bus_MstWr_src_rdy_n); 
      sig_mstwr_src_dsc         <=  not(IP2Bus_MstWr_src_dsc_n); 
                        
      Bus2IP_MstWr_dst_rdy_n    <=  not(sig_mstwr_dst_rdy);
      Bus2IP_MstWr_dst_dsc_n    <=  not(sig_mstwr_dst_dsc);
                        
      sig_llink_src_data_valid  <=  sig_mstwr_src_rdy;
      sig_mstwr_dst_dsc         <=  sig_llsm_dst_dsc;
 
 
 
   -------------------------------------------------------------------------------    
   -- Bus Clock to LocalLink Clock domain transition
   -- These are the same for the no-fifo configuration
   -------------------------------------------------------------------------------    
    
      sig_plb2ll_init       <=  PLB2LL_Init or Bus_Rst;
 
      sig_plb2ll_activate   <=  PLB2LL_Activate;
 
      sig_plb2ll_dst_dsc    <=  PLB2LL_Dst_Dsc;
 
 
 
 
   -------------------------------------------------------------------------------    
   -- LocalLink Clock to Bus Clock transition
   -- These are the same for the no-fifo configuration
   -------------------------------------------------------------------------------    
 
      sig_ll2plb_src_dsc  <=  sig_llsm_2plb_src_dsc;
      
      sig_ll2plb_done     <=  sig_llsm_done;

     

  
  
  
  
   ------------------------------------------------------------------ 
   -- Assign the Start and End Alignment Flags
   -- These cannot be used in the no-fifo configuration so they are
   -- set to '0'. 
   ------------------------------------------------------------------ 

      LL2PLB_MSWS         <=  '0';                              
      LL2PLB_MEWS         <=  '0';

 
 
    
   ------------------------------------------------------------------ 
   -- Assign LLink Ready flag
   -- This just echos the src_rdy assertion from the LLink.
   ------------------------------------------------------------------ 
    
     LL2PLB_Rdy  <=  sig_llsm_rdy;       
     
     
     
 
 
        
   ------------------------------------------------------------------ 
   -- Since DMA/SG is not supported, housekeep these signals
   -- 
   ------------------------------------------------------------------ 
    
      sig_mstwr_dst_rdy <=  PLB2LL_FIFO_REN or
                            sig_llsm_force_dst_rdy;
       
      LL2PLB_FIFO_SOP    <= '0';
      LL2PLB_FIFO_EOP    <= '0';
      LL2PLB_SOP_Rcvd    <= '0';
      LL2PLB_EOP_Rcvd    <= '0';
      
      sig_sop_rcvd_pulse <=  '0';
      
      payload_start      <= sig_llink_src_data_valid and
                            sig_mstwr_sof;
      payload_end        <= sig_llink_src_data_valid and
                            sig_mstwr_eof;
   

     
   ------------------------------------------------------------------ 
   -- Input User FIFO Occupancy Housekeeping
   -- 
   ------------------------------------------------------------------ 
    
      ------------------------------------------------------------
      -- If Generate
      --
      -- Label: USE_OCCUPANCY
      --
      -- If Generate Description:
      --  Connects the input User IP generated FIFO Occupancy to 
      -- the output port occupancy sent to the Master Write 
      -- Controller.
      --
      ------------------------------------------------------------
      USE_OCCUPANCY : if (C_DISREGARD_OCCUPANCY = False) generate
      
         begin
      
           LL2PLB_WRFIFO_Occupancy <= IP2Bus_MstWr_Occupancy;       
                   
                   
         end generate USE_OCCUPANCY;

       
      ------------------------------------------------------------
      -- If Generate
      --
      -- Label: IGNORE_OCCUPANCY
      --
      -- If Generate Description:
      --  Ignores the input User IP generated FIFO Occupancy and 
      --  fixes the output port occupancy sent to the Master Write
      --  Controller to a constant of all '1's (a max occupancy).
      --
      --
      ------------------------------------------------------------
      IGNORE_OCCUPANCY : if (C_DISREGARD_OCCUPANCY = True) generate
      
         begin
      
           LL2PLB_WRFIFO_Occupancy <= (others => '1');       
                   
                   
         end generate IGNORE_OCCUPANCY;
      
      
      
      
      
      
       
     
     
   ------------------------------------------------------------------ 
   -- Sample and Hold Flops for Rd/Wr Controller Signaling
   -- 
   ------------------------------------------------------------------ 
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: LATCH_LL2PLB_SRC_DSC
    --
    -- Process Description:
    --    This process implements a sample and hold register for the
    -- sig_ll2plb_src_dsc signal. It is used to indicate that the 
    -- LocalLink side of the module has been discontinued by the  
    -- Source device. This tells the PLB Write Controller to abort  
    -- the data transfer if started or refrain from initiating it.
    --
    -------------------------------------------------------------
    LATCH_LL2PLB_SRC_DSC : process (Bus_Clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst         = '1' or
                PLB2LL_Init     = '1' or
                PLB2LL_Activate = '1') then
               
               sig_ll2plb_s_h_src_dsc <= '0'; -- cleared
            
            elsif (sig_ll2plb_src_dsc = '1') then
               
               sig_ll2plb_s_h_src_dsc <= '1'; -- latch a high
              
            else
              
              null;  -- hold state
              
            end if;        
         end if;
       end process LATCH_LL2PLB_SRC_DSC; 
    
    
    
    
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: LATCH_LL2PLB_DONE
    --
    -- Process Description:
    --    This process implements a sample and hold register for the
    -- sig_ll2plb_done signal. It is used to indicate that the Local 
    -- Link side of the WrFIFO has completed operations for the 
    -- current packet transfer.
    --
    -------------------------------------------------------------
    LATCH_LL2PLB_DONE : process (Bus_Clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst         = '1' or
                PLB2LL_Init     = '1' or
                PLB2LL_Activate = '1') then
               
               sig_ll2plb_s_h_done <= '0'; -- cleared
            
            elsif (sig_ll2plb_done = '1') then
               
               sig_ll2plb_s_h_done <= '1'; -- latch a high
              
            else
              
              null;  -- hold state
              
            end if;        
         end if;
       end process LATCH_LL2PLB_DONE; 
    
    
    
    
    
   ------------------------------------------------------------------ 
   -- LocalLink State Machine
   -- This is a LLink Destination
   ------------------------------------------------------------------ 
    
    
    
    -------------------------------------------------------------
    -- Combinational Process
    --
    -- Label: LLINK_CONTROLLER_COMB
    --
    -- Process Description:
    --  Combinational part of the Local Link Controller State Machine.
    --
    -------------------------------------------------------------
    LLINK_CONTROLLER_COMB : process (llsm_cntl_state,
                                     sig_plb2ll_init,
                                     sig_plb2ll_activate,
                                     sig_plb2ll_dst_dsc,
                                     sig_mstwr_dst_rdy,
                                     sig_mstwr_src_rdy,
                                     sig_mstwr_src_dsc,
                                     sig_mstwr_eof
                                     )
       begin
    
         if (sig_plb2ll_init = '1') then
           
          -- init states  
            llsm_cntl_state_ns        <= LL_IDLE;
            sig_llsm_dst_dsc_ns       <= '0';
            sig_llsm_2plb_src_dsc_ns  <= '0';
            sig_llsm_force_dst_rdy_ns <= '0';
            sig_llsm_done_ns          <= '0';
            sig_llsm_rdy_ns           <= '0';
           
         else
           
          -- default states  
            llsm_cntl_state_ns        <= LL_IDLE;
            sig_llsm_dst_dsc_ns       <= '0';
            sig_llsm_2plb_src_dsc_ns  <= '0';
            sig_llsm_force_dst_rdy_ns <= '0';
            sig_llsm_done_ns          <= '0';
            sig_llsm_rdy_ns           <= '1';
           
            
          -- State control  
            case llsm_cntl_state is
              
              -------------------------
              when LL_IDLE =>
              -------------------------
              
                 if (sig_plb2ll_activate = '1') then
                 
                    llsm_cntl_state_ns    <= LL_GO;
                 
                 else
                 
                    llsm_cntl_state_ns    <= LL_IDLE;                 
                 
                 end if;
                               
                 
              -------------------------
              when LL_GO =>
              -------------------------
                 
                  if (sig_mstwr_eof     = '1' and
                      sig_mstwr_src_rdy = '1' and
                      sig_mstwr_dst_rdy = '1') then  -- done with this packet

                     llsm_cntl_state_ns    <= LL_IDLE; 
                     sig_llsm_done_ns      <= '1';
                  
                          
                  Elsif (sig_mstwr_src_dsc = '1' and    -- Source aborting the transfer
                         sig_mstwr_src_rdy = '1' and
                        (sig_mstwr_dst_rdy = '0' or     -- but the destination is not ready or
                         sig_mstwr_eof     = '0')) then -- this is not yet the normal end of packet  
                  
                     llsm_cntl_state_ns        <= LL_SRC_DISCONTINUE; 
                     sig_llsm_done_ns          <= '1';
                     sig_llsm_force_dst_rdy_ns <= '1';    
                  
                  
                  elsif (sig_plb2ll_dst_dsc = '1') then  -- PLB write SM aborting the transfer
                  
                     llsm_cntl_state_ns        <= LL_DST_DISCONTINUE;     
                     sig_llsm_dst_dsc_ns       <= '1';
                     sig_llsm_force_dst_rdy_ns <= '1';    
                          
                          
                  else
                  
                     llsm_cntl_state_ns    <= LL_GO;
                  
                  end if;
                
                
              
              -------------------------
              when LL_SRC_DISCONTINUE =>
              -------------------------
                  
                  if (sig_mstwr_src_rdy = '1' and
                      sig_mstwr_dst_rdy = '1' and
                      sig_mstwr_eof     = '1') then   -- Destination has acknowledged abort
                  
                     llsm_cntl_state_ns        <= LL_IDLE; 
                     sig_llsm_2plb_src_dsc_ns  <= '1';
                     sig_llsm_done_ns          <= '1';
                  
                  else                                -- wait for Destination ready
                  
                     llsm_cntl_state_ns        <= LL_SRC_DISCONTINUE;     
                     sig_llsm_force_dst_rdy_ns <= '1';    
                          
                  end if;
                  
              
              -------------------------
              when LL_DST_DISCONTINUE =>
              -------------------------
                  
                  if (sig_mstwr_dst_rdy = '1' and
                      sig_mstwr_src_rdy = '1' and
                      sig_mstwr_eof     = '1') then  -- discontinue complete 
                                                     
                     llsm_cntl_state_ns    <= LL_IDLE; 
                     sig_llsm_done_ns      <= '1';
                  
                  else   -- discontinue completed   
                                   
                     llsm_cntl_state_ns        <= LL_DST_DISCONTINUE;     
                     sig_llsm_dst_dsc_ns       <= '1';
                     sig_llsm_force_dst_rdy_ns <= '1';    
                  
                  end if;
                  
              
              -------------------------
              when others =>
              -------------------------
              
                llsm_cntl_state_ns    <= LL_IDLE;
                
            end case;
            
           
         end if;
    
       end process LLINK_CONTROLLER_COMB; 
    

   
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: LLINK_CONTROLLER_SYNC
    --
    -- Process Description:
    --  Synchronous part of the Local Link Controller State Machine.
    --
    -------------------------------------------------------------
    LLINK_CONTROLLER_SYNC : process (Bus_Clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (sig_plb2ll_init = '1') then
               
               llsm_cntl_state         <= LL_IDLE;
               sig_llsm_dst_dsc        <= '0'    ;
               sig_llsm_2plb_src_dsc   <= '0'    ;
               sig_llsm_force_dst_rdy  <= '0'    ;
               sig_llsm_done           <= '0'    ;
               sig_llsm_rdy            <= '0'    ;     
              
            else
               
               llsm_cntl_state         <= llsm_cntl_state_ns       ;
               sig_llsm_dst_dsc        <= sig_llsm_dst_dsc_ns      ;
               sig_llsm_2plb_src_dsc   <= sig_llsm_2plb_src_dsc_ns ;
               sig_llsm_force_dst_rdy  <= sig_llsm_force_dst_rdy_ns;
               sig_llsm_done           <= sig_llsm_done_ns         ;
               sig_llsm_rdy            <= sig_llsm_rdy_ns          ;
           
            end if;        
         end if;
       end process LLINK_CONTROLLER_SYNC; 
  
  
  
  
   
end implementation;
