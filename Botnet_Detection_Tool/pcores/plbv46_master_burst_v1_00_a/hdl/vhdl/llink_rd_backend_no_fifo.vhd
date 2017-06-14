-------------------------------------------------------------------------------
-- $Id: llink_rd_backend_no_fifo.vhd,v 1.2 2006/10/23 23:03:08 dougt Exp $
-------------------------------------------------------------------------------
-- llink_rd_backend_no_fifo.vhd
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
-- Filename:        llink_rd_backend_no_fifo.vhd
--
-- Description:     
--  This Read Local Link backend interface is synchronous to the Bus Clock
--  for both the bus interface and the LocalLink interface and it has no 
--  intermediate fifo between the LocalLink and the Master Read/Write                 
--  Controller.                
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              llink_rd_backend_no_fifo.vhd
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


library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.log2;

library unisim; -- Required for Xilinx primitives
use unisim.vcomponents.all;  


-------------------------------------------------------------------------------

entity llink_rd_backend_no_fifo is
  generic (
     C_PLB_DWIDTH           : Integer := 64;
     C_SG_IS_PRESENT        : Integer := 1; -- 0 = no S/G, 1 = S/G is present
     C_RD_HDR_SIZE_BYTES    : Integer := 0; -- 0 = no hdr else the hdr size
     C_RD_FTR_SIZE_BYTES    : Integer := 0; -- 0 = no ftr else the ftr size
     C_REM_WIDTH            : Integer := 8; -- 1, 3, or C_PLB_DWIDTH/8
     C_REM_POLARITY         : Integer := 0; -- 0 = active low, 1 = active high
     C_DISREGARD_VACANCY    : boolean := True; -- False = use vacancy, True = ignore vacancy
     C_RDFIFO_VACANCY_WIDTH : Integer := 10;
     C_FAMILY               : String  := "virtex4" 
    );
  port (

     -- System Inputs
     -- (syncronous to Bus_clk)
        Bus_Clk                   : In  std_logic;
        Bus_Rst                   : In  std_logic;
        Bus_Freeze                : In  std_logic;
                                                             
     -- LL FIFO Write Inputs from PLB Read Master                                
     -- (syncronous to Bus_clk)                              
        PLB2LL_FIFO_WEN           : In  std_logic;           
        PLB2LL_FIFO_SOP           : In  std_logic;
        PLB2LL_FIFO_EOP           : In  std_logic;
        PLB2LL_FIFO_REM           : In  std_logic_vector(0 to C_REM_WIDTH-1);
        PLB2LL_FIFO_Data          : In  std_logic_vector(0 to C_PLB_DWIDTH- 1);
        
     -- LL FIFO Write Inputs from Scatter Gather Service                                
     -- (syncronous to Bus_clk)                              
        SG2LL_FIFO_WEN            : in  std_logic;
        SG2LL_FIFO_SOF            : in  std_logic;
        SG2LL_FIFO_EOF            : in  std_logic;
        SG2LL_FIFO_REM            : in  std_logic_vector(0 to C_REM_WIDTH-1);
        SG2LL_FIFO_Data           : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
        
     
     -- LL FIFO Write Status
     -- (syncronous to Bus_clk)
        LL2PLB_FIFO_Almost_full   : Out std_logic;
        LL2PLB_FIFO_Full          : Out std_logic;
        --LL2PLB_FIFO_Wr_Count      : out std_logic_vector(0 to C_RDFIFO_WRCNT_WIDTH-1);
        LL2PLB_FIFO_Wr_Vacancy    : out std_logic_vector(0 to C_RDFIFO_VACANCY_WIDTH-1);
        
     -- PLB Read Controller interface inputs
     -- (syncronous to Bus_clk)
        PLB2LL_Init               : In  std_logic;
        PLB2LL_Activate           : In  std_logic;
        PLB2LL_Src_Dsc            : In  std_logic;
        PLB2LL_HdrFtr_Sel         : in  std_logic; --1=Header or Footer, 0=Payload
     
     -- PLB Read Controller interface Outputs
     -- (syncronous to Bus_clk)
        LL2PLB_Rdy                : Out std_logic;
        LL2PLB_Done               : out std_logic;
        LL2PLB_Dest_Dsc           : out std_logic;
        
     -- Local Link Data Destination Interface Inputs
     -- (must be syncronous to Bus_clk for this version)
     --   IP2Bus_MstRd_clk          : in  std_logic;  -- uses Bus_Clk
        IP2Bus_MstRd_dst_rdy_n    : in  std_logic;
        IP2Bus_MstRd_dst_dsc_n    : in  std_logic;
     
     -- Local Link Source Interface Outputs
     -- (syncronous to Bus_clk for this version)
        Bus2IP_MstRd_sof_n        : out std_logic;
        Bus2IP_MstRd_eof_n        : out std_logic;
        Bus2IP_MstRd_eop_n        : out std_logic;
        Bus2IP_MstRd_sop_n        : out std_logic;
        Bus2IP_MstRd_rem          : out std_logic_vector(0 to C_REM_WIDTH-1);
        Bus2IP_MstRd_d            : out std_logic_vector(0 to C_PLB_DWIDTH-1);
        Bus2IP_MstRd_src_rdy_n    : out std_logic;
        Bus2IP_MstRd_src_dsc_n    : out std_logic;
        
      
      -- User IP RdFIFO Vacancy Status  
      -- (syncronous to Bus_clk for this version and sourced by the IP)
        IP2Bus_MstRd_Vacancy      : in  std_logic_vector(0 to C_RDFIFO_VACANCY_WIDTH-1)
      
    );

end entity llink_rd_backend_no_fifo;


architecture implementation of llink_rd_backend_no_fifo is

  -- Constants
  
  
  -- Types
  
  
     type LL_CNTL_STATES_TYPE is (
                                  LL_IDLE,
                                  LL_GO,
                                  LL_SRC_DISCONTINUE,
                                  LL_DST_DISCONTINUE
                                 );

  -- Signals
  
     -- FIFO signals
     signal  sig_rdfifo_wen           : std_logic;
     Signal  sig_rdfifo_data          : std_logic_vector(0 to C_PLB_DWIDTH-1);
     Signal  sig_rdfifo_wr_sof        : std_logic;
     Signal  sig_rdfifo_wr_eof        : std_logic;
     Signal  sig_rdfifo_wr_sop        : std_logic;
     Signal  sig_rdfifo_wr_eop        : std_logic;
     Signal  sig_rdfifo_wr_rem        : std_logic_vector(0 to C_REM_WIDTH-1);
     Signal  sig_rdfifo_wr_data       : std_logic_vector(0 to C_PLB_DWIDTH-1);
     
     
     -- local link signals
     signal  sig_mstrd_rem            : std_logic_vector(0 to C_REM_WIDTH-1);
     signal  sig_mstrd_rem_invert     : std_logic_vector(0 to C_REM_WIDTH-1);
     signal  sig_mstrd_sof            : std_logic;
     signal  sig_mstrd_eof            : std_logic;
     signal  sig_mstrd_sop            : std_logic;
     signal  sig_mstrd_eop            : std_logic;
     signal  sig_mstrd_src_rdy        : std_logic;
     signal  sig_mstrd_src_dsc        : std_logic;
     signal  sig_mstrd_dst_rdy        : std_logic;
     signal  sig_mstrd_dst_dsc        : std_logic;
     
     
     -- backend state machine signals
     Signal  llsm_cntl_state_ns         : LL_CNTL_STATES_TYPE;
     Signal  llsm_cntl_state            : LL_CNTL_STATES_TYPE;
     signal  sig_llsm_force_sof_ns      : std_logic;
     signal  sig_llsm_force_sof         : std_logic;
     signal  sig_llsm_force_eof_ns      : std_logic;
     signal  sig_llsm_force_eof         : std_logic;
     signal  sig_llsm_force_src_dsc_ns  : std_logic;
     signal  sig_llsm_force_src_dsc     : std_logic;
     signal  sig_llsm_2plb_dest_dsc_ns  : std_logic;
     signal  sig_llsm_2plb_dest_dsc     : std_logic;
     signal  sig_llsm_done_ns           : std_logic;
     signal  sig_llsm_done              : std_logic;
     signal  sig_llsm_rdy               : std_logic;
     signal  sig_llsm_rdy_ns            : std_logic;
     
                                     
     -- backend clock to frontend clock synchronized signals 
     -- from Bus clk to rd_clk
     Signal sig_ll2plb_done           : std_logic;
     Signal sig_ll2plb_dest_dsc       : std_logic;
     
     
     -- frontend clock to backend clock synchronized signals 
     -- from Bus clk to rd_clk
     Signal sig_plb2ll_init           : std_logic;
     Signal sig_plb2ll_activate       : std_logic;
     Signal sig_plb2ll_src_dsc        : std_logic;
     Signal sig_eof_has_been_written  : std_logic;
     Signal sig_sg2ll_sof             : std_logic;
     
     
     -- Other stuff
     Signal sig_eof_written           : std_logic;
     

  
  
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


-------------------------------------------------------------------------  
-- Misc. Connections
-------------------------------------------------------------------------  
    
    -- FIFO Write Status out (to Rd/Wr Controller)
      LL2PLB_FIFO_Almost_full     <= '0';
      LL2PLB_FIFO_Full            <= IP2Bus_MstRd_dst_rdy_n;
    
    -- Local Link Controller Status out (to Rd/Wr Controller)                             
      
      LL2PLB_Done             <= sig_ll2plb_done;
      
      LL2PLB_Dest_Dsc         <= sig_ll2plb_dest_dsc;
      
      LL2PLB_Rdy              <= sig_llsm_rdy;
    
    
    
    -- Local Link Output Port Assignments
   
      Bus2IP_MstRd_sof_n       <= not(sig_mstrd_sof);    
      
      Bus2IP_MstRd_eof_n       <= not(sig_mstrd_eof);    
      
      Bus2IP_MstRd_sop_n       <= not(sig_mstrd_sop);
      
      Bus2IP_MstRd_eop_n       <= not(sig_mstrd_eop);
      
      Bus2IP_MstRd_rem         <= sig_mstrd_rem;      
      
      Bus2IP_MstRd_d           <= sig_rdfifo_data;        
      
      Bus2IP_MstRd_src_rdy_n   <= not(sig_mstrd_src_rdy);
      
      Bus2IP_MstRd_src_dsc_n   <= not(sig_mstrd_src_dsc);
      
  
    -- Local Link Input Port Assignments
  
      sig_mstrd_dst_rdy        <= not(IP2Bus_MstRd_dst_rdy_n);
      
      sig_mstrd_dst_dsc        <= not(IP2Bus_MstRd_dst_dsc_n);
      
  
  
  
    -- Misc. Assignments
      
      sig_rdfifo_data          <= sig_rdfifo_wr_data;
      
      sig_mstrd_sof            <=  sig_llsm_force_sof or
                                   sig_rdfifo_wr_sof;
      
      sig_mstrd_eof            <=  sig_llsm_force_eof or
                                   sig_rdfifo_wr_eof;
      
      sig_mstrd_sop            <= sig_rdfifo_wr_sop;
      
      sig_mstrd_eop            <= sig_rdfifo_wr_eop;
      
      sig_mstrd_src_rdy        <=  sig_llsm_force_sof or
                                   sig_llsm_force_eof or
                                   sig_rdfifo_wen;
      
      sig_mstrd_src_dsc        <=  sig_llsm_force_src_dsc;
      
      sig_eof_written          <=  sig_rdfifo_wr_eof and
                                   sig_rdfifo_wen;
      
      sig_plb2ll_init          <=  Bus_Rst or 
                                   PLB2LL_Init; 
   
   
 
 
 
-------------------------------------------------------------------------  
-- Signals that used to be edge detected and synchro'd
-- Across Clock domains in the Async version of this design.       
-------------------------------------------------------------------------  
       
     sig_plb2ll_activate       <=  PLB2LL_Activate;
       
     sig_plb2ll_src_dsc        <=  PLB2LL_Src_Dsc;
       
     sig_sg2ll_sof             <=  SG2LL_FIFO_SOF;
     
     sig_eof_has_been_written  <=  sig_eof_written;     
       
     sig_ll2plb_dest_dsc       <=  sig_llsm_2plb_dest_dsc;
       
     sig_ll2plb_done           <=  sig_llsm_done;
        


-------------------------------------------------------------------------  
-- Housekeeping of signals when there will never be DMA/SG support      
-------------------------------------------------------------------------  
       
     sig_rdfifo_wr_sof   <=  PLB2LL_FIFO_SOP;
       
     sig_rdfifo_wr_eof   <=  PLB2LL_FIFO_EOP;
       
     sig_rdfifo_wr_sop   <=  '0';  -- not used
      
     sig_rdfifo_wr_eop   <=  '0';  -- not used 
                                               
     sig_rdfifo_wen      <=  PLB2LL_FIFO_WEN;  
                                               
     sig_rdfifo_wr_data  <=  PLB2LL_FIFO_Data; 
                                               
     sig_rdfifo_wr_rem   <=  PLB2LL_FIFO_REM;  
 
 
 
 
-------------------------------------------------------------------------  
-- REM Bus Housekeeping       
-------------------------------------------------------------------------  
 
     
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: HIGH_REM_POLARITY
     --
     -- If Generate Description:
     -- Passes active high REM value through to LLink
     --
     --
     ------------------------------------------------------------
     HIGH_REM_POLARITY : if (C_REM_POLARITY = 1) generate
     
        begin
           
           sig_mstrd_rem            <= sig_rdfifo_wr_rem;
    
     
        end generate HIGH_REM_POLARITY;
         
                    
                    
                    
     ------------------------------------------------------------
     -- If Generate
     --
     -- Label: LOW_REM_POLARITY
     --
     -- If Generate Description:
     -- Inverts the REM polarity before assigning it to the 
     -- LLink .
     --
     ------------------------------------------------------------
     LOW_REM_POLARITY : if (C_REM_POLARITY = 0) generate
     
        begin
           
          -------------------------------------------------------------
          -- Combinational Process
          --
          -- Label: INVERT_REM
          --
          -- Process Description:
          --   This process inverts the assertion polarity of the 
          -- commanded BE value that is used during single data
          -- beat Read Commands from the User IP logic. This is used
          -- for the REM value assignment on the Read LocalLink.
          --
          -------------------------------------------------------------
          INVERT_REM : process (sig_rdfifo_wr_rem)
             begin
               for be_index in 0 to C_REM_WIDTH-1 loop
               
                  sig_mstrd_rem(be_index) <= not(sig_rdfifo_wr_rem(be_index));
                 
               end loop;
          
             end process INVERT_REM; 
           
     
        end generate LOW_REM_POLARITY;
     




-------------------------------------------------------------------------  
-- Input FIFO Vacancy Housekeeping      
-------------------------------------------------------------------------  
     
      ------------------------------------------------------------
      -- If Generate
      --
      -- Label: USE_VACANCY
      --
      -- If Generate Description:
      --  Connects the input User IP generated FIFO Vacancy to 
      -- the output port vacancy sent to the Master Read 
      -- Controller.
      --
      ------------------------------------------------------------
      USE_VACANCY : if (C_DISREGARD_VACANCY = False) generate
      
         begin
      
           LL2PLB_FIFO_Wr_Vacancy <= IP2Bus_MstRd_Vacancy;       
                   
                   
         end generate USE_VACANCY;

       
      ------------------------------------------------------------
      -- If Generate
      --
      -- Label: IGNORE_VACANCY
      --
      -- If Generate Description:
      --  Ignores the input User IP generated FIFO Vacancy and 
      --  fixes the output port vacancy sent to the Master Write
      --  Controller to a constant of all '1's (a max vacancy).
      --
      --
      ------------------------------------------------------------
      IGNORE_VACANCY : if (C_DISREGARD_VACANCY = True) generate
      
         begin
      
           LL2PLB_FIFO_Wr_Vacancy <= (others => '1');       
                   
                   
         end generate IGNORE_VACANCY;
      
      
      
      
      
      
     

-------------------------------------------------------------------------  
-- LocalLink State Machine
-- For Read Backend, this is a LLink Source Implementation      
-------------------------------------------------------------------------  

    
                      
                                     
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
                                     sig_plb2ll_src_dsc,
                                     sig_mstrd_eof,     
                                     sig_mstrd_src_rdy,
                                     sig_mstrd_dst_rdy,
                                     sig_mstrd_dst_dsc,
                                     sig_llsm_force_sof
                                     )
       begin
    
         if (sig_plb2ll_init = '1') then
           
          -- init states  
            llsm_cntl_state_ns         <= LL_IDLE;
            sig_llsm_force_sof_ns      <= '0';
            sig_llsm_force_eof_ns      <= '0';
            sig_llsm_force_src_dsc_ns  <= '0';
            sig_llsm_2plb_dest_dsc_ns  <= '0';
            sig_llsm_done_ns           <= '0';
            sig_llsm_rdy_ns            <= '0';
           
         else
           
          -- default states  
            llsm_cntl_state_ns         <= LL_IDLE;
            sig_llsm_force_sof_ns      <= '0';
            sig_llsm_force_eof_ns      <= '0';
            sig_llsm_force_src_dsc_ns  <= '0';
            sig_llsm_2plb_dest_dsc_ns  <= '0';
            sig_llsm_done_ns           <= '0';
            sig_llsm_rdy_ns            <= '1';
           
            
          -- State control  
            case llsm_cntl_state is
              
              ---------------------------
              when LL_IDLE =>
              ---------------------------
              
                 if (sig_plb2ll_activate = '1') then
                    
                    llsm_cntl_state_ns    <= LL_GO;
                 
                 else
                 
                    llsm_cntl_state_ns    <= LL_IDLE;                 
                 
                 end if;
              
             
              ---------------------------
              when LL_GO =>
              ---------------------------
                 
                  if (sig_mstrd_eof     = '1' and
                      sig_mstrd_src_rdy = '1' and
                      sig_mstrd_dst_rdy = '1') then  -- done with this packet

                     llsm_cntl_state_ns    <= LL_IDLE; 
                     sig_llsm_done_ns      <= '1';
                  
                  elsif (sig_mstrd_dst_dsc = '1' and    -- The Destination is aborting the transfer
                         sig_mstrd_dst_rdy = '1' and    -- and it is ready
                        (sig_mstrd_src_rdy = '0' or     -- but the source is not ready or
                         sig_mstrd_eof     = '0')) then -- this is not yet the normal end of packet  
                  
                     llsm_cntl_state_ns         <= LL_DST_DISCONTINUE;
                     sig_llsm_force_sof_ns      <= sig_llsm_force_sof;
                     sig_llsm_force_eof_ns      <= '1';                  
                     sig_llsm_rdy_ns            <= '0'; -- indicate a not ready condition
                  
                  elsif (sig_plb2ll_src_dsc = '1') then  -- Read Controller is disconnecting 
                  
                     llsm_cntl_state_ns         <= LL_SRC_DISCONTINUE;
                     sig_llsm_force_sof_ns      <= sig_llsm_force_sof;
                     sig_llsm_force_eof_ns      <= '1';                  
                     sig_llsm_force_src_dsc_ns  <= '1'; 
                     sig_llsm_rdy_ns            <= '0'; -- indicate a not ready condition
                         
                  
                  else
                  
                     llsm_cntl_state_ns    <= LL_GO;
                  
                  end if;
                 
              
              ---------------------------
              when LL_SRC_DISCONTINUE =>
              ---------------------------
                  
                  sig_llsm_rdy_ns            <= '0'; -- indicate a not ready condition
                  
                  if (sig_mstrd_dst_rdy = '1' and 
                      sig_mstrd_src_rdy = '1' and
                      sig_mstrd_eof = '1') then   -- Destination has acknowledged abort
                  
                     llsm_cntl_state_ns    <= LL_IDLE; 
                     sig_llsm_done_ns      <= '1';
                  
                  else                                -- wait for Destination ready
                  
                     llsm_cntl_state_ns         <= LL_SRC_DISCONTINUE;     
                     sig_llsm_force_sof_ns      <= sig_llsm_force_sof;
                     sig_llsm_force_eof_ns      <= '1';
                     sig_llsm_force_src_dsc_ns  <= '1';
                          
                          
                  end if;
                  
              
              ---------------------------
              when LL_DST_DISCONTINUE =>
              ---------------------------
                  
                  
                  sig_llsm_rdy_ns            <= '0'; -- indicate a not ready condition
                  
                  if (sig_mstrd_dst_rdy = '1' and    -- dest ready and 
                      sig_mstrd_src_rdy = '1' and    -- src ready and
                      sig_mstrd_eof     = '1') then  -- EOF is set 
                     
                     llsm_cntl_state_ns         <= LL_IDLE; 
                     sig_llsm_2plb_dest_dsc_ns  <= '1';     
                     sig_llsm_done_ns           <= '1';
                  
                  else      -- stay in this state   
                                   
                     llsm_cntl_state_ns    <= LL_DST_DISCONTINUE;     
                     sig_llsm_force_sof_ns <= sig_llsm_force_sof;
                     sig_llsm_force_eof_ns <= '1';                  
                  
                  end if;
                  
              
              ---------------------------
              when others =>
              ---------------------------
              
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
               
               llsm_cntl_state         <= LL_IDLE   ;
               sig_llsm_force_sof      <= '0'       ;
               sig_llsm_force_eof      <= '0'       ;
               sig_llsm_force_src_dsc  <= '0'       ;
               sig_llsm_2plb_dest_dsc  <= '0'       ;
               sig_llsm_done           <= '0'       ;
               sig_llsm_rdy            <= '0'       ;     
            
            else
               
               llsm_cntl_state         <= llsm_cntl_state_ns       ;
               sig_llsm_force_sof      <= sig_llsm_force_sof_ns    ;
               sig_llsm_force_eof      <= sig_llsm_force_eof_ns    ;
               sig_llsm_force_src_dsc  <= sig_llsm_force_src_dsc_ns;
               sig_llsm_2plb_dest_dsc  <= sig_llsm_2plb_dest_dsc_ns;
               sig_llsm_done           <= sig_llsm_done_ns         ;
               sig_llsm_rdy            <= sig_llsm_rdy_ns          ;
               
            end if;        
         end if;
       end process LLINK_CONTROLLER_SYNC; 
   
end implementation;
