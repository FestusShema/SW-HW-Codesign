-------------------------------------------------------------------------------
-- $Id: rd_wr_calc_burst.vhd,v 1.3 2007/01/04 23:41:29 dougt Exp $
-------------------------------------------------------------------------------
-- rd_wr_calc_burst.vhd
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
-- Filename:        rd_wr_calc_burst.vhd
--
-- Description:     
--
--                  
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              rd_wr_calc_burst.vhd
--                |
--                |-- plb_mstr_addr_gen.vhd 
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $$
-- Date:            $10/11/2006$
--
-- History:
--   DET   10/11/2006       Initial Version
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
use ieee.std_logic_unsigned.all;  
use ieee.std_logic_arith.all;  


library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;


library plbv46_master_burst_v1_00_a;
use plbv46_master_burst_v1_00_a.plb_mstr_addr_gen;


library unisim; -- Required for Xilinx primitives
use unisim.all;  


-------------------------------------------------------------------------------

entity rd_wr_calc_burst is
  generic (
    C_LENGTH_WIDTH           : integer range 8 to 30 := 12; 
    C_MAX_FBURST_DBCNT       : integer range 2 to 16 := 16;
    C_PLB_AWIDTH             : Integer := 32; 
    C_NATIVE_DWIDTH          : Integer := 32  
    );
  port (
   
    -- System Inputs
    -- (synchronous to Bus_clk)
     Bus_Clk                   : In  std_logic;
     Bus_Rst                   : In  std_logic;
  
   -- Control Inputs
     Make_Bus_Req              : In  std_logic; 
     New_IP_Req                : In  std_logic; 
     Clr_IP_Req                : In  std_logic; 
     WrAck                     : In  std_logic; 
     RdAck                     : In  std_logic; 
                                                                                                                       
   -- Command Generation Status (outputs)  
     Cmd_Valid                 : Out std_logic;                                                                        
     Cmd_Error                 : Out std_logic;                                                                        
     IP_Req_Done               : Out std_logic;                                                                        
     Xfer_Done                 : Out std_logic;                                                                        
     Xfer_Almost_Done          : Out std_logic;                                                                        
     FLBurst_term              : Out std_logic; 
     Length_is_Zero            : Out std_logic;                                                                        
     Length_is_One             : Out std_logic;
     Length_is_Two             : Out std_logic;
     Single_In_Prog            : Out std_logic;
     FLBurst_In_Prog           : Out std_logic;
     Parent_Is_Single          : Out std_logic;
     Parent_Is_FLBurst         : Out std_logic;
     
   
   -- IP Request Qualifiers (inputs)
     IP2Mst_Rd                 : in  std_logic;
     IP2Mst_Wr                 : in  std_logic;
     IP2Mst_Addr               : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
     IP2Mst_Length             : in  std_logic_vector(0 to C_LENGTH_WIDTH-1);
     IP2Mst_BE                 : in  std_logic_vector(0 to 
                                                     (C_NATIVE_DWIDTH/8)-1);     
     IP2Mst_Type               : in  std_logic;
     IP2Mst_Lock               : In  std_logic;
                               
   -- PLB Request qualifiers (outputs)                         
     Mst_RNW_Out               : out  std_logic;     
     Mst_Addr_Out              : out  std_logic_vector(0 to C_PLB_AWIDTH-1);     
     Mst_BE_Out                : out  std_logic_vector(0 to 
                                                      (C_NATIVE_DWIDTH/8)-1);
     Mst_Size_Out              : out  std_logic_vector(0 to 3); 
     Mst_Burst_Out             : out  std_logic;  
     Mst_Lock_Out              : out  std_logic                                 
                               
    );

end entity rd_wr_calc_burst;


architecture implementation of rd_wr_calc_burst is

  -- functions
   
     -------------------------------------------------------------------
     -- Function
     --
     -- Function Name: calc_xfer_size
     --
     -- Function Description:
     --  This function calculates the transfer size encoded value that
     -- is output during a Fixed Length Burst Address Phase. The transfer
     -- size is based on the Native Data Width of the Master.
     --
     -------------------------------------------------------------------
     function calc_xfer_size (native_dwidth : integer) return std_logic_vector is
     
       Variable size : std_logic_vector(0 to 3) := "1010";
       
     begin
     
        case native_dwidth is
          when 64 =>
            size := "1011"; -- dbl word (64 bits)
          when 128 =>
            size := "1100"; -- quad word (128 bits)
          when others =>
            size := "1010"; -- word (32 bits)
        end case;
        
        Return(size);
                    
     end function calc_xfer_size;
     
  
  
  
  
  
  -- Constants
     
     Constant NUM_BYTE_ADDR_BITS  : integer := log2(C_NATIVE_DWIDTH/8);
     
     Constant LENGTH_NATIVE_DWIDTH_INDEX  : integer := 
              NUM_BYTE_ADDR_BITS + 1;
              -- if Native DWIDTH is 32 then index is 3
              -- if Native DWIDTH is 64 then index is 4
              -- if Native DWIDTH is 128 then index is 5
     
     
     Constant ADDR_LSB_ZEROS      : std_logic_vector(0 to 
                                    NUM_BYTE_ADDR_BITS-1) 
                                    := (others => '0');
     
     Constant ADDRESS_INC_VALUE   : integer := C_NATIVE_DWIDTH/8; 
                                           
     Constant BE_WIDTH            : integer := C_NATIVE_DWIDTH/8; 
                       
     Constant MAX_FLBURST_DBEATS  : integer := C_MAX_FBURST_DBCNT;
     
     Constant MAX_FLBURST_DBEATS_MINUS_1 : integer := C_MAX_FBURST_DBCNT-1;  

     Constant BE_ALL_SET   : std_logic_vector(0 to BE_WIDTH-1)
                                           := (others => '1');
     Constant BE_ALL_CLR   : std_logic_vector(0 to BE_WIDTH-1)
                                           := (others => '0');

     Constant SIZE_OF_SNGL : std_logic_vector(0 to 3) := "0000";
     
     --Constant SIZE_OF_WRD  : std_logic_vector(0 to 3) := "1010";
   
     Constant SIZE_OF_BRST_XFER : std_logic_vector(0 to 3) := 
                             calc_xfer_size(C_NATIVE_DWIDTH);
   
   
     
   -- types
     
     type CALC_OP_TYPES is (IN_RESET, 
                            NO_OP, 
                            CALC_SINGLE, 
                            CALC_FLBURST 
                            );
                               
                              
  -- Signals
  
     Signal sig_combined_ack            : std_logic;
     Signal sig_combined_ack_reg        : std_logic;
     Signal parent_dbeats_remaining     : integer range 0 to 
                                          2**C_LENGTH_WIDTH-1 := 0;
     Signal parent_dbeats_remaining_slv : std_logic_vector(0 to 
                                          C_LENGTH_WIDTH-1);
     -- Signal sig_length_wrds_int         : Integer range 0 to 
     --                                      (2**C_LENGTH_WIDTH-1)/4 := 0; 
     -- Signal sig_length_wrds             : std_logic_vector(0 to 
     --                                      C_LENGTH_WIDTH-3); 
     --Signal sig_flburst_cnt_raw         : std_logic_vector(0 to BE_WIDTH-1); 
     Signal sig_flburst_cnt_raw         : std_logic_vector(0 to 3); 
     --Signal sig_flburst_cnt             : std_logic_vector(0 to BE_WIDTH-1); 
     Signal sig_flburst_cnt             : std_logic_vector(0 to 3); 
     Signal sig_flburst_cnten           : std_logic;
     Signal sig_flburst_cnten_reg       : std_logic;
     Signal sig_cmd_has_been_queued     : std_logic;
     Signal sig_cmd_init                : std_logic;
     Signal dbeat_count                 : integer range 0 to 
                                          MAX_FLBURST_DBEATS := 0;
     Signal dbeat_cnt_done              : std_logic;
     Signal dbeat_cnt_almost_done       : std_logic;
     Signal dbeat_cnt_done_reg          : std_logic;
     Signal dbeat_cnt_almost_done_reg   : std_logic;
     Signal sig_dbeat_count_ld_value    : integer range 0 to 
                                          MAX_FLBURST_DBEATS := 0;
     Signal doing_a_single              : std_logic;
     Signal doing_a_fl_burst            : std_logic;
     Signal doing_a_single_reg          : std_logic;
     Signal doing_a_fl_burst_reg        : std_logic;
     Signal sig_flburst_is_max          : std_logic;
     Signal error_condition             : std_logic;
     Signal sig_calc_op                 : CALC_OP_TYPES;
     Signal sig_cmd_is_valid_s0         : std_logic;
     Signal sig_cmd_is_valid_s1         : std_logic;
     Signal sig_cmd_is_valid            : std_logic;
     Signal parent_cmd_done             : std_logic;
     Signal parent_xfer_single_reg      : std_logic;
     Signal parent_xfer_flburst_reg     : std_logic;
     Signal sig_be_reg                  : std_logic_vector(0 to 
                                          (C_NATIVE_DWIDTH/8)-1);
     Signal addr_cnt_enable             : std_logic;
     Signal sig_addr_incr_ld_enable     : std_logic;
     Signal cmd_rnw                     : std_logic;
     Signal cmd_size                    : std_logic_vector(0 to 3);
     Signal cmd_be                      : std_logic_vector(0 to 
                                          (C_NATIVE_DWIDTH/8)-1);
     Signal cmd_addr                    : std_logic_vector(0 to 
                                          C_PLB_AWIDTH-1);
     Signal cmd_burst                   : std_logic;
     Signal cmd_lock                    : std_logic;
     signal sig_ip2bus_rd_reg           : std_logic;
     signal sig_ip2bus_wr_reg           : std_logic;
     signal addr_cntr_address           : std_logic_vector(0 to 
                                          C_PLB_AWIDTH-1);
     signal sig_addr_increment          : std_logic_vector(0 to 
                                          C_LENGTH_WIDTH-1);
     signal sig_ld_addr_cntr            : std_logic;
     signal sig_rdack_reg               : std_logic;
     signal sig_wrack_reg               : std_logic;
     signal sig_clr_addr_cntr           : std_logic;
     
     Signal parent_dbeats_remaining_eq_0      : boolean := true;
     Signal parent_dbeats_remaining_eq_1      : boolean := false;
     Signal parent_dbeats_remaining_eq_2      : boolean := false;
     Signal parent_dbeats_remaining_lt_MFBDBs : boolean := true;
     
     Signal sig_length_native           : std_logic_vector(0 to 
                                          C_LENGTH_WIDTH -
                                          LENGTH_NATIVE_DWIDTH_INDEX); 
     
     Signal sig_length_native_int       : Integer range 0 to 
                                          (2**C_LENGTH_WIDTH-1)/
                                          (C_NATIVE_DWIDTH/8) := 0; 
     
     
  -- Component Declarations



begin --(architecture implementation)


   -- Port Assignments
    
     Mst_RNW_Out            <= cmd_rnw;
     Mst_Addr_Out           <= cmd_addr;
     Mst_BE_Out             <= cmd_be  ;
     Mst_Size_Out           <= cmd_size;
     Mst_Burst_Out          <= cmd_burst;
     Mst_Lock_Out           <= cmd_lock;
     
     Cmd_Valid              <= sig_cmd_is_valid;
     cmd_rnw                <= sig_ip2bus_rd_reg;
     cmd_addr               <= addr_cntr_address;
     cmd_burst              <= doing_a_fl_burst; 
     cmd_lock               <= IP2Mst_Lock; 
     Cmd_Error              <= error_condition;
 
   
     IP_Req_Done            <= parent_cmd_done;
     Xfer_Done              <= dbeat_cnt_done_reg       ; 
     Xfer_Almost_Done       <= dbeat_cnt_almost_done_reg;
     
     Single_In_Prog         <= doing_a_single_reg     ; 
     FLBurst_In_Prog        <= doing_a_fl_burst_reg   ;  
     
     Parent_is_Single       <=  parent_xfer_single_reg ;
     Parent_is_FLBurst      <=  parent_xfer_flburst_reg;
     


     
     FLBurst_term           <= dbeat_cnt_almost_done and 
                               doing_a_fl_burst_reg;
     
     
     Length_is_Zero         <=  '1'
        when parent_dbeats_remaining_eq_0
        Else '0';
     
     Length_is_One         <=  '1'
        when parent_dbeats_remaining_eq_1
        Else '0';
     
     Length_is_Two        <=  '1'
        when parent_dbeats_remaining_eq_2
        Else '0';
     
     
     
     sig_flburst_cnten       <= parent_xfer_flburst_reg and
                                (WrAck or RdAck);

     sig_flburst_cnten_reg   <= parent_xfer_flburst_reg and
                                (sig_wrack_reg or 
                                 sig_rdack_reg);          
     
     
     --sig_length_wrds         <= IP2Mst_Length(0 to C_LENGTH_WIDTH-3);
                                           
     --sig_length_wrds_int     <= CONV_INTEGER('0' & sig_length_wrds);
     
     
     sig_length_native       <= IP2Mst_Length(0 to 
                                C_LENGTH_WIDTH -
                                LENGTH_NATIVE_DWIDTH_INDEX);
     
     sig_length_native_int   <= CONV_INTEGER('0' & sig_length_native);
     
     
     
     
     sig_combined_ack        <= RdAck or WrAck;
     
     
    -------------------------------------------------------------------
    -- Create the frequently used compares and arithmetic operations
    -------------------------------------------------------------------
    
     parent_dbeats_remaining_eq_0  <= True
       when parent_dbeats_remaining = 0
       else False;
      
     parent_dbeats_remaining_eq_1  <= True
       When parent_dbeats_remaining  = 1
       Else False;
    
     parent_dbeats_remaining_eq_2 <= True
       When parent_dbeats_remaining  = 2
       Else False;
     
     parent_dbeats_remaining_lt_MFBDBs <= True
       When parent_dbeats_remaining < MAX_FLBURST_DBEATS
       Else False;
    
       
   -------------------------------------------------------------------
       
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_DATA_ACKS
   --
   -- Process Description:
   --   This process registers the input data acknowledges.
   --
   -------------------------------------------------------------
   REG_DATA_ACKS : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst = '1') then
           
              sig_rdack_reg        <= '0';
              sig_wrack_reg        <= '0';
              sig_combined_ack_reg <= '0';
              
           
           else
           
              sig_rdack_reg        <= RdAck;
              sig_wrack_reg        <= WrAck;
              sig_combined_ack_reg <= sig_combined_ack;
           
           end if;        
        end if;
      end process REG_DATA_ACKS; 
      
 
 
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: REG_IP_QUALIFERS
   --
   -- Process Description:
   --    Sample and Hold registers for the Command qualifiers
   --
   -------------------------------------------------------------
   REG_IP_QUALIFERS : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst    = '1' or
               Clr_IP_Req = '1') then
              
              sig_ip2bus_rd_reg             <=  '0';
              sig_ip2bus_wr_reg             <=  '0';
              sig_be_reg                    <=  (others => '0');
              parent_xfer_single_reg        <=  '0';
              parent_xfer_flburst_reg       <=  '0';
              
           Elsif (New_IP_Req = '1') Then   -- latch the new IP qualifers
              
              sig_ip2bus_rd_reg             <=  IP2Mst_Rd;
              sig_ip2bus_wr_reg             <=  IP2Mst_Wr;
              sig_be_reg                    <=  IP2Mst_BE; 
              parent_xfer_single_reg        <=  not(IP2Mst_Type);
              parent_xfer_flburst_reg       <=  IP2Mst_Type ;
           
           else

             null;  -- hold state
           
           end if;        
        end if;
      end process REG_IP_QUALIFERS; 
 
 
 
 
    -------------------------------------------------------------
    -- Synchronous Process with Sync Reset
    --
    -- Label: REG_CMD_TYPE_STAT
    --
    -- Process Description:
    --     Sample and hold the type of command being requested.
    -- 
    --
    -------------------------------------------------------------
    REG_CMD_TYPE_STAT : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Rst = '1' or
                Clr_IP_Req = '1' or
                (dbeat_cnt_done_reg = '1' and
                 sig_combined_ack_reg = '1')) then
              
              doing_a_single_reg       <= '0';
              doing_a_fl_burst_reg     <= '0';
            
            elsif (Make_Bus_Req            = '1' and
                   sig_cmd_is_valid        = '1' and
                   sig_cmd_has_been_queued = '0') then  
            
              doing_a_single_reg       <= doing_a_single;
              doing_a_fl_burst_reg     <= doing_a_fl_burst;
            
            else
              null;  -- hold state
            end if;        
         end if;
       end process REG_CMD_TYPE_STAT; 
         
 
 
 
 
 
     -------------------------------------------------------------
     -- Synchronous Process with Sync Reset
     --
     -- Label: REG_CMD_QUEUED
     --
     -- Process Description:
     --     This process implements a flag that indicates that a 
     -- calculated command has been issued to the Controller.
     -- This inhibits new command qualifiers from being passed
     -- to the Controller while it is posting the on-going request
     -- to the PLB. 
     -------------------------------------------------------------
     REG_CMD_QUEUED : process (bus_clk)
        begin
          if (Bus_Clk'event and Bus_Clk = '1') then
             if (Bus_Rst    = '1' or
                 Clr_IP_Req = '1' or
                 New_IP_Req = '1' or
                 Make_Bus_Req = '0') then     

                sig_cmd_has_been_queued   <= '0';
                
             Elsif (sig_cmd_has_been_queued = '0') Then  
             
                sig_cmd_has_been_queued   <= sig_cmd_is_valid;
               
             else
               
               null;  -- hold last state  -- PCI Bug Cleanup
               
             end if;        
          end if;
        end process REG_CMD_QUEUED; 
     
     
         -------------------------------------------------------------
         -- Synchronous Process with Sync Reset
         --
         -- Label: GEN_CMD_INIT
         --
         -- Process Description:
         --
         --
         -------------------------------------------------------------
         GEN_CMD_INIT : process (bus_clk)
            begin
              if (Bus_Clk'event and Bus_Clk = '1') then
                 if (Bus_Rst = '1') then
                   
                   sig_cmd_init  <= '0';
                 
                 elsif (sig_cmd_is_valid        = '1' and
                        sig_cmd_has_been_queued = '0') then
                   
                   sig_cmd_init  <= '1';
                 
                 else
                   
                   sig_cmd_init  <= '0';
                 
                 end if;        
              end if;
            end process GEN_CMD_INIT; 
  
  
  
  
  
  
   -------------------------------------------------------------
   -- Synchronous Process with Sync Reset
   --
   -- Label: GEN_CMD_VALID
   --
   -- Process Description:
   --   This process generates the command valid indicator via
   -- a simple state machine.
   --
   -------------------------------------------------------------
   GEN_CMD_VALID : process (bus_clk)
      begin
        if (Bus_Clk'event and Bus_Clk = '1') then
           if (Bus_Rst               = '1' or   
               Clr_IP_Req            = '1' or   
               Make_Bus_Req          = '0' or   
               error_condition       = '1') then  
             
             sig_cmd_is_valid_s0  <= '0';
             sig_cmd_is_valid_s1  <= '0';
             sig_cmd_is_valid     <= '0';
                         
           elsif (Make_Bus_Req = '1') then  
             
            sig_cmd_is_valid  <=  '1';
            
            --  sig_cmd_is_valid_s0  <= '1';
            --  sig_cmd_is_valid_s1  <= sig_cmd_is_valid_s0;
            --  sig_cmd_is_valid     <= sig_cmd_is_valid_s1;
            
           else
             null; -- hold state
           end if;        
        end if;
      end process GEN_CMD_VALID; 
    
   
  
  
  
       -------------------------------------------------------------
       -- Synchronous Process with Sync Reset
       --
       -- Label: GEN_PCMD_DONE
       --
       -- Process Description:
       -- This process generates the parent command done flag.
       --
       -------------------------------------------------------------
       GEN_PCMD_DONE : process (bus_clk)
          begin
            if (Bus_Clk'event and Bus_Clk = '1') then
               if (Bus_Rst        = '1' or
                   Clr_IP_Req     = '1' or
                   New_IP_Req     = '1') then
                
                 parent_cmd_done <= '0';
               
               Elsif (sig_combined_ack_reg  = '1' and  
                      doing_a_single_reg    = '1') Then  
              
                  parent_cmd_done <= '1';
              
               Elsif (parent_dbeats_remaining_eq_1 and       
                      sig_combined_ack_reg  = '1' and
                      doing_a_fl_burst_reg  = '1') Then  
               
                  parent_cmd_done <= '1'; 
                   
               else
                 null;  -- don't change state
               end if;        
            end if;
          end process GEN_PCMD_DONE; 
       
       
  
  ----------------------------------------------------------------------------  
  -- Instantiate the Master address counter and support logic. This counter 
  -- keeps track of the current address value as transfer acknowledges occur.
  -- If a child command is spawned due to an exception, the counter provides
  -- the starting address and BE (if a single) for the child command to the 
  -- PLB.
   
   
   sig_clr_addr_cntr       <=  Bus_Rst or
                               Clr_IP_Req;
   
   addr_cnt_enable          <= sig_combined_ack and
                               parent_xfer_flburst_reg;
   
   
   sig_addr_incr_ld_enable  <= Make_Bus_Req and 
                               not(sig_cmd_has_been_queued);
  
   sig_addr_increment       <= CONV_STD_LOGIC_VECTOR(ADDRESS_INC_VALUE, 
                                                     C_LENGTH_WIDTH);
                   
   sig_ld_addr_cntr         <= New_IP_Req;
                                                                                           
                                                                         
                                                                         
                                                                         
   I_ADDR_CNTR : entity plbv46_master_burst_v1_00_a.plb_mstr_addr_gen
        generic map(
          C_AWIDTH             =>  C_PLB_AWIDTH,         
          C_INCR_WIDTH         =>  C_LENGTH_WIDTH,       
          C_REM_ADDR_LSB_WIDTH =>  NUM_BYTE_ADDR_BITS,   
          C_BUS_DWIDTH         =>  C_NATIVE_DWIDTH          
          )
        port map(
         -- inputs 
          Bus_Clk             =>  Bus_Clk,                  
          Bus_Rst             =>  sig_clr_addr_cntr,                  
          Parent_is_Burst     =>  parent_xfer_flburst_reg,    
          Address_Ld_Enable   =>  sig_ld_addr_cntr,               
          Address_In          =>  IP2Mst_Addr,            
          Address_Incr_Enable =>  addr_cnt_enable,          
          Strt_BE_In          =>  BE_ALL_CLR,             
          Incr_Ld_Enable      =>  sig_addr_incr_ld_enable,  
          Increment_In        =>  sig_addr_increment,      
          Use_Rem_Addr_Lsb    =>  False,     
          Rem_addr_lsb        =>  ADDR_LSB_ZEROS,  

         -- Outputs 
          Address_Out         =>  addr_cntr_address,        
          BE_Out              =>  open              
          );
    
  
  
  -----------------------------------------------------------------  
   
   
  sig_dbeat_count_ld_value <= MAX_FLBURST_DBEATS_MINUS_1 
      when (sig_flburst_is_max = '1')
      Else CONV_INTEGER('0' & sig_flburst_cnt);
   
   
                 
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: DBEAT_COUNTER
  --
  -- Process Description:
  --    This process implements the fixed length burst transfer 
  -- counter and support logic. This counter keeps track of the
  -- data beat count required to complete a single fixed length 
  -- burst transaction. The counter is down counted when
  -- a valid data ack is received. The fixed Length Burst is 
  -- completed when the counter reaches 0.
  --        
  -------------------------------------------------------------
  DBEAT_COUNTER : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst = '1') then
            dbeat_count <= 0;
          elsif (sig_cmd_init = '1') then
            dbeat_count <= sig_dbeat_count_ld_value;
          elsif (sig_flburst_cnten = '1' and 
                 dbeat_count       > 0) then
            dbeat_count <= dbeat_count-1;
          else
            null; -- hold the current value
          end if;        
       end if;
     end process DBEAT_COUNTER; 
 
  
  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: CHECK_DBEAT_DONE
  --
  -- Process Description:
  --    This process keeps track of the data beat count and 
  -- asserts flags when done or almost done.
  --
  -------------------------------------------------------------
  CHECK_DBEAT_DONE : process (dbeat_count)
    begin
  
      If (dbeat_count = 1) Then

          dbeat_cnt_done        <= '0';
          dbeat_cnt_almost_done <= '1';    
          
       Elsif (dbeat_count <= 0) Then

          dbeat_cnt_done        <= '1';
          dbeat_cnt_almost_done <= '0';    
          
       else       
              
          dbeat_cnt_done        <= '0';
          dbeat_cnt_almost_done <= '0';    
              
      End if;
  
    end process CHECK_DBEAT_DONE; 
  
  
  
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: REG_DBEAT_DONE
  --
  -- Process Description:
  --     Generates the Data beat done status flags.
  --
  -------------------------------------------------------------
  REG_DBEAT_DONE : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst         = '1' or
              Clr_IP_Req      = '1' or
             (Make_Bus_Req    = '1' and
              doing_a_single  = '0')) then
          
             dbeat_cnt_done_reg        <= '0';
             dbeat_cnt_almost_done_reg <= '0';
          
          Elsif (sig_combined_ack    = '1' and 
                 doing_a_single_reg  = '1') Then   
          
             dbeat_cnt_done_reg        <= '1';
             dbeat_cnt_almost_done_reg <= '0';
          
          
          Elsif (Make_Bus_Req    = '1' and 
                 doing_a_single  = '1') Then    
          
             dbeat_cnt_done_reg        <= '0';
             dbeat_cnt_almost_done_reg <= '1';
          
          
          Elsif (sig_combined_ack = '1') Then  
          
             dbeat_cnt_done_reg        <= dbeat_cnt_done       ;
             dbeat_cnt_almost_done_reg <= dbeat_cnt_almost_done;
             
          else
             null;  -- retain state
          end if;        
       end if;
     end process REG_DBEAT_DONE; 

  
    
    
 
                 
 
 
  -------------------------------------------------------------
  -- Synchronous Process with Sync Reset
  --
  -- Label: LENGTH_COUNTER
  --
  -- Process Description:
  -- Calculates remaining xfer length (in Native DWidth Units)
  --
  -------------------------------------------------------------
  LENGTH_COUNTER : process (bus_clk)
     begin
       if (Bus_Clk'event and Bus_Clk = '1') then
          if (Bus_Rst = '1') then
            parent_dbeats_remaining <= 0;
          elsif (New_IP_Req = '1') then
            --parent_dbeats_remaining <= sig_length_wrds_int;
            parent_dbeats_remaining <= sig_length_native_int;
          elsif (sig_flburst_cnten_reg = '1' and
                 not(parent_dbeats_remaining_eq_0)) then
            parent_dbeats_remaining <= parent_dbeats_remaining-1;
          else
            null; -- hold the current value
          end if;        
       end if;
     end process LENGTH_COUNTER; 
 
 
 
   parent_dbeats_remaining_slv <=  
           CONV_STD_LOGIC_VECTOR(parent_dbeats_remaining,
                                 C_LENGTH_WIDTH); 

  -- rip the lower 4 bits of the remaining length
  -- (in Native DWidth Units)
  sig_flburst_cnt_raw <= 
         parent_dbeats_remaining_slv(C_LENGTH_WIDTH-4 to 
                                     C_LENGTH_WIDTH-1);

 
 
  -------------------------------------------------------------
  -- Combinational Process
  --
  -- Label: GEN_FLBURST_CNT
  --
  -- Process Description:
  --    This process generates the down count value for a 
  -- fixed Length burst request. The value is used for both the
  -- data beat counter and the BE assignment for the PLB request.
  --
  -- Note: 
  -- The output value is only valid if the remaining data beats
  -- is less than or equal to 16.
  -------------------------------------------------------------
  GEN_FLBURST_CNT : process (sig_flburst_cnt_raw)
    begin
      
       case sig_flburst_cnt_raw is
         when "0010" =>
           sig_flburst_cnt     <= "0001";  
         when "0011" =>
           sig_flburst_cnt     <= "0010";  
         when "0100" =>
           sig_flburst_cnt     <= "0011";  
         when "0101" =>
           sig_flburst_cnt     <= "0100";  
         when "0110" =>
           sig_flburst_cnt     <= "0101";  
         when "0111" =>
           sig_flburst_cnt     <= "0110";  
         when "1000" =>
           sig_flburst_cnt     <= "0111";  
         when "1001" =>
           sig_flburst_cnt     <= "1000";  
         when "1010" =>
           sig_flburst_cnt     <= "1001";  
         when "1011" =>
           sig_flburst_cnt     <= "1010";  
         when "1100" =>
           sig_flburst_cnt     <= "1011";  
         when "1101" =>
           sig_flburst_cnt     <= "1100";  
         when "1110" =>
           sig_flburst_cnt     <= "1101";  
         when "1111" =>
           sig_flburst_cnt     <= "1110";  
         when others =>
           sig_flburst_cnt     <= "1111";  
       end case;
       
      
    end process GEN_FLBURST_CNT; 
  
  

 
 
 
 
  
 
     -------------------------------------------------------------
     -- Combinational Process
     --
     -- Label: GEN_PARENT_CMD_TYPE_INDET
     --
     -- Process Description:
     -- This process generates the parent command type.
     --
     -------------------------------------------------------------
     GEN_PARENT_CMD_TYPE_INDET : process (
                              Bus_Rst,
                              parent_xfer_single_reg,
                              parent_xfer_flburst_reg,
                              Make_Bus_Req
                              )

        begin
     
          if (Bus_Rst            = '1') then

             sig_calc_op <= IN_RESET; 
              
          Elsif (Make_Bus_Req = '0') Then
             
             sig_calc_op <= NO_OP;
                 
          elsif (parent_xfer_single_reg = '1') then
            
             sig_calc_op <= CALC_SINGLE;
          
          elsif (parent_xfer_flburst_reg = '1') then
            
             sig_calc_op <= CALC_FLBURST;
          
          else
            
             sig_calc_op <= NO_OP;
          
          end if;
     
        end process GEN_PARENT_CMD_TYPE_INDET; 
     
     

 
 
    -------------------------------------------------------------
    -- Combinational Process
    --
    -- Label: CMD_CALCULATOR
    --
    -- Process Description:
    --     This process calculates the command qualifier values
    -- for the Write command request to the PLB.
    --
    -------------------------------------------------------------
    CMD_CALCULATOR : process (
                    sig_calc_op,
                    parent_dbeats_remaining_eq_0,
                    parent_dbeats_remaining_eq_1,
                    parent_dbeats_remaining_lt_MFBDBs ,
                    sig_flburst_cnt,
                    sig_be_reg
                   )
       
      
       begin
 
         doing_a_single        <= '0';
         doing_a_fl_burst      <= '0';
         sig_flburst_is_max    <= '0';
         cmd_size              <= "0000"; -- single 
         cmd_be                <= (others => '0');
         error_condition       <= '0';      
    
         case sig_calc_op is

           ----------------------
           When IN_RESET | NO_OP  =>
           ----------------------
             
             null;  -- defaults apply for now 
                                   
           
           ----------------------
           when CALC_SINGLE =>
           ----------------------
            
             doing_a_single        <= '1';
             cmd_size              <= "0000"; -- single 
             cmd_be                <= sig_be_reg;
      
           
                   
           ----------------------
           when CALC_FLBURST =>
           ----------------------
           
             if (parent_dbeats_remaining_eq_0) then
             
                error_condition       <= '0';      
             
             elsif (parent_dbeats_remaining_eq_1) then
             
               doing_a_single        <= '1';
               cmd_size              <= SIZE_OF_SNGL; -- single 
               cmd_be                <= BE_ALL_SET;
             
             elsif (parent_dbeats_remaining_lt_MFBDBs) then
             
               doing_a_fl_burst      <= '1';
               --cmd_size              <= SIZE_OF_WRD; -- 32-bit burst 
               cmd_size              <= SIZE_OF_BRST_XFER; -- Native DWidth 
               cmd_be(0 to 3)        <= sig_flburst_cnt;
             
             else   -- Use Max data beat count
             
               doing_a_fl_burst      <= '1';
               sig_flburst_is_max    <= '1';
               --cmd_size              <= SIZE_OF_WRD; -- 32-bit burst 
               cmd_size              <= SIZE_OF_BRST_XFER; -- Native DWidth 
               cmd_be(0 to 3)        <= (others => '1'); -- 16 data beats
             
             end if;
             
             
           ----------------------
           when others =>    -- set to defaults
           ----------------------
                
             doing_a_single        <= '0';
             doing_a_fl_burst      <= '0';
             sig_flburst_is_max    <= '0';
             cmd_size              <= "0000"; -- single 
             cmd_be                <= (others => '0');
             error_condition       <= '0';      

               
         end case;
         
    
       end process CMD_CALCULATOR; 
    
  
       
        
 
 
 
 
end implementation;
