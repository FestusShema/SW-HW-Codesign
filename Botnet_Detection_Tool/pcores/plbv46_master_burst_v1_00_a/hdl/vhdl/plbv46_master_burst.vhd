-------------------------------------------------------------------------------
-- $Id: plbv46_master_burst.vhd,v 1.7 2007/07/13 23:39:59 dougt Exp $
-------------------------------------------------------------------------------
-- plbv46_master_burst.vhd
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
-- Filename:        plbv46_master_burst.vhd
--
-- Description:     
--                  
-- PLB Master interface utilizing Xilinx LocalLink interface for data transfer
-- interface.                  
--  This Master is optimized based on the following criteria:
--      - Fixed Native Data width of 32-bits
--      - Only Single Data Beats and Fixed Length bursts are supported.
--         - Fixed Length bursts are linited to 2 to 16 data beats
--         - This Master does not generate cacheline requests            
--      - A PLB Slave premature burst terminate is completed with a LLink
--        destination discontinue and a command error status back to the
--        requesting User Logic. No automatic request respawning.               
--      - Premature burst termination is detected if a Slave Burst terminate
--        occurs before an internal data beat counter reaches completion.            
-- 
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              plbv46_master_burst.vhd
--                 |
--                 |-- rd_wr_controller.vhd
--                 |     |
--                 |     |-- rd_wr_calc_burst.vhd
--                 |           |
--                 |           |-- plb_mstr_addr_gen.vhd
--                 |
--                 |-- llink_rd_backend_no_fifo.vhd
--                 |
--                 |-- llink_wr_backend_no_fifo.vhd
--                 |
--                 |-- cc_brst_exp_adptr.vhd
--                 |
--                 |-- data_width_adapter.vhd
--                 |
--                 |-- data_mirror_128.vhd
--
--
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $Revision: 1.7 $
-- Date:            $09/14/2006$
--
-- History:
--   DET   10/23/2006       Initial V46 Version
-- 
--     DET     1/4/2007     Initial
-- ~~~~~~
--     - Added ability to parameterize Native Data Width to 32, 64, or 128 
--     - Added Conversion Cycle and Burst Length Expansion Logic adapter
-- ^^^^^^
--
--     DET     7/13/2007     Jm.14+
-- ~~~~~~
--     - Merged the Bus_rst and IP2Bus_Mst_Reset into a single internal reset
--       distributed to all sub modules.
--     - Removed commented out instance of previous rd_wr_controller.
-- ^^^^^^
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

library proc_common_v2_00_a;
Use proc_common_v2_00_a.proc_common_pkg.all; -- need log2()
Use proc_common_v2_00_a.family.all; -- need C_FAMILY definitions

library plbv46_master_burst_v1_00_a;
Use plbv46_master_burst_v1_00_a.rd_wr_controller          ;
Use plbv46_master_burst_v1_00_a.llink_rd_backend_no_fifo  ;
Use plbv46_master_burst_v1_00_a.llink_wr_backend_no_fifo  ;
Use plbv46_master_burst_v1_00_a.data_width_adapter        ;
Use plbv46_master_burst_v1_00_a.data_mirror_128           ;
Use plbv46_master_burst_v1_00_a.cc_brst_exp_adptr         ;


-------------------------------------------------------------------------------

entity plbv46_master_burst is
  generic (
     
      
      
 -- PLB Parameters 
     
      C_MPLB_AWIDTH : INTEGER range 32 to 36 := 32;  
           -- Number of PLBV46 Address Bus bits actually used.
               
      C_MPLB_DWIDTH : INTEGER range 32 to 128 := 32;  
           --  Width of the PLBV46 Data Bus Attachment (in bits)
               
      C_MPLB_NATIVE_DWIDTH : INTEGER range 32 to 128 := 32;  
          --  Set this equal to largest data bus width needed by IPIF
          --  and IP elements.
      
      C_MPLB_SMALLEST_SLAVE     : INTEGER range 32 to 128 := 32;
          -- Indicates the Native Data Width of the smallest slave
          -- on the PLB connected to this Master. If this parameter's
          -- value is less than the native Data width of the Master,
          -- then the Conversion Cycle and Burst Length Expansion
          -- Adapter will be included in the Master's implementation.
      
      C_INHIBIT_CC_BLE_INCLUSION  : INTEGER range 0 to 1 := 0;      
          -- This parameter will inhibit the automatic inclusion
          -- of the Conversion Cycle and Burst length Expansion
          -- Adapter. This override is useful if the connected PLB has
          -- narrow Slaves attached to it but this Master will not access
          -- those narrow Slaves.
          
          
          
 -- FPGA Family Parameter      
     
      C_FAMILY : String := "virtex5"
          -- Select the target architecture type
          -- see the family.vhd package in the proc_common
          -- library
    );
  port (
    
  -- System Ports
     MPLB_Clk         : In std_logic ;
     MPLB_Rst         : In std_logic ;
     MD_Error         : Out std_logic;
     
   -- Master Request/Qualifiers to PLB V4.6 (outputs)
     M_request        : out std_logic;
     M_priority       : out std_logic_vector(0 to 1);
     M_busLock        : out std_logic;
     M_RNW            : out std_logic;
     M_BE             : out std_logic_vector(0 to (C_MPLB_DWIDTH/8) - 1);
     M_MSize          : out std_logic_vector(0 to 1);
     M_size           : out std_logic_vector(0 to 3);
     M_type           : out std_logic_vector(0 to 2);
     M_ABus           : out std_logic_vector(0 to 31);
     M_wrBurst        : out std_logic;
     M_rdBurst        : out std_logic;
     M_wrDBus         : out std_logic_vector(0 to C_MPLB_DWIDTH-1);

   -- PLB Reply to Master (inputs)
     PLB_MAddrAck     : in  std_logic;
     PLB_MSSize       : in  std_logic_vector(0 to 1);
     PLB_MRearbitrate : in  std_logic;
     PLB_MTimeout     : in  std_logic;
     PLB_MRdErr       : in  std_logic;
     PLB_MWrErr       : in  std_logic;
     PLB_MRdDBus      : in  std_logic_vector(0 to C_MPLB_DWIDTH-1);
     PLB_MRdDAck      : in  std_logic;
     PLB_MRdBTerm     : in  std_logic;
     PLB_MWrDAck      : in  std_logic;
     PLB_MWrBTerm     : in  std_logic;
  
   -- Included PLB ports but unused in the design
     M_TAttribute     : out std_logic_vector(0 to 15);
     M_lockErr        : out std_logic;
     M_abort          : out std_logic;
     M_UABus          : out std_logic_vector(0 to 31);
     PLB_MBusy        : in  std_logic;
     PLB_MIRQ         : in  std_logic;
     PLB_MRdWdAddr    : in  std_logic_vector(0 to 3);
  
  
  
     
     
   -- IP Master Request/Qualifiers
     IP2Bus_MstRd_Req           : In  std_logic;
     IP2Bus_MstWr_Req           : In  std_logic;
     IP2Bus_Mst_Addr            : in  std_logic_vector(0 to 
                                      C_MPLB_AWIDTH-1);
     IP2Bus_Mst_Length          : in  std_logic_vector(0 to 11);
     IP2Bus_Mst_BE              : in  std_logic_vector(0 to 
                                      (C_MPLB_NATIVE_DWIDTH/8) -1);     
     IP2Bus_Mst_Type            : in  std_logic;
     IP2Bus_Mst_Lock            : In  std_logic;
     IP2Bus_Mst_Reset           : In  std_logic;
     
   -- IP Master Primary Read Request Status Reply
     Bus2IP_Mst_CmdAck          : Out std_logic;
     Bus2IP_Mst_Cmplt           : Out std_logic;
     Bus2IP_Mst_Error           : Out std_logic;
     Bus2IP_Mst_Rearbitrate     : Out std_logic;
     Bus2IP_Mst_Cmd_Timeout     : out std_logic;
   
   -- IP Master Primary Read LocalLink Interface
     Bus2IP_MstRd_d             : out std_logic_vector(0 to 
                                      C_MPLB_NATIVE_DWIDTH-1); 
     Bus2IP_MstRd_rem           : out std_logic_vector(0 to 
                                      (C_MPLB_NATIVE_DWIDTH/8)-1); 
     Bus2IP_MstRd_sof_n         : Out std_logic;
     Bus2IP_MstRd_eof_n         : Out std_logic;
     Bus2IP_MstRd_src_rdy_n     : Out std_logic;
     Bus2IP_MstRd_src_dsc_n     : Out std_logic;
     
     IP2Bus_MstRd_dst_rdy_n     : In  std_logic;
     IP2Bus_MstRd_dst_dsc_n     : In  std_logic;
     
     
      
      
   -- IP Master Primary Write LocalLink Interface
     IP2Bus_MstWr_d             : In  std_logic_vector(0 to 
                                      C_MPLB_NATIVE_DWIDTH-1); 
     IP2Bus_MstWr_rem           : In  std_logic_vector(0 to 
                                      (C_MPLB_NATIVE_DWIDTH/8)-1); 
     IP2Bus_MstWr_sof_n         : In  std_logic;
     IP2Bus_MstWr_eof_n         : In  std_logic;
     IP2Bus_MstWr_src_rdy_n     : In  std_logic;
     IP2Bus_MstWr_src_dsc_n     : In  std_logic;
     
     Bus2IP_MstWr_dst_rdy_n     : Out std_logic;
     Bus2IP_MstWr_dst_dsc_n     : Out std_logic
   
    );

end entity plbv46_master_burst;


architecture implementation of plbv46_master_burst is

  
     
  -- Constants
     
     Constant LOGIC_LOW         : std_logic := '0'; 
     Constant LOGIC_HIGH        : std_logic := '1'; 
  
     Constant LENGTH_WIDTH      : integer := 12; 
     Constant LLINK_DWIDTH      : integer := C_MPLB_NATIVE_DWIDTH; 
     Constant LLINK_REM_CODING  : integer := 2; -- MASK
     Constant LLINK_REM_WIDTH   : integer := C_MPLB_NATIVE_DWIDTH/8;
     Constant REM_LOGIC_LOW     : std_logic_vector(0 to 
                                  LLINK_REM_WIDTH-1) := (others => '0'); 
     Constant LLINK_D_LOGIC_LOW : std_logic_vector(0 to 
                                  LLINK_DWIDTH-1) := (others => '0'); 
     Constant REM_POLARITY      : integer := 0;
        -- 0 = LocalLink REM is active low assertion level (V5 DMA)
        -- 1 = LocalLink REM is active high assertion level (Legacy)
    
    
     Constant MAX_FBURST_DBCNT  : integer := 16;
     
     Constant MAX_FLBURST_SIZE  : integer := MAX_FBURST_DBCNT *
                                             C_MPLB_NATIVE_DWIDTH; 
                                             -- result is bytes
     
     Constant WR_STEER_ADDR_WIDTH  : integer := 4;
    
     Constant UPPER_ADDR_SIZE      : integer := C_MPLB_AWIDTH-32;
    
     Constant RDFIFO_VACANCY_LOW   : std_logic_vector(0 to 0) := 
                                     (others => '0'); 
     Constant WRFIFO_OCCUPANCY_LOW : std_logic_vector(0 to 0) := 
                                     (others => '0'); 
    
     Constant INCLUDE_CC_BLE_SUPPORT : boolean := 
              (C_MPLB_SMALLEST_SLAVE < C_MPLB_NATIVE_DWIDTH) and
              (C_INHIBIT_CC_BLE_INCLUSION = 0);
     
     Constant OMIT_CC_BLE_SUPPORT  : boolean := 
                                     not(INCLUDE_CC_BLE_SUPPORT);
     
     
     
     
  
  -- Signal Declarations
     
                                              
  -- PLB V4.6 adapter signals
     Signal sig_combined_addrbus        : std_logic_vector(0 to 
                                          C_MPLB_AWIDTH-1);
     
     signal sig_internal_be_bus         : std_logic_vector(0 to 
                                          (C_MPLB_NATIVE_DWIDTH/8)-1);
     
     signal sig_adpt2mirror_be_bus      : std_logic_vector(0 to 
                                          (C_MPLB_DWIDTH/8)-1);
     
     signal sig_internal_rddbus         : std_logic_vector(0 to 
                                          C_MPLB_NATIVE_DWIDTH-1);
     
     signal sig_internal_wrdbus         : std_logic_vector(0 to 
                                          C_MPLB_NATIVE_DWIDTH-1);
     
     signal sig_adpt2mirror_wrdbus      : std_logic_vector(0 to 
                                          C_MPLB_DWIDTH-1);

     signal sig_mstr2adptr_wrdbus       : std_logic_vector(0 to 
                                          C_MPLB_NATIVE_DWIDTH-1);
   
   
   
   -- Master Logic interface signals
     -- Request and Qualifiers (outputs)
     signal sig_native_m_request        : std_logic;
     signal sig_native_m_priority       : std_logic_vector(0 to 1);
     signal sig_native_m_buslock        : std_logic;
     signal sig_native_m_rnw            : std_logic;
     signal sig_native_m_be             : std_logic_vector(0 to 
                                          (C_MPLB_NATIVE_DWIDTH/8) - 1);
     signal sig_native_m_msize          : std_logic_vector(0 to 1);
     signal sig_native_m_size           : std_logic_vector(0 to 3);
     signal sig_native_m_type           : std_logic_vector(0 to 2);
     signal sig_native_m_abus           : std_logic_vector(0 to 
                                          C_MPLB_AWIDTH-1);
     signal sig_native_m_wrburst        : std_logic;
     signal sig_native_m_rdburst        : std_logic;
     signal sig_native_m_wrdbus         : std_logic_vector(0 to 
                                          C_MPLB_NATIVE_DWIDTH-1);

     -- PLB Reply to Master (inputs)
     signal sig_native_plb_maddrack     : std_logic;
     signal sig_native_plb_mssize       : std_logic_vector(0 to 1);
     signal sig_native_plb_mrearbitrate : std_logic;
     signal sig_native_plb_mtimeout     : std_logic;
     signal sig_native_plb_mbusy        : std_logic;
     signal sig_native_plb_mrderr       : std_logic;
     signal sig_native_plb_mwrerr       : std_logic;
     signal sig_native_plb_mrddbus      : std_logic_vector(0 to 
                                          C_MPLB_NATIVE_DWIDTH-1);
     signal sig_native_plb_mrddack      : std_logic;
     signal sig_native_plb_mrdbterm     : std_logic;
     signal sig_native_plb_mwrdack      : std_logic;
     signal sig_native_plb_mwrbterm     : std_logic;
  
   
   
   
      

   -- Read LocalLink/Controller interconnect
     signal sig_rd_plb2ll_init            : std_logic;
     signal sig_rd_plb2ll_activate        : std_logic;
     signal sig_rd_plb2ll_src_dsc         : std_logic;
     signal sig_rd_ll2plb_rdy             : std_logic;
     signal sig_rd_ll2plb_done            : std_logic;
     signal sig_rd_ll2plb_dest_dsc        : std_logic;

     signal sig_rd_plb2ll_fifo_wen        :  std_logic;                             
     signal sig_rd_plb2ll_fifo_sop        :  std_logic;                             
     signal sig_rd_plb2ll_fifo_eop        :  std_logic;                             
     signal sig_rd_plb2ll_fifo_rem        :  std_logic_vector(0 to LLINK_REM_WIDTH-1);  
     signal sig_rd_plb2ll_fifo_data       :  std_logic_vector(0 to LLINK_DWIDTH- 1);
     
   
   
   -- Write LocalLink/Controller interconnect
     signal sig_wr_plb2ll_init            :  std_logic;
     signal sig_wr_plb2ll_activate        :  std_logic;
     signal sig_wr_plb2ll_dst_dsc         :  std_logic;
     signal sig_wr_ll2plb_rdy             :  std_logic;
     signal sig_wr_ll2plb_done            :  std_logic;    
     signal sig_wr_ll2plb_src_dsc_rcvd    :  std_logic;    
     
     signal sig_wr_plb2ll_clr_data_valid  :  std_logic;
     signal sig_wr_plb2ll_fifo_ren        :  std_logic;
     signal sig_wr_ll2plb_fifo_sof        :  std_logic;
     signal sig_wr_ll2plb_fifo_eof        :  std_logic;
     signal sig_wr_ll2plb_fifo_sop        :  std_logic;                             
     signal sig_wr_ll2plb_fifo_eop        :  std_logic;                             
     signal sig_wr_ll2plb_fifo_rem        :  std_logic_vector(0 to LLINK_REM_WIDTH-1);  
     signal sig_wr_ll2plb_fifo_data       :  std_logic_vector(0 to LLINK_DWIDTH- 1);
     signal sig_wr_ll2plb_rddata_valid    :  std_logic;                             
  
     
   -- REM polarity mod
     Signal sig_wr_rem_internal           : std_logic_vector(0 to LLINK_REM_WIDTH-1);
     Signal sig_rd_rem_internal           : std_logic_vector(0 to LLINK_REM_WIDTH-1);
  
    -- other new signals
     Signal sig_mstr_write_steer_addr     : std_logic_vector(0 to 
                                            WR_STEER_ADDR_WIDTH-1);
     
     Signal sig_write_steer_addr          : std_logic_vector(0 to 
                                            WR_STEER_ADDR_WIDTH-1);
     

     signal sig_ll2plb_fifo_full          : std_logic;
     signal sig_ll2plb_fifo_almost_full   : std_logic;
     signal sig_composite_rst             : std_logic;
  
  
  
  
                   

begin --(architecture implementation)

 
 
 
  -- Xilinx PLBV46 Simplifications
    M_Tattribute(0 to 15) <= (others => '0'); -- not used 
    M_lockErr             <= '0';
    M_abort               <= '0';
                                                                   
                                                                   
   
   
   sig_composite_rst <= MPLB_Rst or 
                        IP2Bus_Mst_Reset;
   
   
   -- sig_write_steer_addr <= sig_combined_addrbus(C_MPLB_AWIDTH-WR_STEER_ADDR_WIDTH to
   --                                               C_MPLB_AWIDTH-1);
    
   sig_mstr_write_steer_addr <= 
              sig_native_m_abus(C_MPLB_AWIDTH-WR_STEER_ADDR_WIDTH to    
                                C_MPLB_AWIDTH-1);
    
    
   
 --------------------------------------------------------------------  
 -- Note:  REM inversions (if required) are done
 -- in the LocalLink backend modules.  
 --------------------------------------------------------------------  
   Bus2IP_MstRd_rem    <=  sig_rd_rem_internal;                                                               
                                                                   
   sig_wr_rem_internal <= IP2Bus_MstWr_rem;
   
   
                                                                   
                                                                   
 
    
  
    -- Output Address Bus Adapter  --------------------------------
    
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: ADDRESS_EQ_32
    --
    -- If Generate Description:
    --   This IfGen hooks up the M_UABus and the M_ABus when the
    -- total number of address bits used is equal to 32.
    --
    ------------------------------------------------------------
    ADDRESS_EQ_32 : if (C_MPLB_AWIDTH = 32) generate
       begin
    
         M_UABus    <=  (others => '0'); 
         M_ABus     <=  sig_combined_addrbus;
                    
       end generate ADDRESS_EQ_32;
  
      
         
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: ADDRESS_GT_32
    --
    -- If Generate Description:
    --   This IfGen hooks up the M_UABus and the M_ABus when the
    -- total number of address bits used is greater than 32 but
    -- less than 64.
    --
    ------------------------------------------------------------
    ADDRESS_GT_32 : if (C_MPLB_AWIDTH > 32 and
                        C_MPLB_AWIDTH < 64) generate
    
       -- Local Constants
       -- Local variables
       -- local signals
       -- local components
    
       begin
    
        
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: ASSIGN_ADDR
         --
         -- Process Description:
         -- Rip the Upper and Lower address bus values from the 
         -- combined address bus used internally.
         --
         -------------------------------------------------------------
         ASSIGN_ADDR : process (sig_combined_addrbus)
            begin
         
            -- Default upper addr bus with zeros
               M_UABus  <=  (others => '0');
                    
            -- Overload used upper addr bus bits
               M_UABus((32-UPPER_ADDR_SIZE) to 31) <=  
                          sig_combined_addrbus(0 to UPPER_ADDR_SIZE-1);
                                       
         
            -- Set lower addr bus bits   
               M_ABus     <=  sig_combined_addrbus(C_MPLB_AWIDTH-32 to 
                                             C_MPLB_AWIDTH-1);
                                                        
            end process ASSIGN_ADDR; 
         
        
       end generate ADDRESS_GT_32;
  
 
  
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: ADDRESS_EQ_64
    --
    -- If Generate Description:
    --   This IfGen hooks up the M_UABus and the M_ABus when the
    -- total number of address bits used is equal to 64.
    --
    ------------------------------------------------------------
    ADDRESS_EQ_64 : if (C_MPLB_AWIDTH = 64) generate
       begin
    
         M_UABus    <=  sig_combined_addrbus(0 to 31); 
         M_ABus     <=  sig_combined_addrbus(32 to 63); 
                   
       end generate ADDRESS_EQ_64;
  
  
    
    
    
    
    
    
    
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: OMIT_CC_BLE_ADAPTER
    --
    -- If Generate Description:
    -- This IfGen omits the Conversion Cycle and Burst length
    -- Expansion Adapter.
    --
    ------------------------------------------------------------
    OMIT_CC_BLE_ADAPTER : if (OMIT_CC_BLE_SUPPORT) generate
    
    
       begin
          
          -- Request and Qualifiers (outputs)
          M_request                    <= sig_native_m_request  ;         
          M_priority                   <= sig_native_m_priority ;     
          M_busLock                    <= sig_native_m_buslock  ;      
          M_RNW                        <= sig_native_m_rnw      ;      
          sig_internal_be_bus          <= sig_native_m_be       ;       
          M_MSize                      <= sig_native_m_msize    ;       
          M_size                       <= sig_native_m_size     ;       
          M_type                       <= sig_native_m_type     ;       
          sig_combined_addrbus         <= sig_native_m_abus     ;       
          M_wrBurst                    <= sig_native_m_wrburst  ;       
          M_rdBurst                    <= sig_native_m_rdburst  ;       
          sig_mstr2adptr_wrdbus        <= sig_native_m_wrdbus   ;       
                                      
           --PLB Reply to Master (inputs)
          sig_native_plb_maddrack      <=  PLB_MAddrAck       ; 
          sig_native_plb_mssize        <=  PLB_MSSize         ; 
          sig_native_plb_mrearbitrate  <=  PLB_MRearbitrate   ; 
          sig_native_plb_mtimeout      <=  PLB_MTimeout       ;
          sig_native_plb_mbusy         <=  PLB_MBusy          ;
          sig_native_plb_mrderr        <=  PLB_MRdErr         ; 
          sig_native_plb_mwrerr        <=  PLB_MWrErr         ; 
          sig_native_plb_mrddbus       <=  sig_internal_rddbus; 
          sig_native_plb_mrddack       <=  PLB_MRdDAck        ; 
          sig_native_plb_mrdbterm      <=  PLB_MRdBTerm       ; 
          sig_native_plb_mwrdack       <=  PLB_MWrDAck        ; 
          sig_native_plb_mwrbterm      <=  PLB_MWrBTerm       ; 
             
          sig_write_steer_addr         <=  sig_mstr_write_steer_addr;  
             
             
             
       end generate OMIT_CC_BLE_ADAPTER;
    
     
     
     
     
     
     
    ------------------------------------------------------------
    -- If Generate
    --
    -- Label: INCLUDE_CC_BLE_ADAPTER
    --
    -- If Generate Description:
    -- This IfGen includes the Conversion Cycle and Burst Length
    -- Expansion support module.
    --
    --
    ------------------------------------------------------------
    INCLUDE_CC_BLE_ADAPTER : if (INCLUDE_CC_BLE_SUPPORT) generate
    
      begin


        ------------------------------------------------------------
        -- Instance: I_CC_BLE_ADAPTER 
        --
        -- Description:
        -- This instance includes the Conversion Cycle and Burst Length
        -- Expansion functionality.
        --
        ------------------------------------------------------------
        I_CC_BLE_ADAPTER : entity plbv46_master_burst_v1_00_a.cc_brst_exp_adptr
          generic map(
            C_NATIVE_DWIDTH      =>  C_MPLB_NATIVE_DWIDTH,  
            C_AWIDTH             =>  C_MPLB_AWIDTH       ,  
            C_SUPPORT_BURSTS     =>  1                   ,  
            C_STEER_ADDR_WIDTH   =>  WR_STEER_ADDR_WIDTH    
            )
          port map(
          
            -- System Inputs
            Bus_Clk              =>  MPLB_Clk,  
            Bus_Rst              =>  sig_composite_rst,  
          
           -- Request and Qualifiers from Master Logic
            Mst_Req_in           =>  sig_native_m_request  ,  
            Mst_Priority_in      =>  sig_native_m_priority ,  
            Mst_Buslock_in       =>  sig_native_m_buslock  ,  
            Mst_RNW_in           =>  sig_native_m_rnw      ,  
            Mst_BE_in            =>  sig_native_m_be       ,  
            Mst_MSize_in         =>  sig_native_m_msize    ,  
            Mst_Size_in          =>  sig_native_m_size     ,  
            Mst_Type_in          =>  sig_native_m_type     ,  
            Mst_Addr_in          =>  sig_native_m_abus     ,  
            Mst_WrBurst_in       =>  sig_native_m_wrburst  ,  
            Mst_RdBurst_in       =>  sig_native_m_rdburst  ,  
            Mst_WrDBus_in        =>  sig_native_m_wrdbus   ,  
                                                              
            
           -- Write DBus Steering address input
            Mst_Steer_Addr_in    =>  sig_mstr_write_steer_addr,  
                                                                 
                     
           -- PLB Reply (inputs)
            PLB_MAddrAck         =>  PLB_MAddrAck    ,  
            PLB_MSSize           =>  PLB_MSSize      ,  
            PLB_MRearbitrate     =>  PLB_MRearbitrate,  
            PLB_MTimeout         =>  PLB_MTimeout    ,
            PLB_MBusy            =>  PLB_MBusy       ,
            PLB_MRdErr           =>  PLB_MRdErr      ,
            PLB_MWrErr           =>  PLB_MWrErr      ,  
            PLB_MRdDBus          =>  sig_internal_rddbus,  
            PLB_MRdDAck          =>  PLB_MRdDAck  ,  
            PLB_MRdBTerm         =>  PLB_MRdBTerm ,  
            PLB_MWrDAck          =>  PLB_MWrDAck  ,  
            PLB_MWrBTerm         =>  PLB_MWrBTerm ,  
         
            
           -- Request Reply Outputs to Master
            To_Mstr_MAddrAck     =>  sig_native_plb_maddrack    ,  
            To_Mstr_MSSize       =>  sig_native_plb_mssize      ,  
            To_Mstr_MRearbitrate =>  sig_native_plb_mrearbitrate,  
            To_Mstr_MTimeout     =>  sig_native_plb_mtimeout    ,  
            To_Mstr_MBusy        =>  sig_native_plb_mbusy       ,
            To_Mstr_MRdErr       =>  sig_native_plb_mrderr      ,  
            To_Mstr_MWrErr       =>  sig_native_plb_mwrerr      ,  
            To_Mstr_MRdDBus      =>  sig_native_plb_mrddbus     ,  
            To_Mstr_MRdDAck      =>  sig_native_plb_mrddack     ,  
            To_Mstr_MRdBTerm     =>  sig_native_plb_mrdbterm    ,  
            To_Mstr_MWrDAck      =>  sig_native_plb_mwrdack     ,  
            To_Mstr_MWrBTerm     =>  sig_native_plb_mwrbterm    ,   
                                 
            
            
           -- Steer Address to Write Data bus steering logic 
            To_Mstr_Wr_Steer_Addr =>  sig_write_steer_addr      ,  
                                                             
            
            
            -- Outputs to PLB
            M_request_out        =>  M_request             ,  
            M_priority_out       =>  M_priority            ,  
            M_busLock_out        =>  M_busLock             ,  
            M_RNW_out            =>  M_RNW                 ,  
            M_BE_out             =>  sig_internal_be_bus   ,  
            M_MSize_out          =>  M_MSize               ,  
            M_size_out           =>  M_size                ,  
            M_type_out           =>  M_type                ,  
            M_ABus_out           =>  sig_combined_addrbus  ,  
            M_wrBurst_out        =>  M_wrBurst             ,  
            M_rdBurst_out        =>  M_rdBurst             ,  
            M_wrDBus_out         =>  sig_mstr2adptr_wrdbus  
                                        
           );
      

   
      end generate INCLUDE_CC_BLE_ADAPTER;
    
    
    
      
  
    ------------------------------------------------------------
    -- Instance: I_DATA_BUS_ADAPTER 
    --
    -- Description:
    -- This module adapts the Master's Data bus width to the 
    -- PLB Data bus width width per PLB requirements. Note 
    -- that the Master's data bus width can never be wider
    -- than the PLB Data Bus width.
    ------------------------------------------------------------
    I_DATA_BUS_ADAPTER : entity plbv46_master_burst_v1_00_a.data_width_adapter
    generic map (
      C_MPLB_DWIDTH     =>  C_MPLB_DWIDTH  ,   
      C_MIPIF_DWIDTH    =>  C_MPLB_NATIVE_DWIDTH     
      )
    port map (
      Bus2Adptr_RdDBus   =>  PLB_MRdDBus           ,  
      Adptr2Mstr_RdDBus  =>  sig_internal_rddbus   ,  

      Mstr2Adptr_WrDBus  =>  sig_mstr2adptr_wrdbus ,  
      Adptr2Bus_WrDBus   =>  sig_adpt2mirror_wrdbus,  
      
      Mstr2Adptr_BE      =>  sig_internal_be_bus   ,  
      Adptr2Bus_BE       =>  sig_adpt2mirror_be_bus   
      
      );
  
  
     
     
    ------------------------------------------------------------
    -- Instance: I_WRITE_DATA_MIRROR 
    --
    -- Description:
    --     This module provides the required dynamic PLB data   
    -- mirroring logic for the Master Write Data bus. The mirror
    -- function is based on the address of the cooresponding 
    -- write data beat, the width of the PLB attachment, and 
    -- the native data width of the Master.
    --
    ------------------------------------------------------------
    I_WRITE_DATA_MIRROR : entity plbv46_master_burst_v1_00_a.data_mirror_128
    generic map (
      C_MPLB_DWIDTH  =>  C_MPLB_DWIDTH  ,  
      C_MIPIF_DWIDTH =>  C_MPLB_NATIVE_DWIDTH    
      )
    port map (
   
      Mstr2Mirror_ABus    =>  sig_write_steer_addr  ,  
      
      Mstr2Mirror_WrDBus  =>  sig_adpt2mirror_wrdbus,  
      Mirror2Bus_WrDBus   =>  M_wrDBus              ,  
      
      Mstr2Mirror_BE      =>  sig_adpt2mirror_be_bus,  
      Mirror2Bus_BE       =>  M_BE                     
      
      );

     

      
    
    
    ------------------------------------------------------------
    -- Instance: I_RD_WR_CONTROL 
    --
    -- Description:
    --     This instance is for the main Read and Write control
    -- function.
    --
    ------------------------------------------------------------
     I_RD_WR_CONTROL : entity plbv46_master_burst_v1_00_a.rd_wr_controller
     generic map (
       C_LENGTH_WIDTH    =>  LENGTH_WIDTH        ,    
       C_AWIDTH          =>  C_MPLB_AWIDTH       ,
       C_NATIVE_DWIDTH   =>  C_MPLB_NATIVE_DWIDTH,    
       C_LLINK_REM_WIDTH =>  LLINK_REM_WIDTH     ,    
       C_LLINK_DWIDTH    =>  LLINK_DWIDTH               
       )
     port map (
   
    -- System Ports
       Bus_Clk          =>  MPLB_Clk             ,    
       Bus_Rst          =>  sig_composite_rst    ,    
       MD_Error         =>  MD_Error             ,    
       
     -- Master Request/Qualifiers to PLB V4.6 (outputs)
       M_request        =>  sig_native_m_request    ,    
       M_priority       =>  sig_native_m_priority   ,    
       M_busLock        =>  sig_native_m_buslock    ,    
       M_RNW            =>  sig_native_m_rnw        ,    
       M_BE             =>  sig_native_m_be         ,    
       M_MSize          =>  sig_native_m_msize      ,    
       M_size           =>  sig_native_m_size       ,    
       M_type           =>  sig_native_m_type       ,    
       M_ABus           =>  sig_native_m_abus       ,    
       M_wrBurst        =>  sig_native_m_wrburst    ,    
       M_rdBurst        =>  sig_native_m_rdburst    ,    
       M_wrDBus         =>  sig_native_m_wrdbus     ,    

     -- PLB Reply to Master (inputs)
       PLB_MAddrAck     =>  sig_native_plb_maddrack     ,    
       PLB_MSSize       =>  sig_native_plb_mssize       ,    
       PLB_MRearbitrate =>  sig_native_plb_mrearbitrate ,    
       PLB_MTimeout     =>  sig_native_plb_mtimeout     ,    
       PLB_MBusy        =>  sig_native_plb_mbusy,
       PLB_MRdErr       =>  sig_native_plb_mrderr       ,    
       PLB_MWrErr       =>  sig_native_plb_mwrerr       ,    
       PLB_MRdDBus      =>  sig_native_plb_mrddbus      ,    
       PLB_MRdDAck      =>  sig_native_plb_mrddack      ,    
       PLB_MRdBTerm     =>  sig_native_plb_mrdbterm     ,    
       PLB_MWrDAck      =>  sig_native_plb_mwrdack      ,    
       PLB_MWrBTerm     =>  sig_native_plb_mwrbterm     ,    


     -- IP Master Request/Qualifiers
       IP2Bus_MstRd_Req           =>  IP2Bus_MstRd_Req   ,    
       IP2Bus_MstWr_Req           =>  IP2Bus_MstWr_Req   ,    
       IP2Bus_Mst_Addr            =>  IP2Bus_Mst_Addr    ,    
       IP2Bus_Mst_Length          =>  IP2Bus_Mst_Length  ,    
       IP2Bus_Mst_BE              =>  IP2Bus_Mst_BE      ,         
       IP2Bus_Mst_Type            =>  IP2Bus_Mst_Type    ,    
       IP2Bus_Mst_Lock            =>  IP2Bus_Mst_Lock    ,    
       --IP2Bus_Mst_Reset           =>  IP2Bus_Mst_Reset   ,    
       
     -- IP Master Primary Read Request Status Reply
       Bus2IP_Mst_CmdAck          =>  Bus2IP_Mst_CmdAck       ,    
       Bus2IP_Mst_Cmplt           =>  Bus2IP_Mst_Cmplt        ,    
       Bus2IP_Mst_Error           =>  Bus2IP_Mst_Error        ,    
       Bus2IP_Mst_Rearbitrate     =>  Bus2IP_Mst_Rearbitrate  ,    
       Bus2IP_Mst_Cmd_Timeout     =>  Bus2IP_Mst_Cmd_Timeout  ,    
     
     
     -- Read LocalLink Backend Control  
       Rd_PLB2LL_Init             =>  sig_rd_plb2ll_init      ,                                    
       Rd_PLB2LL_Activate         =>  sig_rd_plb2ll_activate  ,                                    
       Rd_PLB2LL_Src_Dsc          =>  sig_rd_plb2ll_src_dsc   ,                                    
       Rd_LL2PLB_Rdy              =>  sig_rd_ll2plb_rdy       ,                                    
       Rd_LL2PLB_Done             =>  sig_rd_ll2plb_done      ,                                    
       Rd_LL2PLB_Dest_Dsc         =>  sig_rd_ll2plb_dest_dsc  ,                                    
                                                                                  
                                                                                      
     -- Read LLink Flow Control
       Rd_LL2PLB_FIFO_Full        =>  sig_ll2plb_fifo_full        ,  
       Rd_LL2PLB_FIFO_Almost_Full =>  sig_ll2plb_fifo_almost_full ,  
                                                                              
                                                                                           
     -- Read LocalLink Backend Data  
       Rd_PLB2LL_Fifo_Wen         =>  sig_rd_plb2ll_fifo_wen  ,    
       Rd_PLB2LL_Fifo_Sop         =>  sig_rd_plb2ll_fifo_sop  ,    
       Rd_PLB2LL_Fifo_Eop         =>  sig_rd_plb2ll_fifo_eop  ,    
       Rd_PLB2LL_Fifo_Rem         =>  sig_rd_plb2ll_fifo_rem  ,    
       Rd_PLB2LL_Fifo_Data        =>  sig_rd_plb2ll_fifo_data ,    
      
      
       
     -- Write LocalLink Backend Control  
       Wr_PLB2LL_Init             =>  sig_wr_plb2ll_init           ,    
       Wr_PLB2LL_Activate         =>  sig_wr_plb2ll_activate       ,    
       Wr_PLB2LL_Dst_Dsc          =>  sig_wr_plb2ll_dst_dsc        ,    
       Wr_LL2PLB_Rdy              =>  sig_wr_ll2plb_rdy            ,    
       Wr_LL2PLB_Done             =>  sig_wr_ll2plb_done           ,    
       Wr_LL2PLB_Src_Dsc_Rcvd     =>  sig_wr_ll2plb_src_dsc_rcvd   ,    
       
     -- Write LocalLink Backend Data  
       Wr_PLB2LL_Clr_Data_Valid   =>  sig_wr_plb2ll_clr_data_valid ,    
       Wr_PLB2LL_Fifo_Ren         =>  sig_wr_plb2ll_fifo_ren       ,    
       Wr_LL2PLB_Fifo_Sof         =>  sig_wr_ll2plb_fifo_sof       ,    
       Wr_LL2PLB_Fifo_Eof         =>  sig_wr_ll2plb_fifo_eof       ,    
       Wr_LL2PLB_Fifo_Sop         =>  sig_wr_ll2plb_fifo_sop       ,    
       Wr_LL2PLB_Fifo_Eop         =>  sig_wr_ll2plb_fifo_eop       ,    
       Wr_LL2PLB_Fifo_Rem         =>  sig_wr_ll2plb_fifo_rem       ,    
       Wr_LL2PLB_Fifo_Data        =>  sig_wr_ll2plb_fifo_data      ,    
       Wr_LL2PLB_Rddata_Valid     =>  sig_wr_ll2plb_rddata_valid        
      
       );
   
   
    
    
    
      
           
   
   
          
    ------------------------------------------------------------
    -- Instance: I_RD_LLINK 
    --
    -- Description:
    --     This is the instantiation for the read LocalLink
    -- backend block. This version is for fifos omitted.
    --
    ------------------------------------------------------------
     I_RD_LLINK : entity plbv46_master_burst_v1_00_a.llink_rd_backend_no_fifo
     generic map (
       C_PLB_DWIDTH              =>  LLINK_DWIDTH ,    
       C_SG_IS_PRESENT           =>  0            ,    
       C_RD_HDR_SIZE_BYTES       =>  0            ,    
       C_RD_FTR_SIZE_BYTES       =>  0            ,    
       --C_REM_CODING              =>  LLINK_REM_CODING ,    
       C_REM_WIDTH               =>  LLINK_REM_WIDTH  ,    
       C_REM_POLARITY            =>  0            , -- always active low
       C_DISREGARD_VACANCY       =>  True         ,    
       C_RDFIFO_VACANCY_WIDTH    =>  1            ,    
       C_FAMILY                  =>  C_FAMILY          
       )
     port map (
    -- System Inputs
    -- (syncronous to Bus_clk)
       Bus_Clk                   =>  MPLB_Clk ,    
       Bus_Rst                   =>  sig_composite_rst ,    
       Bus_Freeze                =>  LOGIC_LOW,    
                                                            
    -- LL FIFO Write Inputs from PLB Read Master                                
    -- (syncronous to Bus_clk)                              
       PLB2LL_FIFO_WEN           =>  sig_rd_plb2ll_fifo_wen ,    
       PLB2LL_FIFO_SOP           =>  sig_rd_plb2ll_fifo_sop ,    
       PLB2LL_FIFO_EOP           =>  sig_rd_plb2ll_fifo_eop ,    
       PLB2LL_FIFO_REM           =>  sig_rd_plb2ll_fifo_rem ,    
       PLB2LL_FIFO_Data          =>  sig_rd_plb2ll_fifo_data,    
       
    -- LL FIFO Write Inputs from Scatter Gather Service                                
    -- (syncronous to Bus_clk)                              
       SG2LL_FIFO_WEN            =>  LOGIC_LOW        ,    
       SG2LL_FIFO_SOF            =>  LOGIC_LOW        ,    
       SG2LL_FIFO_EOF            =>  LOGIC_LOW        ,    
       SG2LL_FIFO_REM            =>  REM_LOGIC_LOW    ,    
       SG2LL_FIFO_Data           =>  LLINK_D_LOGIC_LOW,    
       
    
    -- LL FIFO Write Status
    -- (syncronous to Bus_clk)
       LL2PLB_FIFO_Almost_full   =>  sig_ll2plb_fifo_almost_full,    
       LL2PLB_FIFO_Full          =>  sig_ll2plb_fifo_full       ,    
       LL2PLB_FIFO_Wr_Vacancy    =>  open,    
       
    -- PLB Read Controller interface inputs
    -- (syncronous to Bus_clk)
       PLB2LL_Init               =>  sig_rd_plb2ll_init    ,    
       PLB2LL_Activate           =>  sig_rd_plb2ll_activate,    
       PLB2LL_Src_Dsc            =>  sig_rd_plb2ll_src_dsc ,    
       PLB2LL_HdrFtr_Sel         =>  LOGIC_LOW             ,    
    
    -- PLB Read Controller interface Outputs
    -- (syncronous to Bus_clk)
       LL2PLB_Rdy                =>  sig_rd_ll2plb_rdy     ,    
       LL2PLB_Done               =>  sig_rd_ll2plb_done    ,    
       LL2PLB_Dest_Dsc           =>  sig_rd_ll2plb_dest_dsc,    
       
    -- Local Link Data Destination Interface Inputs
    -- (must be syncronous to Bus_clk for this version)
       IP2Bus_MstRd_dst_rdy_n    =>  IP2Bus_MstRd_dst_rdy_n ,    
       IP2Bus_MstRd_dst_dsc_n    =>  IP2Bus_MstRd_dst_dsc_n ,    
    
    -- Local Link Source Interface Outputs
    -- (syncronous to Bus_clk for this version)
       Bus2IP_MstRd_sof_n        =>  Bus2IP_MstRd_sof_n    ,    
       Bus2IP_MstRd_eof_n        =>  Bus2IP_MstRd_eof_n    ,    
       Bus2IP_MstRd_eop_n        =>  open                  ,    
       Bus2IP_MstRd_sop_n        =>  open                  ,    
       Bus2IP_MstRd_rem          =>  sig_rd_rem_internal   ,    
       Bus2IP_MstRd_d            =>  Bus2IP_MstRd_d        ,    
       Bus2IP_MstRd_src_rdy_n    =>  Bus2IP_MstRd_src_rdy_n,    
       Bus2IP_MstRd_src_dsc_n    =>  Bus2IP_MstRd_src_dsc_n,    
       
     
     -- User IP RdFIFO Vacancy Status  
     -- (syncronous to Bus_clk for this version and sourced by the IP)
       IP2Bus_MstRd_Vacancy      =>  RDFIFO_VACANCY_LOW    
     
       );
   
    
                

     
     ------------------------------------------------------------
     -- Instance: I_WR_LLINK 
     --
     -- Description:
     --     This is the instantiation for the write LocalLink
     -- backend block. This version is for fifos omitted.
     --
     ------------------------------------------------------------
     I_WR_LLINK : entity plbv46_master_burst_v1_00_a.llink_wr_backend_no_fifo
     generic map (
        C_PLB_DWIDTH             =>  LLINK_DWIDTH      ,    
        C_SG_IS_PRESENT          =>  0                 ,    
        C_WR_HDR_SIZE_BYTES      =>  0                 ,    
        C_WR_FTR_SIZE_BYTES      =>  0                 ,    
        --C_REM_CODING             =>  LLINK_REM_CODING  ,    
        C_REM_WIDTH              =>  LLINK_REM_WIDTH   ,    
        C_REM_POLARITY           =>  0                 , -- active low   
        C_DISREGARD_OCCUPANCY    =>  True              ,    
        C_WRFIFO_OCCUPANCY_WIDTH =>  1                 ,    
        C_FAMILY                 =>  C_FAMILY               
       )
     port map (
        -- System Inputs
        -- (syncronous to Bus_clk)
           Bus_Clk                   =>  MPLB_Clk ,    
           Bus_Rst                   =>  sig_composite_rst ,    
           Bus_Freeze                =>  LOGIC_LOW,    
        
        -- LL FIFO Read I/O with Write Master
        -- (syncronous to Bus_clk)
           PLB2LL_Clr_Data_Valid     =>  sig_wr_plb2ll_clr_data_valid ,    
           PLB2LL_FIFO_REN           =>  sig_wr_plb2ll_fifo_ren       ,    
           LL2PLB_FIFO_SOF           =>  sig_wr_ll2plb_fifo_sof       ,    
           LL2PLB_FIFO_EOF           =>  sig_wr_ll2plb_fifo_eof       ,    
           LL2PLB_FIFO_SOP           =>  sig_wr_ll2plb_fifo_sop       ,    
           LL2PLB_FIFO_EOP           =>  sig_wr_ll2plb_fifo_eop       ,    
           LL2PLB_FIFO_REM           =>  sig_wr_ll2plb_fifo_rem       ,    
           LL2PLB_FIFO_Data          =>  sig_wr_ll2plb_fifo_data      ,    
           LL2PLB_RdData_Valid       =>  sig_wr_ll2plb_rddata_valid   ,    
    
        -- LL FIFO Read I/O with Scatter Gather Service
        -- (syncronous to Bus_clk)
           SG2LL_FIFO_REN            =>  LOGIC_LOW    ,    
        
        -- LL FIFO Read Status
        -- (syncronous to Bus_clk)
           LL2PLB_FIFO_Almost_Empty  =>  open     ,    
           LL2PLB_FIFO_Empty         =>  open     ,    
           LL2PLB_WRFIFO_Occupancy   =>  open     ,    
           
        -- PLB Write Controller inputs
        -- (syncronous to Bus_clk)
           PLB2LL_Init               =>  sig_wr_plb2ll_init       ,    
           PLB2LL_Activate           =>  sig_wr_plb2ll_activate   ,    
           PLB2LL_Dst_Dsc            =>  sig_wr_plb2ll_dst_dsc    ,    
           PLB2LL_Rdy_For_Ftr        =>  LOGIC_LOW                ,    
           PLB2LL_HdrFtr_Sel         =>  LOGIC_LOW                ,    
        
        -- Status Outputs to PLB Write Controller 
        -- (syncronous to Bus_clk)
           LL2PLB_Rdy                =>  sig_wr_ll2plb_rdy         ,    
           LL2PLB_Done               =>  sig_wr_ll2plb_done        ,    
           LL2PLB_Src_Dsc_Rcvd       =>  sig_wr_ll2plb_src_dsc_rcvd,    
           LL2PLB_SOF_Rcvd           =>  open,    
           LL2PLB_EOF_Rcvd           =>  open,    
           LL2PLB_SOP_Rcvd           =>  open,    
           LL2PLB_EOP_Rcvd           =>  open,    
           LL2PLB_MSWS               =>  open,    
           LL2PLB_MEWS               =>  open,    
           
        -- Local Link Data Destination Interface Outputs
        -- (syncronous to Bus_clk for this version)
           Bus2IP_MstWr_dst_rdy_n    =>  Bus2IP_MstWr_dst_rdy_n,    
           Bus2IP_MstWr_dst_dsc_n    =>  Bus2IP_MstWr_dst_dsc_n,    
        
        -- Local Link Source Interface inputs
        -- (syncronous to Bus_clk for this version)
           IP2Bus_MstWr_sof_n        =>  IP2Bus_MstWr_sof_n    ,    
           IP2Bus_MstWr_eof_n        =>  IP2Bus_MstWr_eof_n    ,    
           IP2Bus_MstWr_sop_n        =>  LOGIC_HIGH            ,    
           IP2Bus_MstWr_eop_n        =>  LOGIC_HIGH            ,    
           IP2Bus_MstWr_rem          =>  sig_wr_rem_internal   ,    
           IP2Bus_MstWr_d            =>  IP2Bus_MstWr_d        ,    
           IP2Bus_MstWr_src_rdy_n    =>  IP2Bus_MstWr_src_rdy_n,    
           IP2Bus_MstWr_src_dsc_n    =>  IP2Bus_MstWr_src_dsc_n,    
           
         
         -- WrFIFO Occupancy Status  
        -- (syncronous to Bus_clk for this version)
           IP2Bus_MstWr_Occupancy    =>  WRFIFO_OCCUPANCY_LOW                   
       );



    

end implementation;
