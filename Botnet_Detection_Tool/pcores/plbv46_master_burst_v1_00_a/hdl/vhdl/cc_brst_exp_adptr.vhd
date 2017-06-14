      -------------------------------------------------------------------------------
      -- $Id: cc_brst_exp_adptr.vhd,v 1.2 2007/01/15 19:24:38 dougt Exp $
      -------------------------------------------------------------------------------
      -- cc_brst_exp_adptr.vhd
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
      -- Filename:        cc_brst_exp_adptr.vhd
      --
      -- Description:     
      -- This VHDL design is used in conjunction with a PLBV46 Master IPIF. It is                  
      -- needed when the Master is transfering to/from a Target Slave that has a 
      -- narrower data width than the Master. The fundamental requirement of the
      -- design is to support a "bolt on" type connection for the PLB Master IPIF
      -- modules. This approach supports a parameterizable inclusion/omission of
      -- the function without major redesign to the PLB Master IPIF designs.
      -- 
      -- Special Note:
      -- The design of this module assumes that it will be instantiated in a 
      -- top level Host file only if it is required. Otherwise it will be   
      -- omitted from the Host file. This assumption precludes the need for 
      -- parameterization implementation within this design to omit or include
      -- the Conversion Cycle functionality (it is always included in this 
      -- module). Burst Length Expansion is included/omitted within this design
      -- depending on whether Burst Support is enabled via the
      -- C_SUPPORT_BURSTS parameter.
      --
      --
      --
      -- Fixed length Bursts to/from a narrower Slave:
      --     In the Burst scenario, the number of data beats required for 
      -- completion of the burst is going to be 2x or 4x the actual explicity  
      -- requested data beat count.
      -- 
      --
      --   Master Size     Slave Size       Data Beat expansion Factor
      --   -----------     ----------       --------------------------
      --      32            32/64/128              1x
      --      64               32                  2x
      --      64             64/128                1x
      --     128               32                  4x
      --     128               64                  2x
      --     128              128                  1x
      --
      -- This design 'tricks' the requesting Master by passing only every 
      -- second or every fourth data acknowledge during the burst expansion
      -- case. In addition to this, the design also incorporates a register
      -- used for Read data capture. The register is partially populated   
      -- with Read data from the Slave based on the width of the Slave. When 
      -- the register has been filled, the Read Dack is relayed back to the 
      -- Master Read Logic along with the full width data value. 
      --              
      --                  
      -- Conversion Cycles:
      --    Conversion Cycles are required to complete single data beat transfers
      -- if the asserted BEs for the transfer cross the native data width 
      -- boundary of the target Slave device. This design "tricks" the Master
      -- logic by witholding the Data Acks from the Master logic if Conversion 
      -- Cycles are required. The design then generates the required Conversion 
      -- Cycle requests (and associated qualifiers) to completed the requested 
      -- transfer. Upon completion, the Data Ack is relayed to the Master logic 
      -- indicating completion. On Read Conversion Cycles, the Read Data Register
      -- is used to hold intermediate read data values from the Slave until all
      -- of the requested read data is captured in the register.
      -- Note on Conversio Cycles:
      -- A PLB_Timeout assertion during a Conversion Cycle address phase results 
      -- in the associated Merr assertion to the Master logic (not a timeout).
      --  
      --
      --
      --
      --                  
      -- VHDL-Standard:   VHDL'93
      -------------------------------------------------------------------------------
      -- Structure:   
      --              cc_brst_exp_adptr.vhd
      --
      -------------------------------------------------------------------------------
      -- Revision History:
      --
      --
      -- Author:          DET
      -- Revision:        $$
      -- Date:            $$
      --
      -- History:
      --   DET   11/29/2006       Initial Version
      --                      
      --     DET     1/15/2007     Initial
      -- ~~~~~~
      --     - Corrected byte address counter width sizing issue to account  
      --       for a post increment operation at the end of a FLBurst 16.
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
      use IEEE.std_logic_arith.all;
      use IEEE.std_logic_unsigned.all;
      
      
      
      library proc_common_v2_00_a; 
      use proc_common_v2_00_a.proc_common_pkg.log2;  
      
      
      library unisim; -- Required for Xilinx primitives
      use unisim.all;  
      
      
      -------------------------------------------------------------------------------
      
      entity cc_brst_exp_adptr is
        generic (
          C_NATIVE_DWIDTH    : Integer range 32 to 128 := 128;
          C_AWIDTH           : Integer range 32 to  36 := 32 ;
          C_SUPPORT_BURSTS   : Integer range  0 to   1 :=  1 ;
          C_STEER_ADDR_WIDTH : Integer range  1 to   4 :=  4
          );
        port (
        
          -- System Inputs
          Bus_Clk              : In std_logic;
          Bus_Rst              : In std_logic;
        
         -- Request and Qualifiers from Master Logic
          Mst_Req_in           : In std_logic;
          Mst_Priority_in      : In std_logic_vector(0 to 1);
          Mst_Buslock_in       : In std_logic;
          Mst_RNW_in           : in std_logic;
          Mst_BE_in            : In std_logic_vector(0 to 
                                    (C_NATIVE_DWIDTH/8)-1);
          Mst_MSize_in         : In std_logic_vector(0 to 1);
          Mst_Size_in          : In std_logic_vector(0 to 3);
          Mst_Type_in          : In std_logic_vector(0 to 2);
          Mst_Addr_in          : in std_logic_vector(0 to 
                                    C_AWIDTH-1);
          Mst_WrBurst_in       : In std_logic;
          Mst_RdBurst_in       : In std_logic;
          Mst_WrDBus_in        : In std_logic_vector(0 to 
                                    C_NATIVE_DWIDTH-1);
          
         -- Write DBus Steering address input
          Mst_Steer_Addr_in    : in std_logic_vector(0 to 
                                    C_STEER_ADDR_WIDTH-1);
                   
         -- PLB Reply (inputs)
          PLB_MAddrAck         : in  std_logic;
          PLB_MSSize           : in  std_logic_vector(0 to 1);
          PLB_MRearbitrate     : in  std_logic;
          PLB_MTimeout         : in  std_logic;
          PLB_MBusy            : In  std_logic;
          PLB_MRdErr           : in  std_logic;
          PLB_MWrErr           : in  std_logic;
          PLB_MRdDBus          : in  std_logic_vector(0 to 
                                     C_NATIVE_DWIDTH-1);
          PLB_MRdDAck          : in  std_logic;
          PLB_MRdBTerm         : in  std_logic;
          PLB_MWrDAck          : in  std_logic;
          PLB_MWrBTerm         : in  std_logic;
       
          
         -- Reply Output to Master
          To_Mstr_MAddrAck     : out std_logic;
          To_Mstr_MSSize       : out std_logic_vector(0 to 1);
          To_Mstr_MRearbitrate : out std_logic;
          To_Mstr_MTimeout     : out std_logic;
          To_Mstr_MBusy        : out std_logic;
          To_Mstr_MRdErr       : out std_logic;
          To_Mstr_MWrErr       : out std_logic;
          To_Mstr_MRdDBus      : out std_logic_vector(0 to 
                                     C_NATIVE_DWIDTH-1);
          To_Mstr_MRdDAck      : out std_logic;
          To_Mstr_MRdBTerm     : out std_logic;
          To_Mstr_MWrDAck      : out std_logic;
          To_Mstr_MWrBTerm     : out std_logic;
       
          
          
         -- Steer Address to Write Data bus steering logic 
          To_Mstr_Wr_Steer_Addr : Out std_logic_vector(0 to 
                                      C_STEER_ADDR_WIDTH-1);
          
          
          -- Outputs to PLB
          M_request_out        : out std_logic;
          M_priority_out       : out std_logic_vector(0 to 1);
          M_busLock_out        : out std_logic;
          M_RNW_out            : out std_logic;
          M_BE_out             : out std_logic_vector(0 to 
                                     (C_NATIVE_DWIDTH/8)-1);
          M_MSize_out          : out std_logic_vector(0 to 1);
          M_size_out           : out std_logic_vector(0 to 3);
          M_type_out           : out std_logic_vector(0 to 2);
          M_ABus_out           : out std_logic_vector(0 to 31);
          M_wrBurst_out        : out std_logic;
          M_rdBurst_out        : out std_logic;
          M_wrDBus_out         : out std_logic_vector(0 to 
                                     C_NATIVE_DWIDTH-1)
          
         );
      
      end entity cc_brst_exp_adptr;
      
      
      architecture implementation of cc_brst_exp_adptr is
      
          
          
        -- Constant Declarations  
         Constant NUM_BYTE_LANES   : integer := C_NATIVE_DWIDTH/8;
         Constant NUM_LS_ADDR_BITS : natural := log2(C_NATIVE_DWIDTH/8);
         
         Constant BE_WIDTH         : natural := C_NATIVE_DWIDTH/8;
         
         Constant MAX_BRST_DBEATS  : natural := 16;
         
         Constant NUM_BYTES_PER_DBEAT : natural := C_NATIVE_DWIDTH/8;
         
         Constant MAX_BRST_BYTES_XFERED  : natural := MAX_BRST_DBEATS*NUM_BYTES_PER_DBEAT;
         
         Constant MAX_ADDR_INCR_PER_DBEAT  : natural := 16; -- (128/8) in Byte Addressing
         
         Constant BYTE_ADDR_WIDTH     : natural := log2(MAX_BRST_BYTES_XFERED);
         
         Constant BYTE_ADDR_CNTR_SIZE : natural := MAX_BRST_BYTES_XFERED +
                                                   MAX_ADDR_INCR_PER_DBEAT; -- allows for 1 post increment
                                                                            -- without overflow
          
          
        -- Type Declarations
         Type byte_reg_type is array(0 to (C_NATIVE_DWIDTH/8)-1) of 
                                   std_logic_vector(0 to 7);
         
          
        -- Burst Length Expansion Signals
         signal sig_s_h_enable          : std_logic;
         Signal sig_m_req_reg           : std_logic;
         signal sig_m_size_reg          : std_logic_vector(0 to 3);
         signal sig_req_is_burst        : std_logic;
         signal rd_data_reg             : byte_reg_type;
         signal rd_data_reg_slv         : std_logic_vector(0 to 
                                          C_NATIVE_DWIDTH-1);
         
         signal sig_byte_addr           : std_logic_vector(0 to 
                                          BYTE_ADDR_WIDTH);
         signal sig_byte_addr_int       : integer range 0 to 
                                          BYTE_ADDR_CNTR_SIZE := 0;
         Signal sig_byte_addr_incr      : integer range 0 to 
                                          MAX_ADDR_INCR_PER_DBEAT := 0;
         Signal sig_byte_addr_incr_reg  : integer range 0 to 
                                          MAX_ADDR_INCR_PER_DBEAT := 0;
         Signal sig_byte_addr_incr_value: integer range 0 to 
                                          MAX_ADDR_INCR_PER_DBEAT := 0;
         
         
         Signal sig_ssize_reg           : std_logic_vector(0 to 1);
         Signal sig_ssize_value         : std_logic_vector(0 to 1);
         Signal sig_xfer_cmplt          : std_logic;
         Signal sig_ble_rddack_to_mstr  : std_logic;
         Signal sig_ble_wrdack_to_mstr  : std_logic;
         signal sig_ld_en_vec           : std_logic_vector(0 to 
                                          NUM_BYTE_LANES-1);
         Signal sig_segment_xfer_done   : std_logic;
         signal sig_rnw_reg             : std_logic;
         signal sig_addrack_cmplt       : std_logic;
         signal sig_wrburst_reg         : std_logic;
         signal sig_rdburst_reg         : std_logic;
         signal sig_rd_error_reg        : std_logic;
         signal sig_wr_error_reg        : std_logic;
         signal sig_rdbterm             : std_logic;
         signal sig_wrbterm             : std_logic;
         signal sig_inc_test_value      : std_logic_vector(0 to 3);
          
         Signal rd_data_reg_load        : std_logic_vector(0 to 
                                          NUM_BYTE_LANES-1);
         
         
         Signal rd_data_reg_ld_composite   : std_logic_vector(0 to 
                                             NUM_BYTE_LANES-1);
         
         
       -- Conversion Cycle signals
         signal sig_need_conv_cycle     : std_logic;
         
         signal sig_need_conv_cycle_reg : std_logic;
         
         signal sig_cc_next_be          : std_logic_vector(0 to 
                                         (C_NATIVE_DWIDTH/8)-1);
         signal sig_cc_next_addr        : std_logic_vector(0 to 
                                         C_AWIDTH-1);
         signal sig_cc_next_size        : std_logic_vector(0 to 3);
                                         
         signal sig_cc_next_rnw         : std_logic;
         
         signal sig_cc_next_msize       : std_logic_vector(0 to 1);
          
         signal sig_cc_next_priority    : std_logic_vector(0 to 1);
      
         -- signal sig_mstr_req_reg        : std_logic;
         
         --signal sig_s_h_enable          : std_logic;
         
         signal sig_address_reg         : std_logic_vector(0 to 
                                          C_AWIDTH-1);
         
         signal sig_be_reg              : std_logic_vector(0 to 
                                          (C_NATIVE_DWIDTH/8)-1);
         
         signal sig_be_clr_vec          : std_logic_vector(0 to 
                                          (C_NATIVE_DWIDTH/8)-1);
         
         signal sig_be_clr_vec_and      : std_logic_vector(0 to 
                                          (C_NATIVE_DWIDTH/8)-1);
                 
         signal sig_be_still_set        : std_logic;
         
         signal sig_next_addr_ls        : std_logic_vector(0 to 
                                          NUM_LS_ADDR_BITS-1);
         
         signal sig_next_addr_ls_reg    : std_logic_vector(0 to 
                                          NUM_LS_ADDR_BITS-1);
         
         
         --signal sig_rnw_reg             : std_logic;
                              
         signal sig_msize_reg           : std_logic_vector(0 to 1);
                              
         signal sig_parent_addrack_cmplt : std_logic;
         
         Signal sig_combined_ack         : std_logic;
         
         Signal sig_cc_xfer_cmplt        : std_logic;
         
         --signal sig_dack_rcvd            : std_logic;
         
         Signal sig_composite_wrack      : std_logic;
           
         signal sig_composite_rdack      : std_logic;
         
         signal sig_cc_rddack_to_mstr    : std_logic;
         
         signal sig_cc_steer_addr        : std_logic_vector(0 to 
                                           C_STEER_ADDR_WIDTH-1);
       
         signal sig_first_wrdack_cmplt   : std_logic;
        
         signal sig_cc_mbusy_reg         : std_logic;
         
         signal sig_rd_mbusy_reg         : std_logic;
        
        
                            
                            
        begin --(architecture implementation)
        
         
          
         -- Pass through connections
          To_Mstr_MSSize   <=  PLB_MSSize;
          
          M_busLock_out    <=  Mst_Buslock_in; -- direct assignment
          M_type_out       <=  "000";        -- always memory type
          M_wrDBus_out     <=  Mst_WrDBus_in;  -- direct assignment
         
         
         
         -- Conversion Cycle Muxing and Port Connections 
         -- for output to PLB
         
          M_request_out <= Mst_Req_in or
                           sig_need_conv_cycle_reg;
          
          M_BE_out      <= sig_cc_next_be 
            When sig_need_conv_cycle_reg = '1'
            Else Mst_BE_in;
          
          M_ABus_out    <= sig_cc_next_addr
            When sig_need_conv_cycle_reg = '1'
            else Mst_Addr_in;
          
          M_size_out    <= sig_cc_next_size
            when sig_need_conv_cycle_reg = '1'
            Else Mst_Size_in;
        
          M_RNW_out     <= sig_cc_next_rnw 
            When sig_need_conv_cycle_reg = '1'
            Else Mst_RNW_in;
         
          M_MSize_out   <= sig_cc_next_msize 
            When sig_need_conv_cycle_reg = '1'
            Else Mst_MSize_in;
         
          M_priority_out   <= sig_cc_next_priority 
            When sig_need_conv_cycle_reg = '1'
            Else Mst_Priority_in;
         
         
         -- Conversion Cycle Muxing and Port Connections 
         -- for output to Master Logic
         
          To_Mstr_MAddrAck <= '0'
             when (sig_parent_addrack_cmplt = '1' and
                  sig_req_is_burst = '0')
             Else PLB_MAddrAck;
         
           To_Mstr_MRearbitrate  <= '0'
             when (sig_parent_addrack_cmplt = '1' and
                  sig_req_is_burst = '0')
             Else PLB_MRearbitrate;
         
           To_Mstr_MTimeout  <= '0'
             when (sig_parent_addrack_cmplt = '1' and
                   sig_req_is_burst = '0')
             Else PLB_MTimeout;
         
           -- To_Mstr_Wr_Steer_Addr <= sig_cc_steer_addr
           --   when (sig_req_is_burst = '0')
           --   Else sig_byte_addr;
          
           To_Mstr_Wr_Steer_Addr <= Mst_Steer_Addr_in
             When sig_first_wrdack_cmplt = '0'
             else sig_cc_steer_addr
             when (sig_req_is_burst = '0')
             Else sig_byte_addr(BYTE_ADDR_WIDTH-(C_STEER_ADDR_WIDTH-1) to 
                                BYTE_ADDR_WIDTH);
          
          
          -- To_Mstr_MBusy    <=  sig_cc_mbusy_reg; 
          --    when (sig_parent_addrack_cmplt = '1' and
          --         sig_req_is_burst = '0')
          --    Else PLB_MBusy;
       
          
          To_Mstr_MBusy  <= sig_rd_mbusy_reg or
                            sig_cc_mbusy_reg or 
                            PLB_MBusy;          
         
         
         
         
          
         -- Burst Length Expansion port assignements
             
          To_Mstr_MRdDAck       <=  sig_composite_rdack;
          To_Mstr_MRdErr        <=  sig_rd_error_reg;
          To_Mstr_MRdDBus       <=  rd_data_reg_slv;
          To_Mstr_MRdBTerm      <=  sig_rdbterm;
 
          To_Mstr_MWrDAck       <=  sig_composite_wrack;
          To_Mstr_MWrErr        <=  sig_wr_error_reg or
                                    PLB_MWrErr;
          To_Mstr_MWrBTerm      <=  sig_wrbterm;
          
          
          M_wrBurst_out         <=  sig_wrburst_reg or
                                    Mst_WrBurst_in;
                                    
          M_rdBurst_out         <=  sig_rdburst_reg;
 
          
          sig_wrbterm           <=  PLB_MWrBTerm;
          
    
       
       
       
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    --
    -- Common Logic
    --
    -----------------------------------------------------------
    -----------------------------------------------------------
   
          sig_xfer_cmplt <= '1'
            When  (sig_composite_rdack = '1'  and
                   Mst_RdBurst_in      = '0') or
                  (sig_composite_wrack = '1'  and
                   Mst_WrBurst_in      = '0')
            Else '0';
         
         
         
          
          
          
       -- Both Conv Cycles and BLE must control Data AcksAck   
          sig_composite_wrack  <=  sig_ble_wrdack_to_mstr 
             when sig_req_is_burst = '1'
             Else PLB_MWrDack and not(sig_need_conv_cycle);
          
          
           sig_composite_rdack  <=  sig_ble_rddack_to_mstr
             when sig_req_is_burst = '1'
             Else sig_cc_rddack_to_mstr;
          
          
        
        
          
    
    
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_RD_ERROR_DETECT
        --
        -- Process Description:
        -- This process implements a register for capturing the 
        -- occurance of an error during a Read transfer. The error
        -- is registered and held until the corresponding rdack is
        -- sent to the Master.
        --  
        -------------------------------------------------------------
        GEN_RD_ERROR_DETECT : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
               if (Bus_Rst        = '1' or
                   sig_xfer_cmplt = '1' or
                   sig_rnw_reg    = '0') then
                 
                 sig_rd_error_reg <= '0';
               
               elsif (--sig_req_is_burst  = '1' and
                      PLB_MRdDack       = '1' and
                      PLB_MRdErr        = '1') then
                 
                 sig_rd_error_reg <= '1';
              
               Elsif (sig_composite_rdack = '1') Then
               
                 sig_rd_error_reg <= '0';
                 
               else
                 null;  -- hold current state
               end if; 
            end if;       
          end process GEN_RD_ERROR_DETECT; 
       
        
                       
                       
                       
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_WR_ERROR_DETECT
        --
        -- Process Description:
        -- This process implements a register for capturing the 
        -- occurance of an error during a Write transfer. The error
        -- is registered and held until the corresponding wrack is
        -- sent to the Master.
        --
        -------------------------------------------------------------
        GEN_WR_ERROR_DETECT : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
               if (Bus_Rst        = '1' or
                   sig_xfer_cmplt = '1' or
                   sig_rnw_reg    = '1') then
                 
                 sig_wr_error_reg <= '0';
               
               elsif (--sig_req_is_burst = '1' and
                      PLB_MWrDack       = '1' and
                      PLB_MWrErr        = '1') then
                 
                 sig_wr_error_reg <= '1';
               
               Elsif (sig_composite_wrack = '1') Then
               
                 sig_wr_error_reg <= '0';
               
               else
                 null;  -- hold current state
               end if; 
            end if;       
          end process GEN_WR_ERROR_DETECT; 
        
           
          
          
    
    
         
         ------------------------------------------------------------
         -- For Generate
         --
         -- Label: GEN_RDDREG
         --
         -- For Generate Description:
         --  The ForGen implements the Byte wide register segments
         -- of the RDDREG. The RDDREG collects the input read data
         -- from the PLB during burst length expansion operations and
         -- Conversion Cycles.  Burst Length Expansion and Conversion
         -- Cycles may be required when a Master accesses a PLB Slave 
         -- that is narrower than the requested data transfer size 
         -- requested by the Master. The RDDREG is loaded in units of
         -- the Slave's width until it is filled. The register data 
         -- is then sent on to the Master's read logic in one data beat.
         --
         ------------------------------------------------------------
         GEN_RDDREG : for reg_byte_index in 0 to NUM_BYTE_LANES-1 generate
            
            -- local signals
            Signal rd_data_reg_clear       : std_logic;
            
           begin
          
             rd_data_reg_clear <= Bus_Rst or
                                  not(sig_rnw_reg);
            
             
             
             rd_data_reg_ld_composite(reg_byte_index) <=  
                                  sig_ld_en_vec(reg_byte_index)
                When (sig_req_is_burst = '1')
                Else sig_be_reg(reg_byte_index);
             
             
             rd_data_reg_load(reg_byte_index) <= PLB_MRdDack and
                                 rd_data_reg_ld_composite(reg_byte_index); 
              
               
             
             -------------------------------------------------------------
             -- Synchronous Process with Sync Reset
             --
             -- Label: RDDREG_BYTE_SEGMENT
             --
             -- Process Description:
             -- This synchronous process implements a single byte wide
             -- register segment of the RDDREG.
             --
             -------------------------------------------------------------
             RDDREG_BYTE_SEGMENT : process (bus_clk)
                begin
                  if (Bus_Clk'event and Bus_Clk = '1') then
                    if (rd_data_reg_clear = '1') then

                      rd_data_reg(reg_byte_index)  <= (others => '0');
                             
                    elsif (rd_data_reg_load(reg_byte_index) = '1') then
       
                      rd_data_reg(reg_byte_index)  <= 
                             PLB_MRdDBus((reg_byte_index*8) to 
                             (reg_byte_index*8)+7);
                             
                    else
                      null;  -- hold register value
                    end if;
                  End if;
                end process RDDREG_BYTE_SEGMENT; 
             
              
           end generate GEN_RDDREG;
         

         
         
         -------------------------------------------------------------
         -- Combinational Process
         --
         -- Label: CONVERT_RDDATA2SLV
         --
         -- Process Description:
         --  This process converts the byte sliced read register 
         -- output data to Standard Logic Vector.
         --
         -------------------------------------------------------------
         CONVERT_RDDATA2SLV : process (rd_data_reg)
           begin
        
             for i in 0 to (C_NATIVE_DWIDTH/8)-1 loop

               rd_data_reg_slv((i*8) to (i*8)+7) <= rd_data_reg(i);
                            
             End loop; 

        
           end process CONVERT_RDDATA2SLV; 
         
         
      
      
      
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_RD_MBUSY
         --
         -- Process Description:
         -- This process registers the PLB_MBusy input from the PLB
         -- to time align it with the read data that is collected in 
         -- the read data register.
         --
         -------------------------------------------------------------
         GEN_RD_MBUSY : process (bus_clk)
            begin
              if (Bus_Clk'event and Bus_Clk = '1') then
                 if (Bus_Rst = '1') then
                   sig_rd_mbusy_reg <= '0';
                 elsif (PLB_MRdDAck = '1') then
                   sig_rd_mbusy_reg <= PLB_MBusy;
                 else
                   sig_rd_mbusy_reg <= '0';
                 end if; 
              end if;       
            end process GEN_RD_MBUSY; 
      
      
      
      
      
         
                
   
           
    -----------------------------------------------------------
    -----------------------------------------------------------
    --
    -- Burst length Expansion Logic
    --
    -----------------------------------------------------------
    -----------------------------------------------------------
   
          
          
         
          sig_s_h_enable <=  Mst_Req_in and not(sig_m_req_reg);
         
         
         
          sig_byte_addr_incr_value <= sig_byte_addr_incr_reg
             when sig_addrack_cmplt = '1'
             Else sig_byte_addr_incr;
         
         
          sig_byte_addr <= CONV_STD_LOGIC_VECTOR(sig_byte_addr_int,
                                                 BYTE_ADDR_WIDTH+1);
         
         
          
          sig_ble_wrdack_to_mstr  <=  sig_segment_xfer_done  and 
                                      PLB_MWrDack;
          
   
          
          
          
          -------------------------------------------------------------
          -- Synchronous Process with Sync Reset
          --
          -- Label: REG_M_REQUEST
          --
          -- Process Description:
          -- This process registers the Master Request input.
          --
          -------------------------------------------------------------
          REG_M_REQUEST : process (bus_clk)
             begin
               if (Bus_Clk'event and Bus_Clk = '1') then
                  if (Bus_Rst = '1') then
                    sig_m_req_reg <= '0';
                  else
                    sig_m_req_reg <= Mst_Req_in;
                  end if; 
               end if;       
             end process REG_M_REQUEST; 
          
          
          
          -------------------------------------------------------------
          -- Synchronous Process with Sync Reset
          --
          -- Label: REG_REQ_TYPE
          --
          -- Process Description:
          --     This process samples and holds the indication of 
          -- a burst request.
          --
          -------------------------------------------------------------
          REG_REQ_TYPE : process (bus_clk)
             begin
               if (Bus_Clk'event and Bus_Clk = '1') then
                  if (Bus_Rst        = '1' or
                      sig_xfer_cmplt = '1') then
                    
                    sig_req_is_burst <= '0';
                  
                  elsif (Mst_Size_in(0) = '1' and
                         sig_s_h_enable = '1') then
                    
                    sig_req_is_burst <= '1';
                  
                  else
                    null; -- hold current state
                  end if; 
               end if;       
            end process REG_REQ_TYPE; 
        

         
         

         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: REG_REQ_SIZE
         --
         -- Process Description:
         --     This process samples and holds the requested transfer 
         -- width of a burst request.
         --
         -------------------------------------------------------------
         REG_REQ_SIZE : process (bus_clk)
            begin
              if (Bus_Clk'event and Bus_Clk = '1') then
                 if (Bus_Rst        = '1' or
                     sig_xfer_cmplt = '1') then
                   
                   sig_m_size_reg <= "0000";
                 
                 elsif (sig_s_h_enable = '1') then
                   
                   sig_m_size_reg <= Mst_Size_in;
                 
                 else
                   null; -- hold current state
                 end if; 
              end if;       
            end process REG_REQ_SIZE; 
        

         
         

         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: REG_RNW
         --
         -- Process Description:
         -- This process implements a sample and hold register for the
         -- M_RNW qualifier for the originating request.
         --
         -------------------------------------------------------------
         REG_RNW : process (bus_clk)
            begin
              if (Bus_Clk'event and Bus_Clk = '1') then
                 if (Bus_Rst        = '1' or
                     sig_xfer_cmplt = '1') then
                   
                   sig_rnw_reg <= '0';
                 
                 elsif (sig_s_h_enable = '1') then
                   
                   sig_rnw_reg <= Mst_RNW_in;
                 
                 else
                   null; -- hold current state
                 end if; 
              end if;       
            end process REG_RNW; 
         
         
           
         
         
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_SSIZE_REG
         --
         -- Process Description:
         -- This process registers the reported target Slave Size.
         --
         -------------------------------------------------------------
         GEN_SSIZE_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
                if (Bus_Rst = '1' or
                    sig_xfer_cmplt = '1') then
                  sig_ssize_reg <= "00";
                elsif (PLB_MAddrAck = '1') then
                  sig_ssize_reg <= PLB_MSsize;
                else
                  null;  -- hold current state
                end if; 
             end if;       
           end process GEN_SSIZE_REG; 
            
         
         
         
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_RDBURST_REG
         --
         -- Process Description:
         -- This process implements the sample and hold register for
         -- the Read Burst qualifier.
         -- 
         -- Note:  The read burst signal need not be asserted  
         -- until the receipt of Addrack, however PLB V4.6 allows it
         -- to be asserted earlier than AddrAck.
         --
         -------------------------------------------------------------
         GEN_RDBURST_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
                if (Bus_Rst        = '1' or
                    PLB_MRdBTerm   = '1' or
                    sig_xfer_cmplt = '1') then
                  sig_rdburst_reg <= '0';
                elsif (Mst_Size_in(0) = '1' and
                       Mst_RNW_in     = '1' and
                       sig_s_h_enable = '1') then
                  sig_rdburst_reg <= '1';
                else
                  null;  -- hold current state
                end if; 
             end if;       
           end process GEN_RDBURST_REG; 
            
         
         
         
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_WRBURST_REG
         --
         -- Process Description:
         -- This process implements the sample and hold register for
         -- the Write Burst qualifier from the Master.
         -- 
         --Note:   The Write burst must be asserted with the M_Request
         -- so it can be sampled during the leading edge of M_Request.
         --
         -------------------------------------------------------------
         GEN_WRBURST_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
                if (Bus_Rst        = '1' or
                    PLB_MWrBTerm   = '1' or
                    sig_xfer_cmplt = '1') then
                  sig_wrburst_reg <= '0';
                elsif (sig_s_h_enable = '1') then
                  sig_wrburst_reg <= Mst_WrBurst_in;
                else
                  null;  -- hold current state
                end if; 
             end if;       
           end process GEN_WRBURST_REG; 
            
         
         
         
          
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_RDBTERM_REG
         --
         -- Process Description:
         -- This process implements flop for registering the
         -- Read Burst termination qualifier to the Master logic.
         -- 
         -------------------------------------------------------------
         GEN_RDBTERM_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
                if (Bus_Rst        = '1') then
                  sig_rdbterm <= '0';
                else 
                  sig_rdbterm <= PLB_MRdBTerm;
                end if; 
             end if;       
           end process GEN_RDBTERM_REG; 
            
         
         
         
          
          
          
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_ADDRACK_CMPLT
        --
        -- Process Description:
        -- This process implements a sample and hold register for the
        -- address acknowledge from the PLB.
        --
        -------------------------------------------------------------
        GEN_ADDRACK_CMPLT : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
              if (Bus_Rst        = '1' or
                  sig_xfer_cmplt = '1') then
                sig_addrack_cmplt <= '0';
              elsif (PLB_MAddrAck = '1') then
                sig_addrack_cmplt <= '1';
              else
                null;  -- hold current state
              end if; 
            end if;       
          end process GEN_ADDRACK_CMPLT; 
        
        
        
        
        
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_BLE_RDACK_REG
        --
        -- Process Description:
        -- This process implements a register that generates the
        -- read data acknowledge that is sent to the Master logic.
        -- This delays the RdAck from the PLB by one clock to align
        -- it with the data that is collected and output to the
        -- Master from the Read Data Register.
        -- Both the Conversion Cycle process and the Burst Length
        -- Expansion Logic need to control the RdAck.
        -------------------------------------------------------------
        GEN_BLE_RDACK_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
               if (Bus_Rst        = '1' or
                   sig_xfer_cmplt = '1') then
                 sig_ble_rddack_to_mstr <= '0';
               else
                 sig_ble_rddack_to_mstr <= sig_segment_xfer_done and
                                           PLB_MRdDack;
               end if; 
             end if;       
           end process GEN_BLE_RDACK_REG; 
          
          
          
          
          -------------------------------------------------------------
          -- Combinational Process
          --
          -- Label: CALC_BYTE_ADDR_INCR
          --
          -- Process Description:
          -- This process calculates the required increment value for
          -- the byte address counter based on the target Slave width
          -- and the requested transfer width by the Master. The 
          -- increment value must match the lesser of the two widths.
          -- A Master cannot request a width that is wider than it's
          -- Native Data Width. It is allowed to request transfer
          -- widths less than the Native Data Width.
          -------------------------------------------------------------
          CALC_BYTE_ADDR_INCR : process (PLB_MSsize,
                                         sig_m_size_reg,
                                         sig_inc_test_value)
        
             
            begin
          
              sig_inc_test_value <= PLB_MSsize & 
                                    sig_m_size_reg(2 to 3);
                                    
             
              
              case sig_inc_test_value is
                
                ----------------------------
                when "0000" =>  -- Slave is 32 bits, req is quad-wrd
                ----------------------------
                
                  sig_byte_addr_incr <= 4;
                
                ----------------------------
                when "0010" =>  -- Slave is 32 bits, req is word
                ----------------------------
                
                  sig_byte_addr_incr <= 4;
                
                ----------------------------
                when "0011" =>  -- Slave is 32 bits, req is dbl-word
                ----------------------------
                
                  sig_byte_addr_incr <= 4;
                
                
                
                
                ----------------------------
                when "0100" =>  -- Slave is 64 bits, req is quad-wrd
                ----------------------------
                
                  sig_byte_addr_incr <= 8;
                
                ----------------------------
                when "0110" =>  -- Slave is 64 bits, req is word
                ----------------------------
                
                  sig_byte_addr_incr <= 4;
                
                ----------------------------
                when "0111" =>  -- Slave is 64 bits, req is dbl-word
                ----------------------------
                
                  sig_byte_addr_incr <= 8;
                
                
                
                
                ----------------------------
                when "1000" =>  -- Slave is 128 bits, req is quad-wrd
                ----------------------------
                
                  sig_byte_addr_incr <= 16;
                
                ----------------------------
                when "1010" =>  -- Slave is 128 bits, req is word
                ----------------------------
                
                  sig_byte_addr_incr <= 4;
                
                ----------------------------
                when "1011" =>  -- Slave is 128 bits, req is dbl-word
                ----------------------------
                
                  sig_byte_addr_incr <= 8;
                
                
                
                ----------------------------
                when others =>  -- assume the Master's Native DWidth
                ----------------------------
                  
                  sig_byte_addr_incr <= C_NATIVE_DWIDTH/8;
              
              end case;
              
          
            end process CALC_BYTE_ADDR_INCR; 
          
          
          
          
           
           
          -------------------------------------------------------------
          -- Synchronous Process with Sync Reset
          --
          -- Label: GEN_BYTE_ADDR_INCR_REG
          --
          -- Process Description:
          -- This process implements a sample and hold register 
          -- for the calculated byte address increment value. 
          --
          -------------------------------------------------------------
          GEN_BYTE_ADDR_INCR_REG : process (bus_clk)
             begin
               if (Bus_Clk'event and Bus_Clk = '1') then
                  if (Bus_Rst = '1') then
                    sig_byte_addr_incr_reg <= 0;
                  elsif (PLB_MAddrAck = '1') then
                    sig_byte_addr_incr_reg <= sig_byte_addr_incr;
                  else
                    null; -- hold current state
                  end if; 
               end if;       
             end process GEN_BYTE_ADDR_INCR_REG; 
         
         
         
                       
          -------------------------------------------------------------
          -- Synchronous Process with Sync Reset
          --
          -- Label: GEN_BYTE_ADDR
          --
          -- Process Description:
          -- This process implements the byte address counter.
          --
          -------------------------------------------------------------
          GEN_BYTE_ADDR : process (bus_clk)
             begin
               if (Bus_Clk'event and Bus_Clk = '1') then
                  if (Bus_Rst = '1') then
                    sig_byte_addr_int <= 0;
                  elsif (sig_s_h_enable = '1') then
                    sig_byte_addr_int <= CONV_INTEGER('0' & Mst_Steer_Addr_in);
                  Elsif (sig_req_is_burst = '1' and
                        (PLB_MWrDack      = '1' or
                         PLB_MRdDack      = '1')) Then
                    
                    sig_byte_addr_int <= sig_byte_addr_int + 
                                         sig_byte_addr_incr_value;
                                         
                  else
                    null;  -- hold current value
                  end if; 
               end if;       
             end process GEN_BYTE_ADDR; 
                       
                       
                       
        
          
          
          
            
          ------------------------------------------------------------
          -- If Generate
          --
          -- Label: GEN_LD_ENBLS_MSTR64
          --
          -- If Generate Description:
          -- This IfGen Builds the Read Register Load Enables for the
          -- case of a 64-bit Native Data Width Master.
          --
          --
          ------------------------------------------------------------
          GEN_LD_ENBLS_MSTR64 : if (C_NATIVE_DWIDTH = 64) generate
          
            signal sig_ld_en_vec_8bit    : std_logic_vector(0 to 7);
            signal sig_byte_addr_3bit    : std_logic_vector(0 to 2);
            Signal sig_ssize_size_64     : std_logic_vector(0 to 4);
            --Signal sig_xfer_size_case_64 : std_logic_vector(0 to 2);
            
            
            begin
         
             -- Used for BLE 
              sig_ld_en_vec        <= sig_ld_en_vec_8bit(0 to 
                                      (C_NATIVE_DWIDTH/8)-1);
             
             -- Used for Conv Cycles                         
              -- sig_be_clr_vec       <= sig_ld_en_vec_8bit(0 to                    
              --                         (C_NATIVE_DWIDTH/8)-1); 
                                         
              
              sig_byte_addr_3bit   <= sig_byte_addr(
                                       (BYTE_ADDR_WIDTH-2) to 
                                        BYTE_ADDR_WIDTH);
              
              
              sig_ssize_value    <=  sig_ssize_reg
                When sig_addrack_cmplt = '1'
                Else PLB_MSsize;
              
              
              -- sig_xfer_size_case_64 <= sig_m_size_reg(1 to 3)
              --    When sig_req_is_burst = '1'
              --    Else "011"; -- force xfer size to Master width (64 bits)
              
              sig_ssize_size_64   <= sig_ssize_value & sig_m_size_reg(1 to 3); 
              --sig_ssize_size_64   <= sig_ssize_value & sig_xfer_size_case_64; 
               
               
              
              -------------------------------------------------------------
              -- Combinational Process
              --
              -- Label: DO_LD_ENBLS_64
              --
              -- Process Description:
              -- This IfGen Builds the Read Register Load Enables for the
              -- case of a 64-bit Native Data Width Master.
              --
              -------------------------------------------------------------
              DO_LD_ENBLS_64 : process (--sig_ssize_reg,
                                        sig_byte_addr_3bit,
                                        sig_ssize_size_64)
                begin
                                
                  
                  
                  --case sig_ssize_reg is
                  case sig_ssize_size_64 is
                    
                    -----------------------------------------------
                    when "00010" =>   -- 32-bit Slave, word request
                    -----------------------------------------------
                      
                      sig_ld_en_vec_8bit      <= "11110000";
                      sig_segment_xfer_done   <= '1';       
                      
                      
                      
                      
                    -----------------------------------------------
                    when "00011" =>   -- 32-bit Slave, dblword request
                    -----------------------------------------------
                      
                      If (sig_byte_addr_3bit(0) = '0') Then

                        sig_ld_en_vec_8bit     <= "11110000";
                        sig_segment_xfer_done  <= '0';
                        
                      else
                      
                        sig_ld_en_vec_8bit     <= "00001111";
                        sig_segment_xfer_done  <= '1';
                        
                      End if;
                      
                      
                      
                    -----------------------------------------------
                    when others =>   -- 64-bit and 128-bit Slaves
                    -----------------------------------------------
                  
                      sig_ld_en_vec_8bit     <= "11111111";
                      sig_segment_xfer_done  <= '1';
                  
                  end case;
                  
              end process DO_LD_ENBLS_64; 
                  

            end generate GEN_LD_ENBLS_MSTR64;
     
     
     
     
          ------------------------------------------------------------
          -- If Generate
          --
          -- Label: GEN_LD_ENBLS_MSTR128
          --
          -- If Generate Description:
          -- This IfGen Builds the Read Register Load Enables for the
          -- case of a 128-bit Native Data Width Master.
          --
          ------------------------------------------------------------
          GEN_LD_ENBLS_MSTR128 : if (C_NATIVE_DWIDTH = 128) generate
          
            
            signal sig_ld_en_vec_16bit    : std_logic_vector(0 to 15);
            signal sig_byte_addr_4bit     : std_logic_vector(0 to 3);
            Signal sig_ssize_size_128     : std_logic_vector(0 to 4);
            --Signal sig_xfer_size_case_128 : std_logic_vector(0 to 2);
            
            begin
          
             -- Used for BLE 
              sig_ld_en_vec      <= sig_ld_en_vec_16bit(0 to 
                                    (C_NATIVE_DWIDTH/8)-1);
             
             -- Used for Conv Cycle 
              -- sig_be_clr_vec     <= sig_ld_en_vec_16bit(0 to
              --                       (C_NATIVE_DWIDTH/8)-1); 
              
              
              sig_byte_addr_4bit <= sig_byte_addr(
                                    (BYTE_ADDR_WIDTH-3) to 
                                     BYTE_ADDR_WIDTH);                  
          
              
              sig_ssize_value    <=  sig_ssize_reg
                When sig_addrack_cmplt = '1'
                Else PLB_MSsize;
              
              -- sig_xfer_size_case_128 <= sig_m_size_reg(1 to 3)
              --    When sig_req_is_burst = '1'
              --    Else "100"; -- force xfer size to Master width (128 bits)
              
              sig_ssize_size_128   <=  sig_ssize_value & sig_m_size_reg(1 to 3); 
              --sig_ssize_size_128   <=  sig_ssize_value & sig_xfer_size_case_128; 
              
              
              
              -------------------------------------------------------------
              -- Combinational Process
              --
              -- Label: DO_LD_ENBLS_128
              --
              -- Process Description:
              --     This Process formulates the Read Register Load 
              -- Enables for a 128-bit Master and 32-bit, 64-bit,
              -- and 128-bit Slaves.
              --
              --
              -- Note: It is required that the Master set the M_msize to
              -- match the transfer size denoted by the M_size(0:3) 
              -- qualifier.
              --
              -------------------------------------------------------------
              DO_LD_ENBLS_128 : process (--sig_ssize_reg,
                                         sig_byte_addr_4bit,
                                         sig_ssize_size_128)
                begin
             
                  --case sig_ssize_reg is
                  case sig_ssize_size_128 is
                    
                    ------------------------------------------------
                    when "00010" =>   
                    -- 32-bit Slave, word wide xfer
                    ------------------------------------------------
                      
                      sig_ld_en_vec_16bit   <= "1111000000000000";
                      sig_segment_xfer_done <= '1';              
                      
                      
                    ------------------------------------------------
                    when "00011" =>   
                    -- 32-bit Slave, dblwrd wide xfer
                    ------------------------------------------------
                      
                      case sig_byte_addr_4bit is
                        when "0000" | "0001" | "0010" | "0011" =>
                          sig_ld_en_vec_16bit   <= "1111000000000000";
                          sig_segment_xfer_done <= '0';
                        when "0100" | "0101" | "0110" | "0111" =>
                          sig_ld_en_vec_16bit   <= "0000111100000000";
                          sig_segment_xfer_done <= '1';
                        when "1000" | "1001" | "1010" | "1011" =>
                          sig_ld_en_vec_16bit   <= "1111000000000000";
                          sig_segment_xfer_done <= '0';
                        when others =>
                          sig_ld_en_vec_16bit   <= "0000111100000000";
                          sig_segment_xfer_done <= '1';
                      end case;
   
   
    
                    -----------------------------------------------
                    when "00100" =>   
                    -- 32-bit Slave, quadwrd wide xfer
                    ------------------------------------------------
                      
                      case sig_byte_addr_4bit is
                        when "0000" | "0001" | "0010" | "0011" =>
                          sig_ld_en_vec_16bit   <= "1111000000000000";
                          sig_segment_xfer_done <= '0';
                        when "0100" | "0101" | "0110" | "0111" =>
                          sig_ld_en_vec_16bit   <= "0000111100000000";
                          sig_segment_xfer_done <= '0';
                        when "1000" | "1001" | "1010" | "1011" =>
                          sig_ld_en_vec_16bit   <= "0000000011110000";
                          sig_segment_xfer_done <= '0';
                        when others =>
                          sig_ld_en_vec_16bit   <= "0000000000001111";
                          sig_segment_xfer_done <= '1';
                      end case;
                        
    
                        
                    -----------------------------------------------
                    when "01010" =>  
                    -- 64-bit Slave, word wide xfer
                    -----------------------------------------------
                    
                    
                      sig_ld_en_vec_16bit   <= "1111000000000000";
                      sig_segment_xfer_done <= '1';              
                       

                      
                    -----------------------------------------------
                    when "01011" =>  
                    -- 64-bit Slave, dblwrd wide xfer
                    -----------------------------------------------
                       
                      sig_ld_en_vec_16bit   <= "1111111100000000";
                      sig_segment_xfer_done <= '1';              

                       
                      
                    -----------------------------------------------
                    when "01100" =>  
                    -- 64-bit Slave, quadwrd wide xfer
                    -----------------------------------------------
                       
                      if (sig_byte_addr_4bit(0) = '0') then
                      
                         sig_ld_en_vec_16bit   <= "1111111100000000";
                         sig_segment_xfer_done <= '0';
                      
                      else
                      
                         sig_ld_en_vec_16bit   <= "0000000011111111";
                         sig_segment_xfer_done <= '1';
                      
                      end if;
                       
                      
                    -----------------------------------------------
                    When "10010" | "10011" | "10100"  =>    
                    -- 128-bit Slave, wrd, dblwrd, and Qwrd
                    -----------------------------------------------
                    
                       sig_ld_en_vec_16bit   <= "1111111111111111";
                       sig_segment_xfer_done <= '1';
                        
                      
                    -----------------------------------------------
                    when others =>  
                    -----------------------------------------------
                    
                       sig_ld_en_vec_16bit   <= "0000000000000000";
                       sig_segment_xfer_done <= '0';
                        
                  end case;
                  
                end process DO_LD_ENBLS_128; 
                  

         
            end generate GEN_LD_ENBLS_MSTR128;
        
        
        
         
         

   
   
   
                
                
                
                
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    --
    -- Conversion Cycle Logic
    --
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
   
   
   
         -- Conversion Cycle Generator Internals 
           
          sig_combined_ack    <=   PLB_MRdDAck or PLB_MWrDAck;
          
          sig_cc_next_size     <=  "0000"; -- always a Single data beat when used
          
          sig_cc_next_be       <=  sig_be_reg;
          
          sig_cc_next_addr     <=  sig_address_reg(0 to 
                                   (C_AWIDTH-NUM_LS_ADDR_BITS)-1) &
                                   sig_next_addr_ls_reg;
          
          
          sig_cc_next_rnw      <=  sig_rnw_reg;
          
          
          sig_cc_next_msize    <=  sig_msize_reg;
          
          
          sig_cc_next_priority <=  "11"; -- High priority for Conv Cycle
                                     
          
          
          -- 
          --sig_need_conv_cycle  <= sig_inhib_dack;
          
          --  -- Generate the BE Register Load enable pulse
          --  sig_s_h_enable       <= MST_Req_in and not(sig_mstr_req_reg);
         
          
          -- Determine if all remaining BE will be cleared on this 
          -- clear iteration
          sig_be_clr_vec_and   <=  not(sig_be_clr_vec) and sig_be_reg;
          
   
   
   
          sig_need_conv_cycle <= sig_be_still_set and
                                 not(sig_req_is_burst);                        
          
   
          sig_cc_xfer_cmplt    <=  sig_combined_ack and
                                   not(sig_need_conv_cycle);
          
                
      
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_CC_RDACK_REG
        --
        -- Process Description:
        -- This process implements a register that generates the
        -- read data acknowledge that is sent to the Master logic
        -- as a result of Conversion Cycle operations.
        -- This delays the RdAck from the PLB by one clock to align
        -- it with the data that is collected and output to the
        -- Master from the Read Data Register.
        --
        -------------------------------------------------------------
        GEN_CC_RDACK_REG : process (bus_clk)
           begin
             if (Bus_Clk'event and Bus_Clk = '1') then
               if (Bus_Rst        = '1' or
                   sig_xfer_cmplt = '1') then
                 sig_cc_rddack_to_mstr <= '0';
               else
                 sig_cc_rddack_to_mstr <= not(sig_need_conv_cycle) and
                                          PLB_MRdDack;
               end if; 
             end if;       
           end process GEN_CC_RDACK_REG; 
          
          
          
          
      
      
      
      
      
      
      
      
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: GEN_INHIB_DACK
      --
      -- Process Description:
      --  This process implements logic to examine the BE register
      -- assertions that will remain after the ensuing transfer
      -- data ack from the Slave occurs.  If the Target Slave is
      -- too narrow, then overflow BE assertions will remain in 
      -- the BE register and the the associated Data Ack has to
      -- be suppressed from the Master. This will also cause an 
      -- additional request (Conversion_cycle) to be generated 
      -- starting at the next address that corresponds to the 
      -- index of the first overflow BE still asserted.  
      -- If all of the asserted BE will be satisfied, then the 
      -- Data Ack is relayed back to the Master indicating a 
      -- completed transfer.
      -------------------------------------------------------------
       DO_BE_PARSER : process (sig_be_clr_vec_and)
       
         Variable be_bit_position : Integer;
         Variable be_bit_detected : Boolean;
         Variable be_loop_index   : integer;
         
         Begin
          
           be_loop_index   := BE_WIDTH;
           be_bit_position := 0;
           be_bit_detected := FALSE;
         
                                     
           --sig_inhib_dack <= sig_be_still_set;                           
                                     
          -- Search through the pending BE values starting with the LSB 
           while (be_loop_index > 0) loop
              
             If (sig_be_clr_vec_and(be_loop_index-1) = '1') Then
               be_bit_detected := TRUE;
               be_bit_position := be_loop_index-1;
             else
               null; -- do nothing
             End if;
            
             be_loop_index := be_loop_index - 1;
     
           End loop;
           
          -- now assign the Address output value corresponding to the bit position 
          -- of the most significant BE assertion encountered 
           If (be_bit_detected) Then
              sig_next_addr_ls  <= conv_std_logic_vector(be_bit_position, NUM_LS_ADDR_BITS);
              sig_be_still_set  <= '1';  
           else
              sig_next_addr_ls  <= conv_std_logic_vector(0, NUM_LS_ADDR_BITS); 
              sig_be_still_set  <= '0';
           End if;


         End process DO_BE_PARSER; 

      
      
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: REG_NEXT_ADDR_LS
      --
      -- Process Description:
      --    This process registers the next address for an ensuing
      -- conversion cycle.  
      --
      -------------------------------------------------------------
      REG_NEXT_ADDR_LS : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1') then
               sig_next_addr_ls_reg <= (others => '0');
             
             Elsif (sig_s_h_enable = '1') Then

               sig_next_addr_ls_reg <= Mst_Addr_in(C_AWIDTH-NUM_LS_ADDR_BITS to
                                                   C_AWIDTH-1); 
                 
             elsif (sig_combined_ack = '1' and 
                    sig_be_still_set = '1') then

               sig_next_addr_ls_reg  <=  sig_next_addr_ls;
             
             else
               null;  -- hold current value
             end if; 
           end if;       
         end process REG_NEXT_ADDR_LS; 
      
      
      
      
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: GEN_CC_STEER_ADDR
        --
        -- Process Description:
        -- This process creates the steering address value that is 
        -- needed during Conversion Cycle write operations
        --
        -------------------------------------------------------------
        GEN_CC_STEER_ADDR : process (sig_next_addr_ls_reg)
           begin
        
           -- Default the entire value  
             sig_cc_steer_addr <= (others => '0');
             
             
           -- overload the CC byte address bits  
             sig_cc_steer_addr(C_STEER_ADDR_WIDTH-NUM_LS_ADDR_BITS to
                            C_STEER_ADDR_WIDTH-1) <= sig_next_addr_ls_reg;
          
          
        
           end process GEN_CC_STEER_ADDR; 
        
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: REG_NEED_CONV_CYCLE
      --
      -- Process Description:
      --    This process registers the signal indicating that a 
      -- Conversion Cycle is required to complete a Single Data
      -- Beat request. The registered signal is used to generate
      -- ensuing M_request assertions to the PLB so it must clear
      -- upon receipt of an addrack and regenerate on receipt of
      -- a data ack from the PLB if needed.
      --
      -------------------------------------------------------------
      REG_NEED_CONV_CYCLE : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
              if (Bus_Rst       = '1' or
                 (PLB_MAddrAck  = '1' and
                  PLB_MWrDAck   = '0')) then
                
                sig_need_conv_cycle_reg <= '0';
              
              Elsif (-- sig_parent_addrack_cmplt = '1' and
                     sig_combined_ack         = '1') Then
                
                sig_need_conv_cycle_reg <= sig_need_conv_cycle;                           
              
              else
                null; -- hold current state
              end if; 
           end if;       
         end process REG_NEED_CONV_CYCLE; 
      
      
      
      
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_PARENT_ADDRACK_CMPLT
        --
        -- Process Description:
        -- This process implements a sample and hold register for the
        -- address acknowledge from the PLB for the parent request.
        --
        -------------------------------------------------------------
        GEN_PARENT_ADDRACK_CMPLT : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
              if (Bus_Rst        = '1' or
                  sig_xfer_cmplt = '1') then
                sig_parent_addrack_cmplt <= '0';
              elsif (PLB_MAddrAck = '1') then
                sig_parent_addrack_cmplt <= '1';
              else
                null;  -- hold current state
              end if; 
            end if;       
          end process GEN_PARENT_ADDRACK_CMPLT; 
        
        
        
   
        -------------------------------------------------------------
        -- Synchronous Process with Sync Reset
        --
        -- Label: GEN_FIRST_WRDACK_CMPLT
        --
        -- Process Description:
        -- This process implements a sample and hold register for the
        -- receipt of the first write data acknowledge from the PLB 
        -- for the parent request.
        --
        -------------------------------------------------------------
        GEN_FIRST_WRDACK_CMPLT : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
              if (Bus_Rst        = '1' or
                  sig_xfer_cmplt = '1') then
                sig_first_wrdack_cmplt <= '0';
              elsif (PLB_MWrDack = '1') then
                sig_first_wrdack_cmplt <= '1';
              else
                null;  -- hold current state
              end if; 
            end if;       
          end process GEN_FIRST_WRDACK_CMPLT; 
        
        
        
   
       
       
       
       
     --   redundant     -------------------------------------------------------------
     --   redundant     -- Synchronous Process with Sync Reset
     --   redundant     --
     --   redundant     -- Label: REG_MSTR_REQ
     --   redundant     --
     --   redundant     -- Process Description:
     --   redundant     --
     --   redundant     --
     --   redundant     -------------------------------------------------------------
     --   redundant     REG_MSTR_REQ : process (bus_clk)
     --   redundant        begin
     --   redundant          if (Bus_Clk'event and Bus_Clk = '1') then
     --   redundant             if (Bus_Rst = '1') then
     --   redundant               sig_mstr_req_reg <= '0';
     --   redundant             else
     --   redundant               sig_mstr_req_reg <= MST_Req_in;
     --   redundant             end if; 
     --   redundant          end if;       
     --   redundant        end process REG_MSTR_REQ; 
    
    
    
    
     
     
     
       
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: DO_ADDR_REGISTER
      --
      -- Process Description:
      --  Samples and holds the starting address from the Master
      --
      -------------------------------------------------------------
      DO_ADDR_REGISTER : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1') then
               sig_address_reg <= (others => '0');
             elsif (sig_s_h_enable = '1') then
               sig_address_reg <= Mst_Addr_in;
             else
               null;  -- hold the current state
             end if; 
           end if;       
         end process DO_ADDR_REGISTER; 
       
       
       
       
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: DO_MISC_REGISTER
      --
      -- Process Description:
      --    Samples and holds other qualifiers from the Master that 
      -- need to be echoed when a Conversion Cycle is required.
      --
      -------------------------------------------------------------
      DO_MISC_REGISTER : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst = '1') then
               --sig_rnw_reg   <= '0';
               sig_msize_reg <= (others => '0');
             elsif (sig_s_h_enable = '1') then
               --sig_rnw_reg   <= Mst_RNW_in;
               sig_msize_reg <= Mst_MSize_in;
             else
               null;  -- hold the current state
             end if; 
           end if;       
         end process DO_MISC_REGISTER; 
       
       
      
      -------------------------------------------------------------
      -- Synchronous Process with Sync Reset
      --
      -- Label: DO_MBUSY_REG
      --
      -- Process Description:
      --    This process implements the mbusy flag needed during
      -- Conversion Cycle operations. This facilitates a continously
      -- asserted PLB_MBusy back to the Master while Conversion
      -- Cycles are in progress.
      --
      -------------------------------------------------------------
      DO_MBUSY_REG : process (bus_clk)
         begin
           if (Bus_Clk'event and Bus_Clk = '1') then
              if (Bus_Rst        = '1' or
                  sig_xfer_cmplt = '1') then
                sig_cc_mbusy_reg <= '0';
              elsif (PLB_MAddrAck = '1' and
                     sig_need_conv_cycle = '1') then
                sig_cc_mbusy_reg <= '1';
              else
                null; -- hold current state
              end if; 
           end if;       
         end process DO_MBUSY_REG; 
      
      
       
       
      ------------------------------------------------------------
      -- For Generate
      --
      -- Label: DO_BE_REGISTER
      --
      -- For Generate Description:
      --  This ForGen implements a parametized number of BE
      -- Register bits. Each bit can be indepenently cleared.
      --
      --
      --
      ------------------------------------------------------------
      DO_BE_REGISTER : for be_index in 0 to BE_WIDTH-1 generate
         -- local variables
         -- local constants
         -- local signals
         -- local component declarations
      
      begin
      
         
         
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: BE_REG_BIT
         --
         -- Process Description:
         -- This process implements a single bit of the BE Register
         --
         -------------------------------------------------------------
         BE_REG_BIT : process (bus_clk)
            begin
              if (Bus_Clk'event and Bus_Clk = '1') then
                 if (Bus_Rst = '1') then
                   sig_be_reg(be_index) <= '0';
                 elsif (sig_s_h_enable = '1') then
                   sig_be_reg(be_index) <= Mst_BE_in(be_index);
                 Elsif (sig_be_clr_vec(be_index) = '1' and
                        sig_combined_ack         = '1') Then
                    sig_be_reg(be_index) <= '0';
                 else
                   null;  -- hold current state
                 end if; 
              end if;       
            end process BE_REG_BIT; 
         
      end generate DO_BE_REGISTER;
       

 
 
 
      
       ------------------------------------------------------------
       -- If Generate
       --
       -- Label: GEN_BE_CLRS_MSTR64
       --
       -- If Generate Description:
       -- This IfGen Builds the BE Register Clear Bit vector for the
       -- case of a 64-bit Native Data Width Master.
       --
       --
       ------------------------------------------------------------
       GEN_BE_CLRS_MSTR64 : if (C_NATIVE_DWIDTH = 64) generate
       
         signal sig_be_clr_vec_8bit         : std_logic_vector(0 to 7);
         signal sig_strt_addr_ls_3bit       : std_logic_vector(0 to 2);
         --signal sig_next_strt_addr_ls_3bit  : std_logic_vector(0 to 2);
         Signal sig_slave_size_64            : std_logic_vector(0 to 1);
         
         
         
         begin
       
           
           sig_be_clr_vec <= sig_be_clr_vec_8bit(0 to 
                             (C_NATIVE_DWIDTH/8)-1);
           
           -- sig_strt_addr_ls_3bit <=  sig_strt_addr_ls(0 to 
           --                           NUM_LS_ADDR_BITS-1);
           
           sig_strt_addr_ls_3bit <=  sig_next_addr_ls_reg(0 to 
                                     NUM_LS_ADDR_BITS-1);
           
           
           sig_slave_size_64 <= sig_ssize_reg
             When sig_parent_addrack_cmplt = '1'
             Else PLB_MSsize ;
           
           
       
           -------------------------------------------------------------
           -- Combinational Process
           --
           -- Label: DO_BE_CLR_BITS_64
           --
           -- Process Description:
           --     This Process formulates the BE clear mask for a 
           -- 64-bit Master and 32-bit, 64-bit and 128-bit Slaves
           --
           -------------------------------------------------------------
           DO_BE_CLR_BITS_64 : process (sig_slave_size_64,
                                        sig_strt_addr_ls_3bit)
             begin
          
               case sig_slave_size_64 is
                 --------------------------------
                 when "00" =>   -- 32-bit Slave
                 --------------------------------
                     
                   case sig_strt_addr_ls_3bit is
                     when "000" =>
                       sig_be_clr_vec_8bit <= "11110000";
                       --sig_next_strt_addr_ls_3bit <= "100";
                     when "001" =>
                       sig_be_clr_vec_8bit <= "11110000";
                       --sig_next_strt_addr_ls_3bit <= "100";
                     when "010" =>
                       sig_be_clr_vec_8bit <= "11110000";
                       --sig_next_strt_addr_ls_3bit <= "100";
                     when "011" =>
                       sig_be_clr_vec_8bit <= "11110000";
                       --sig_next_strt_addr_ls_3bit <= "100";
                     --  when "100" =>
                     --    sig_be_clr_vec_8bit <= "00001111";
                     --    sig_next_strt_addr_ls_3bit <= "000";
                     --  when "101" =>
                     --    sig_be_clr_vec_8bit <= "00001111";
                     --    sig_next_strt_addr_ls_3bit <= "000";
                     --  when "110" =>
                     --    sig_be_clr_vec_8bit <= "00001111";
                     --    sig_next_strt_addr_ls_3bit <= "000";
                     --  when "111" =>
                     --    sig_be_clr_vec_8bit <= "00001111";
                     --    sig_next_strt_addr_ls_3bit <= "000";
                     when others =>
                       sig_be_clr_vec_8bit <= "00001111";
                       --sig_next_strt_addr_ls_3bit <= "000";
                   end case;
                     
                 --------------------------------
                 when others =>   -- 64-bit and 128-bit Slaves
                 --------------------------------
               
                   sig_be_clr_vec_8bit <= "11111111";
                   --sig_next_strt_addr_ls_3bit <= "000";
               
               end case;
               
           end process DO_BE_CLR_BITS_64; 
               
       
         end generate GEN_BE_CLRS_MSTR64;
       
       
       
       
       ------------------------------------------------------------
       -- If Generate
       --
       -- Label: GEN_BE_CLRS_MSTR128
       --
       -- If Generate Description:
       -- This IfGen Builds the BE Register Clear Bit vector for the
       -- case of a 128-bit Native Data Width Master.
       --
       ------------------------------------------------------------
       GEN_BE_CLRS_MSTR128 : if (C_NATIVE_DWIDTH = 128) generate
       
         
         signal sig_be_clr_vec_16bit         : std_logic_vector(0 to 15);
         signal sig_strt_addr_ls_4bit        : std_logic_vector(0 to 3);
         --signal sig_next_strt_addr_ls_4bit   : std_logic_vector(0 to 3);
         Signal sig_slave_size_128           : std_logic_vector(0 to 1);
         
         begin
       
           sig_be_clr_vec <= sig_be_clr_vec_16bit(0 to 
                             (C_NATIVE_DWIDTH/8)-1);
           
           -- sig_strt_addr_ls_4bit <=  sig_strt_addr_ls(0 to 
           --                           NUM_LS_ADDR_BITS-1);
           
           sig_strt_addr_ls_4bit <=  sig_next_addr_ls_reg(0 to 
                                     NUM_LS_ADDR_BITS-1);
           
           sig_slave_size_128 <= sig_ssize_reg
             When sig_parent_addrack_cmplt = '1'
             Else PLB_MSsize ;
           
           
       
           -------------------------------------------------------------
           -- Combinational Process
           --
           -- Label: GEN_BE_CLR_BITS
           --
           -- Process Description:
           --     This Process formulates the BE clear mask for a 
           -- 128-bit Master and 32-bit, 64-bit and 128-bit Slaves
           --
           -------------------------------------------------------------
           GEN_BE_CLR_BITS : process (sig_slave_size_128,
                                      sig_strt_addr_ls_4bit)
             begin
          
               case sig_slave_size_128 is
                 
                 --------------------------------
                 when "00" =>   -- 32-bit Slave
                 --------------------------------
                   
                   case sig_strt_addr_ls_4bit is
                     when "0000" | "0001" | "0010" | "0011" =>
                       sig_be_clr_vec_16bit <= "1111000000000000";
                       --sig_next_strt_addr_ls_4bit <= "0100";
                     
                     
                     when "0100" | "0101" | "0110" | "0111" =>
                       sig_be_clr_vec_16bit <= "0000111100000000";
                       --sig_next_strt_addr_ls_4bit <= "1000";
                     
                     
                     when "1000" | "1001" | "1010" | "1011" =>
                       sig_be_clr_vec_16bit <= "0000000011110000";
                       --sig_next_strt_addr_ls_4bit <= "1100";
                     
                     
                     when others =>
                       sig_be_clr_vec_16bit <= "0000000000001111";
                       --sig_next_strt_addr_ls_4bit <= "0000";
                       
                   end case;
       
       
       
                     
                 --------------------------------
                 when "01" =>  -- 64-bit Slave
                 --------------------------------
                   
                   
                   If (sig_strt_addr_ls_4bit(0) = '0') Then
       
                     sig_be_clr_vec_16bit <= "1111111100000000";
                     --sig_next_strt_addr_ls_4bit <= "1000";
                     
                   else
                   
                     sig_be_clr_vec_16bit <= "0000000011111111";
                     --sig_next_strt_addr_ls_4bit <= "0000";
                     
                   End if;
                   
                   
                   
                   
                   
                   -- case sig_strt_addr_ls_4bit is
                   --   when "0000" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0001" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0010" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0011" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0100" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0101" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0110" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   when "0111" =>
                   --     sig_be_clr_vec_16bit <= "1111111100000000";
                   --     --sig_next_strt_addr_ls_4bit <= "1000";
                   --   
                   --   when others =>
                   --     sig_be_clr_vec_16bit <= "0000000011111111";
                   --     --sig_next_strt_addr_ls_4bit <= "0000";
                   -- end case;
       
       
                     
                 --------------------------------
                 when others =>  -- 128-bit Slave
                 --------------------------------
                 
                     sig_be_clr_vec_16bit <= "1111111111111111";
                     --sig_next_strt_addr_ls_4bit <= "0000";
                     
               end case;
               
             end process GEN_BE_CLR_BITS; 
            
      
      
      end generate GEN_BE_CLRS_MSTR128;

 
 
 
      
      end implementation;
