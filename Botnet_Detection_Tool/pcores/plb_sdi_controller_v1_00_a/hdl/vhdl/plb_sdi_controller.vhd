------------------------------------------------------------------------------
-- plb_sdi_controller.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          plb_sdi_controller.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Thu Mar 26 21:03:08 2009 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
-- PROJECT      : PICSY
-- AUTHOR       : Felix & Ali (University of Potsdam, Computer Science Department)
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.ipif_pkg.all;

library interrupt_control_v2_00_a;
use interrupt_control_v2_00_a.interrupt_control;

library plbv46_slave_single_v1_00_a;
use plbv46_slave_single_v1_00_a.plbv46_slave_single;

library plbv46_master_burst_v1_00_a;
use plbv46_master_burst_v1_00_a.plbv46_master_burst;

library plb_sdi_controller_v1_00_a;
use plb_sdi_controller_v1_00_a.user_logic;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_BASEADDR                   -- PLBv46 slave: base address
--   C_HIGHADDR                   -- PLBv46 slave: high address
--   C_SPLB_AWIDTH                -- PLBv46 slave: address bus width
--   C_SPLB_DWIDTH                -- PLBv46 slave: data bus width
--   C_SPLB_NUM_MASTERS           -- PLBv46 slave: Number of masters
--   C_SPLB_MID_WIDTH             -- PLBv46 slave: master ID bus width
--   C_SPLB_NATIVE_DWIDTH         -- PLBv46 slave: internal native data bus width
--   C_SPLB_P2P                   -- PLBv46 slave: point to point interconnect scheme
--   C_SPLB_SUPPORT_BURSTS        -- PLBv46 slave: support bursts
--   C_SPLB_SMALLEST_MASTER       -- PLBv46 slave: width of the smallest master
--   C_SPLB_CLK_PERIOD_PS         -- PLBv46 slave: bus clock in picoseconds
--   C_INCLUDE_DPHASE_TIMER       -- PLBv46 slave: Data Phase Timer configuration; 0 = exclude timer, 1 = include timer
--   C_FAMILY                     -- Xilinx FPGA family
--   C_MPLB_AWIDTH                -- PLBv46 master: address bus width
--   C_MPLB_DWIDTH                -- PLBv46 master: data bus width
--   C_MPLB_NATIVE_DWIDTH         -- PLBv46 master: internal native data width
--   C_MPLB_P2P                   -- PLBv46 master: point to point interconnect scheme
--   C_MPLB_SMALLEST_SLAVE        -- PLBv46 master: width of the smallest slave
--   C_MPLB_CLK_PERIOD_PS         -- PLBv46 master: bus clock in picoseconds
--
-- Definition of Ports:
--   SPLB_Clk                     -- PLB main bus clock
--   SPLB_Rst                     -- PLB main bus reset
--   PLB_ABus                     -- PLB address bus
--   PLB_UABus                    -- PLB upper address bus
--   PLB_PAValid                  -- PLB primary address valid indicator
--   PLB_SAValid                  -- PLB secondary address valid indicator
--   PLB_rdPrim                   -- PLB secondary to primary read request indicator
--   PLB_wrPrim                   -- PLB secondary to primary write request indicator
--   PLB_masterID                 -- PLB current master identifier
--   PLB_abort                    -- PLB abort request indicator
--   PLB_busLock                  -- PLB bus lock
--   PLB_RNW                      -- PLB read/not write
--   PLB_BE                       -- PLB byte enables
--   PLB_MSize                    -- PLB master data bus size
--   PLB_size                     -- PLB transfer size
--   PLB_type                     -- PLB transfer type
--   PLB_lockErr                  -- PLB lock error indicator
--   PLB_wrDBus                   -- PLB write data bus
--   PLB_wrBurst                  -- PLB burst write transfer indicator
--   PLB_rdBurst                  -- PLB burst read transfer indicator
--   PLB_wrPendReq                -- PLB write pending bus request indicator
--   PLB_rdPendReq                -- PLB read pending bus request indicator
--   PLB_wrPendPri                -- PLB write pending request priority
--   PLB_rdPendPri                -- PLB read pending request priority
--   PLB_reqPri                   -- PLB current request priority
--   PLB_TAttribute               -- PLB transfer attribute
--   Sl_addrAck                   -- Slave address acknowledge
--   Sl_SSize                     -- Slave data bus size
--   Sl_wait                      -- Slave wait indicator
--   Sl_rearbitrate               -- Slave re-arbitrate bus indicator
--   Sl_wrDAck                    -- Slave write data acknowledge
--   Sl_wrComp                    -- Slave write transfer complete indicator
--   Sl_wrBTerm                   -- Slave terminate write burst transfer
--   Sl_rdDBus                    -- Slave read data bus
--   Sl_rdWdAddr                  -- Slave read word address
--   Sl_rdDAck                    -- Slave read data acknowledge
--   Sl_rdComp                    -- Slave read transfer complete indicator
--   Sl_rdBTerm                   -- Slave terminate read burst transfer
--   Sl_MBusy                     -- Slave busy indicator
--   Sl_MWrErr                    -- Slave write error indicator
--   Sl_MRdErr                    -- Slave read error indicator
--   Sl_MIRQ                      -- Slave interrupt indicator
--   MPLB_Clk                     -- PLB main bus Clock
--   MPLB_Rst                     -- PLB main bus Reset
--   MD_error                     -- Master detected error status output
--   M_request                    -- Master request
--   M_priority                   -- Master request priority
--   M_busLock                    -- Master buslock
--   M_RNW                        -- Master read/nor write
--   M_BE                         -- Master byte enables
--   M_MSize                      -- Master data bus size
--   M_size                       -- Master transfer size
--   M_type                       -- Master transfer type
--   M_TAttribute                 -- Master transfer attribute
--   M_lockErr                    -- Master lock error indicator
--   M_abort                      -- Master abort bus request indicator
--   M_UABus                      -- Master upper address bus
--   M_ABus                       -- Master address bus
--   M_wrDBus                     -- Master write data bus
--   M_wrBurst                    -- Master burst write transfer indicator
--   M_rdBurst                    -- Master burst read transfer indicator
--   PLB_MAddrAck                 -- PLB reply to master for address acknowledge
--   PLB_MSSize                   -- PLB reply to master for slave data bus size
--   PLB_MRearbitrate             -- PLB reply to master for bus re-arbitrate indicator
--   PLB_MTimeout                 -- PLB reply to master for bus time out indicator
--   PLB_MBusy                    -- PLB reply to master for slave busy indicator
--   PLB_MRdErr                   -- PLB reply to master for slave read error indicator
--   PLB_MWrErr                   -- PLB reply to master for slave write error indicator
--   PLB_MIRQ                     -- PLB reply to master for slave interrupt indicator
--   PLB_MRdDBus                  -- PLB reply to master for read data bus
--   PLB_MRdWdAddr                -- PLB reply to master for read word address
--   PLB_MRdDAck                  -- PLB reply to master for read data acknowledge
--   PLB_MRdBTerm                 -- PLB reply to master for terminate read burst indicator
--   PLB_MWrDAck                  -- PLB reply to master for write data acknowledge
--   PLB_MWrBTerm                 -- PLB reply to master for terminate write burst indicator
--   IP2INTC_Irpt                 -- Interrupt output to processor
------------------------------------------------------------------------------

entity plb_sdi_controller is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
  ------------------------------------------
  -- added by akzare: started here
  ------------------------------------------    
    C_DEBUG_DWIDTH                 : integer              := 32;	
    C_OPERATION_MODE               : integer              := 0;	
    C_NUM_PU_CONFIG_REGS           : integer              := 1;	
    C_NUM_PU_STATUS_REGS           : integer              := 1;	
    C_FIFO_IMPLEMENTATION_TYPE	   : integer              := 1;   -- 0 = Any, 1 = BRAM, 2 = Dist.Memory, 3 = Shift Regs
    C_FIFO_DEPTH						       : integer              := 1024;
  ------------------------------------------
  -- added by akzare: ended here
  ------------------------------------------
	 
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_SPLB_AWIDTH                  : integer              := 32;
    C_SPLB_DWIDTH                  : integer              := 128;
    C_SPLB_NUM_MASTERS             : integer              := 8;
    C_SPLB_MID_WIDTH               : integer              := 3;
    C_SPLB_NATIVE_DWIDTH           : integer              := 32;
    C_SPLB_P2P                     : integer              := 0;
    C_SPLB_SUPPORT_BURSTS          : integer              := 0;
    C_SPLB_SMALLEST_MASTER         : integer              := 32;
    C_SPLB_CLK_PERIOD_PS           : integer              := 10000;
    C_INCLUDE_DPHASE_TIMER         : integer              := 1;
    C_FAMILY                       : string               := "virtex4";
    C_MPLB_AWIDTH                  : integer              := 32;
    C_MPLB_DWIDTH                  : integer              := 128;
    C_MPLB_NATIVE_DWIDTH           : integer              := 64;
    C_MPLB_P2P                     : integer              := 0;
    C_MPLB_SMALLEST_SLAVE          : integer              := 32;
    C_MPLB_CLK_PERIOD_PS           : integer              := 10000
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    DEBUG_D_I  	   					: in std_logic_vector (C_DEBUG_DWIDTH-1 downto 0);    
    DEBUG_D_O  	   					: out std_logic_vector (C_DEBUG_DWIDTH-1 downto 0);    
    DEBUG_D_T  	   					: out std_logic_vector (C_DEBUG_DWIDTH-1 downto 0);    
	 
    -- SDI Interface ------------------------------------------------------------------
    stream_out_clk						: in	std_logic;
    stream_out_stop						: in	std_logic;
    stream_out_valid					: out	std_logic;
    stream_out_data						: out	std_logic_vector(C_MPLB_NATIVE_DWIDTH-1 downto 0);
    stream_in_clk							: in	std_logic;
    stream_in_stop						: out	std_logic;
    stream_in_valid						: in	std_logic;
    stream_in_data						: in	std_logic_vector(C_MPLB_NATIVE_DWIDTH-1 downto 0);

    pu_reset                  : out	std_logic;	
    pu_sof                    : out std_logic;
    pu_sof_ack                : in std_logic;
    pu_eof                    : in std_logic;
    pu_eof_ack                : out std_logic;
    request_frame             : in std_logic;
    request_frame_ack         : out std_logic;

    -- PU Registers ---------------------------------------------------------------------
    pu_config_regs				    : out	std_logic_vector(C_NUM_PU_CONFIG_REGS*C_SPLB_NATIVE_DWIDTH-1 downto 0);
    pu_status_regs		        : in	std_logic_vector(C_NUM_PU_STATUS_REGS*C_SPLB_NATIVE_DWIDTH-1 downto 0);

    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    SPLB_Clk                       : in  std_logic;
    SPLB_Rst                       : in  std_logic;
    PLB_ABus                       : in  std_logic_vector(0 to 31);
    PLB_UABus                      : in  std_logic_vector(0 to 31);
    PLB_PAValid                    : in  std_logic;
    PLB_SAValid                    : in  std_logic;
    PLB_rdPrim                     : in  std_logic;
    PLB_wrPrim                     : in  std_logic;
    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort                      : in  std_logic;
    PLB_busLock                    : in  std_logic;
    PLB_RNW                        : in  std_logic;
    PLB_BE                         : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
    PLB_MSize                      : in  std_logic_vector(0 to 1);
    PLB_size                       : in  std_logic_vector(0 to 3);
    PLB_type                       : in  std_logic_vector(0 to 2);
    PLB_lockErr                    : in  std_logic;
    PLB_wrDBus                     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst                    : in  std_logic;
    PLB_rdBurst                    : in  std_logic;
    PLB_wrPendReq                  : in  std_logic;
    PLB_rdPendReq                  : in  std_logic;
    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
    PLB_reqPri                     : in  std_logic_vector(0 to 1);
    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
    Sl_addrAck                     : out std_logic;
    Sl_SSize                       : out std_logic_vector(0 to 1);
    Sl_wait                        : out std_logic;
    Sl_rearbitrate                 : out std_logic;
    Sl_wrDAck                      : out std_logic;
    Sl_wrComp                      : out std_logic;
    Sl_wrBTerm                     : out std_logic;
    Sl_rdDBus                      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                    : out std_logic_vector(0 to 3);
    Sl_rdDAck                      : out std_logic;
    Sl_rdComp                      : out std_logic;
    Sl_rdBTerm                     : out std_logic;
    Sl_MBusy                       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ                        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    MPLB_Clk                       : in  std_logic;
    MPLB_Rst                       : in  std_logic;
    MD_error                       : out std_logic;
    M_request                      : out std_logic;
    M_priority                     : out std_logic_vector(0 to 1);
    M_busLock                      : out std_logic;
    M_RNW                          : out std_logic;
    M_BE                           : out std_logic_vector(0 to C_MPLB_DWIDTH/8-1);
    M_MSize                        : out std_logic_vector(0 to 1);
    M_size                         : out std_logic_vector(0 to 3);
    M_type                         : out std_logic_vector(0 to 2);
    M_TAttribute                   : out std_logic_vector(0 to 15);
    M_lockErr                      : out std_logic;
    M_abort                        : out std_logic;
    M_UABus                        : out std_logic_vector(0 to 31);
    M_ABus                         : out std_logic_vector(0 to 31);
    M_wrDBus                       : out std_logic_vector(0 to C_MPLB_DWIDTH-1);
    M_wrBurst                      : out std_logic;
    M_rdBurst                      : out std_logic;
    PLB_MAddrAck                   : in  std_logic;
    PLB_MSSize                     : in  std_logic_vector(0 to 1);
    PLB_MRearbitrate               : in  std_logic;
    PLB_MTimeout                   : in  std_logic;
    PLB_MBusy                      : in  std_logic;
    PLB_MRdErr                     : in  std_logic;
    PLB_MWrErr                     : in  std_logic;
    PLB_MIRQ                       : in  std_logic;
    PLB_MRdDBus                    : in  std_logic_vector(0 to (C_MPLB_DWIDTH-1));
    PLB_MRdWdAddr                  : in  std_logic_vector(0 to 3);
    PLB_MRdDAck                    : in  std_logic;
    PLB_MRdBTerm                   : in  std_logic;
    PLB_MWrDAck                    : in  std_logic;
    PLB_MWrBTerm                   : in  std_logic;
    IP2INTC_Irpt                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of SPLB_Clk      : signal is "CLK";
  attribute SIGIS of MPLB_Clk      : signal is "CLK";
  attribute SIGIS of SPLB_Rst      : signal is "RST";
  attribute SIGIS of MPLB_Rst      : signal is "RST";
  attribute SIGIS of IP2INTC_Irpt  : signal is "INTR_LEVEL_HIGH";

end entity plb_sdi_controller;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of plb_sdi_controller is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
  constant CONTROLLER_BASEADDR            : std_logic_vector     := C_BASEADDR or X"00000000";
  constant CONTROLLER_HIGHADDR            : std_logic_vector     := C_BASEADDR or X"000000FF";
  constant INTR_BASEADDR                  : std_logic_vector     := C_BASEADDR or X"00000100";
  constant INTR_HIGHADDR                  : std_logic_vector     := C_BASEADDR or X"000001FF";

  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
    (
      ZERO_ADDR_PAD & CONTROLLER_BASEADDR,  -- controller space base address
      ZERO_ADDR_PAD & CONTROLLER_HIGHADDR,  -- controller space high address
      ZERO_ADDR_PAD & INTR_BASEADDR,        -- interrupt control space base address
      ZERO_ADDR_PAD & INTR_HIGHADDR         -- interrupt control space high address
    );

  -- FIXME: use function from std_logic_arith
  function max(L, R: INTEGER) return INTEGER is
  begin
    if L > R then
      return L;
    else
      return R;
    end if;
  end;

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  constant PU_NUM_REG                     : integer              := max(C_NUM_PU_CONFIG_REGS, C_NUM_PU_STATUS_REGS);

  constant CONTROLLER_NUM_REG             : integer              := 9 + PU_NUM_REG;

  constant INTR_NUM_CE                    : integer              := 16;

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(CONTROLLER_NUM_REG), -- number of ce for controller space
      1  => INTR_NUM_CE                     -- number of ce for interrupt control space
    );

  ------------------------------------------
  -- Ratio of bus clock to core clock (for use in dual clock systems)
  -- 1 = ratio is 1:1
  -- 2 = ratio is 2:1
  ------------------------------------------
  constant IPIF_BUS2CORE_CLK_RATIO        : integer              := 1;

  ------------------------------------------
  -- Width of the slave data bus (32 only)
  ------------------------------------------
  constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the master data bus (32, 64, or 128)
  ------------------------------------------
  constant USER_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  constant IPIF_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Inhibit the automatic inculsion of the Conversion Cycle and Burst Length Expansion logic
  -- 0 = allow automatic inclusion of the CC and BLE logic
  -- 1 = inhibit automatic inclusion of the CC and BLE logic
  ------------------------------------------
  constant IPIF_INHIBIT_CC_BLE_INCLUSION  : integer              := 0;

  ------------------------------------------
  -- Number of device level interrupts
  ------------------------------------------
  constant INTR_NUM_IPIF_IRPT_SRC         : integer              := 4;

  ------------------------------------------
  -- Capture mode for each IP interrupt (generated by user logic)
  -- 1 = pass through (non-inverting)
  -- 2 = pass through (inverting)
  -- 3 = registered level (non-inverting)
  -- 4 = registered level (inverting)
  -- 5 = positive edge detect
  -- 6 = negative edge detect
  ------------------------------------------
  constant USER_NUM_INTR                  : integer              := 32;
  constant USER_INTR_CAPTURE_MODE         : integer              := 5;

  constant INTR_IP_INTR_MODE_ARRAY        : INTEGER_ARRAY_TYPE   := 
    (
      0  => USER_INTR_CAPTURE_MODE,
      1  => USER_INTR_CAPTURE_MODE,
      2  => USER_INTR_CAPTURE_MODE,
      3  => USER_INTR_CAPTURE_MODE,
      4  => USER_INTR_CAPTURE_MODE,
      5  => USER_INTR_CAPTURE_MODE,
      6  => USER_INTR_CAPTURE_MODE,
      7  => USER_INTR_CAPTURE_MODE,
      8  => USER_INTR_CAPTURE_MODE,
      9  => USER_INTR_CAPTURE_MODE,
      10 => USER_INTR_CAPTURE_MODE,
      11 => USER_INTR_CAPTURE_MODE,
      12 => USER_INTR_CAPTURE_MODE,
      13 => USER_INTR_CAPTURE_MODE,
      14 => USER_INTR_CAPTURE_MODE,
      15 => USER_INTR_CAPTURE_MODE,
      16 => USER_INTR_CAPTURE_MODE,
      17 => USER_INTR_CAPTURE_MODE,
      18 => USER_INTR_CAPTURE_MODE,
      19 => USER_INTR_CAPTURE_MODE,
      20 => USER_INTR_CAPTURE_MODE,
      21 => USER_INTR_CAPTURE_MODE,
      22 => USER_INTR_CAPTURE_MODE,
      23 => USER_INTR_CAPTURE_MODE,
      24 => USER_INTR_CAPTURE_MODE,
      25 => USER_INTR_CAPTURE_MODE,
      26 => USER_INTR_CAPTURE_MODE,
      27 => USER_INTR_CAPTURE_MODE,
      28 => USER_INTR_CAPTURE_MODE,
      29 => USER_INTR_CAPTURE_MODE,
      30 => USER_INTR_CAPTURE_MODE,
      31 => USER_INTR_CAPTURE_MODE 
    );

  ------------------------------------------
  -- Device priority encoder feature inclusion/omission
  -- true  = include priority encoder
  -- false = omit priority encoder
  ------------------------------------------
  constant INTR_INCLUDE_DEV_PENCODER      : boolean              := true;

  ------------------------------------------
  -- Device ISC feature inclusion/omission
  -- true  = include device ISC
  -- false = omit device ISC
  ------------------------------------------
  constant INTR_INCLUDE_DEV_ISC           : boolean              := true;

  ------------------------------------------
  -- Width of the master address bus (32 only)
  ------------------------------------------
  constant USER_MST_AWIDTH                : integer              := C_MPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant CONTROLLER_CS_INDEX            : integer              := 0;
  constant CONTROLLER_CE_INDEX            : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, CONTROLLER_CS_INDEX);
  constant INTR_CS_INDEX                  : integer              := 1;
  constant INTR_CE_INDEX                  : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, INTR_CS_INDEX);

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Reset              : std_logic;
  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_Bus2IP_RNW                : std_logic;
  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_IP2Bus_MstRd_Req          : std_logic;
  signal ipif_IP2Bus_MstWr_Req          : std_logic;
  signal ipif_IP2Bus_Mst_Addr           : std_logic_vector(0 to C_MPLB_AWIDTH-1);
  signal ipif_IP2Bus_Mst_Length         : std_logic_vector(0 to 11);
  signal ipif_IP2Bus_Mst_BE             : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_Mst_Type           : std_logic;
  signal ipif_IP2Bus_Mst_Lock           : std_logic;
  signal ipif_IP2Bus_Mst_Reset          : std_logic;
  signal ipif_Bus2IP_Mst_CmdAck         : std_logic;
  signal ipif_Bus2IP_Mst_Cmplt          : std_logic;
  signal ipif_Bus2IP_Mst_Error          : std_logic;
  signal ipif_Bus2IP_Mst_Rearbitrate    : std_logic;
  signal ipif_Bus2IP_Mst_Cmd_Timeout    : std_logic;
  signal ipif_Bus2IP_MstRd_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_Bus2IP_MstRd_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_Bus2IP_MstRd_sof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_eof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_src_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstRd_src_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstWr_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_IP2Bus_MstWr_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_MstWr_sof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_eof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_src_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstWr_src_dsc_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_dsc_n    : std_logic;
  signal intr_IPIF_Reg_Interrupts       : std_logic_vector(0 to 1);
  signal intr_IPIF_Lvl_Interrupts       : std_logic_vector(0 to INTR_NUM_IPIF_IRPT_SRC-1);
  signal intr_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal intr_IP2Bus_WrAck              : std_logic;
  signal intr_IP2Bus_RdAck              : std_logic;
  signal intr_IP2Bus_Error              : std_logic;
  signal user_Bus2IP_RdCE               : std_logic_vector(0 to CONTROLLER_NUM_REG-1);
  signal user_Bus2IP_WrCE               : std_logic_vector(0 to CONTROLLER_NUM_REG-1);
  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;
  signal user_IP2Bus_IntrEvent          : std_logic_vector(0 to USER_NUM_INTR-1);

begin

  ------------------------------------------
  -- instantiate plbv46_slave_single
  ------------------------------------------
  PLBV46_SLAVE_SINGLE_I : entity plbv46_slave_single_v1_00_a.plbv46_slave_single
    generic map
    (
      C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
      C_SPLB_P2P                     => C_SPLB_P2P,
      C_BUS2CORE_CLK_RATIO           => IPIF_BUS2CORE_CLK_RATIO,
      C_SPLB_MID_WIDTH               => C_SPLB_MID_WIDTH,
      C_SPLB_NUM_MASTERS             => C_SPLB_NUM_MASTERS,
      C_SPLB_AWIDTH                  => C_SPLB_AWIDTH,
      C_SPLB_DWIDTH                  => C_SPLB_DWIDTH,
      C_SIPIF_DWIDTH                 => IPIF_SLV_DWIDTH,
      C_INCLUDE_DPHASE_TIMER         => C_INCLUDE_DPHASE_TIMER,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      SPLB_Clk                       => SPLB_Clk,
      SPLB_Rst                       => SPLB_Rst,
      PLB_ABus                       => PLB_ABus,
      PLB_UABus                      => PLB_UABus,
      PLB_PAValid                    => PLB_PAValid,
      PLB_SAValid                    => PLB_SAValid,
      PLB_rdPrim                     => PLB_rdPrim,
      PLB_wrPrim                     => PLB_wrPrim,
      PLB_masterID                   => PLB_masterID,
      PLB_abort                      => PLB_abort,
      PLB_busLock                    => PLB_busLock,
      PLB_RNW                        => PLB_RNW,
      PLB_BE                         => PLB_BE,
      PLB_MSize                      => PLB_MSize,
      PLB_size                       => PLB_size,
      PLB_type                       => PLB_type,
      PLB_lockErr                    => PLB_lockErr,
      PLB_wrDBus                     => PLB_wrDBus,
      PLB_wrBurst                    => PLB_wrBurst,
      PLB_rdBurst                    => PLB_rdBurst,
      PLB_wrPendReq                  => PLB_wrPendReq,
      PLB_rdPendReq                  => PLB_rdPendReq,
      PLB_wrPendPri                  => PLB_wrPendPri,
      PLB_rdPendPri                  => PLB_rdPendPri,
      PLB_reqPri                     => PLB_reqPri,
      PLB_TAttribute                 => PLB_TAttribute,
      Sl_addrAck                     => Sl_addrAck,
      Sl_SSize                       => Sl_SSize,
      Sl_wait                        => Sl_wait,
      Sl_rearbitrate                 => Sl_rearbitrate,
      Sl_wrDAck                      => Sl_wrDAck,
      Sl_wrComp                      => Sl_wrComp,
      Sl_wrBTerm                     => Sl_wrBTerm,
      Sl_rdDBus                      => Sl_rdDBus,
      Sl_rdWdAddr                    => Sl_rdWdAddr,
      Sl_rdDAck                      => Sl_rdDAck,
      Sl_rdComp                      => Sl_rdComp,
      Sl_rdBTerm                     => Sl_rdBTerm,
      Sl_MBusy                       => Sl_MBusy,
      Sl_MWrErr                      => Sl_MWrErr,
      Sl_MRdErr                      => Sl_MRdErr,
      Sl_MIRQ                        => Sl_MIRQ,
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      IP2Bus_Data                    => ipif_IP2Bus_Data,
      IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
      IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
      IP2Bus_Error                   => ipif_IP2Bus_Error,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE
    );

  ------------------------------------------
  -- instantiate plbv46_master_burst
  ------------------------------------------
  PLBV46_MASTER_BURST_I : entity plbv46_master_burst_v1_00_a.plbv46_master_burst
    generic map
    (
      C_MPLB_AWIDTH                  => C_MPLB_AWIDTH,
      C_MPLB_DWIDTH                  => C_MPLB_DWIDTH,
      C_MPLB_NATIVE_DWIDTH           => IPIF_MST_DWIDTH,
      C_MPLB_SMALLEST_SLAVE          => C_MPLB_SMALLEST_SLAVE,
      C_INHIBIT_CC_BLE_INCLUSION     => IPIF_INHIBIT_CC_BLE_INCLUSION,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      MPLB_Clk                       => MPLB_Clk,
      MPLB_Rst                       => MPLB_Rst,
      MD_error                       => MD_error,
      M_request                      => M_request,
      M_priority                     => M_priority,
      M_busLock                      => M_busLock,
      M_RNW                          => M_RNW,
      M_BE                           => M_BE,
      M_MSize                        => M_MSize,
      M_size                         => M_size,
      M_type                         => M_type,
      M_TAttribute                   => M_TAttribute,
      M_lockErr                      => M_lockErr,
      M_abort                        => M_abort,
      M_UABus                        => M_UABus,
      M_ABus                         => M_ABus,
      M_wrDBus                       => M_wrDBus,
      M_wrBurst                      => M_wrBurst,
      M_rdBurst                      => M_rdBurst,
      PLB_MAddrAck                   => PLB_MAddrAck,
      PLB_MSSize                     => PLB_MSSize,
      PLB_MRearbitrate               => PLB_MRearbitrate,
      PLB_MTimeout                   => PLB_MTimeout,
      PLB_MBusy                      => PLB_MBusy,
      PLB_MRdErr                     => PLB_MRdErr,
      PLB_MWrErr                     => PLB_MWrErr,
      PLB_MIRQ                       => PLB_MIRQ,
      PLB_MRdDBus                    => PLB_MRdDBus,
      PLB_MRdWdAddr                  => PLB_MRdWdAddr,
      PLB_MRdDAck                    => PLB_MRdDAck,
      PLB_MRdBTerm                   => PLB_MRdBTerm,
      PLB_MWrDAck                    => PLB_MWrDAck,
      PLB_MWrBTerm                   => PLB_MWrBTerm,
      IP2Bus_MstRd_Req               => ipif_IP2Bus_MstRd_Req,
      IP2Bus_MstWr_Req               => ipif_IP2Bus_MstWr_Req,
      IP2Bus_Mst_Addr                => ipif_IP2Bus_Mst_Addr,
      IP2Bus_Mst_Length              => ipif_IP2Bus_Mst_Length,
      IP2Bus_Mst_BE                  => ipif_IP2Bus_Mst_BE,
      IP2Bus_Mst_Type                => ipif_IP2Bus_Mst_Type,
      IP2Bus_Mst_Lock                => ipif_IP2Bus_Mst_Lock,
      IP2Bus_Mst_Reset               => ipif_IP2Bus_Mst_Reset,
      Bus2IP_Mst_CmdAck              => ipif_Bus2IP_Mst_CmdAck,
      Bus2IP_Mst_Cmplt               => ipif_Bus2IP_Mst_Cmplt,
      Bus2IP_Mst_Error               => ipif_Bus2IP_Mst_Error,
      Bus2IP_Mst_Rearbitrate         => ipif_Bus2IP_Mst_Rearbitrate,
      Bus2IP_Mst_Cmd_Timeout         => ipif_Bus2IP_Mst_Cmd_Timeout,
      Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
      Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
      Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
      Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
      Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
      Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
      IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
      IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
      IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
      IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
      IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
      IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
      IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
      IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
      Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
      Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n
    );

  ------------------------------------------
  -- instantiate interrupt_control
  ------------------------------------------
  INTERRUPT_CONTROL_I : entity interrupt_control_v2_00_a.interrupt_control
    generic map
    (
      C_NUM_CE                       => INTR_NUM_CE,
      C_NUM_IPIF_IRPT_SRC            => INTR_NUM_IPIF_IRPT_SRC,
      C_IP_INTR_MODE_ARRAY           => INTR_IP_INTR_MODE_ARRAY,
      C_INCLUDE_DEV_PENCODER         => INTR_INCLUDE_DEV_PENCODER,
      C_INCLUDE_DEV_ISC              => INTR_INCLUDE_DEV_ISC,
      C_IPIF_DWIDTH                  => IPIF_SLV_DWIDTH
    )
    port map
    (
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Interrupt_RdCE                 => ipif_Bus2IP_RdCE(INTR_CE_INDEX to INTR_CE_INDEX+INTR_NUM_CE-1),
      Interrupt_WrCE                 => ipif_Bus2IP_WrCE(INTR_CE_INDEX to INTR_CE_INDEX+INTR_NUM_CE-1),
      IPIF_Reg_Interrupts            => intr_IPIF_Reg_Interrupts,
      IPIF_Lvl_Interrupts            => intr_IPIF_Lvl_Interrupts,
      IP2Bus_IntrEvent               => user_IP2Bus_IntrEvent,
      Intr2Bus_DevIntr               => IP2INTC_Irpt,
      Intr2Bus_DBus                  => intr_IP2Bus_Data,
      Intr2Bus_WrAck                 => intr_IP2Bus_WrAck,
      Intr2Bus_RdAck                 => intr_IP2Bus_RdAck,
      Intr2Bus_Error                 => intr_IP2Bus_Error,
      Intr2Bus_Retry                 => open,
      Intr2Bus_ToutSup               => open
    );

  -- feed registered and level-pass-through interrupts into Device ISC if exists, otherwise ignored
  intr_IPIF_Reg_Interrupts(0) <= '0';
  intr_IPIF_Reg_Interrupts(1) <= '0';
  intr_IPIF_Lvl_Interrupts(0) <= '0';
  intr_IPIF_Lvl_Interrupts(1) <= '0';
  intr_IPIF_Lvl_Interrupts(2) <= '0';
  intr_IPIF_Lvl_Interrupts(3) <= '0';

  ------------------------------------------
  -- instantiate User Logic
  ------------------------------------------
  USER_LOGIC_I : entity plb_sdi_controller_v1_00_a.user_logic
    generic map
    (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      C_DEBUG_DWIDTH              => C_DEBUG_DWIDTH,
      C_OPERATION_MODE            => C_OPERATION_MODE,	
      C_NUM_PU_CONFIG_REGS        => C_NUM_PU_CONFIG_REGS,	
      C_NUM_PU_STATUS_REGS        => C_NUM_PU_STATUS_REGS,
      C_FIFO_IMPLEMENTATION_TYPE  => C_FIFO_IMPLEMENTATION_TYPE,
      C_FIFO_DEPTH                => C_FIFO_DEPTH,		
      C_FAMILY                    => C_FAMILY,
		
      -- MAP USER GENERICS ABOVE THIS LINE ---------------
      C_SLV_DWIDTH                   => USER_SLV_DWIDTH,
      C_MST_AWIDTH                   => USER_MST_AWIDTH,
      C_MST_DWIDTH                   => USER_MST_DWIDTH,
      C_NUM_REG                      => CONTROLLER_NUM_REG,
      C_NUM_INTR                     => USER_NUM_INTR
    )
    port map
    (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      --USER ports mapped here
  ------------------------------------------
  -- added by akzare: started here
  ------------------------------------------      
      DEBUG_D_I => DEBUG_D_I,
      DEBUG_D_O => DEBUG_D_O,
      DEBUG_D_T => DEBUG_D_T,
	 
      stream_out_clk => stream_out_clk,
      stream_out_stop => stream_out_stop,
      stream_out_valid => stream_out_valid, 						
      stream_out_data => stream_out_data, 						
      stream_in_clk => stream_in_clk,
      stream_in_stop => stream_in_stop, 						
      stream_in_valid => stream_in_valid,						
      stream_in_data => stream_in_data,						

      pu_reset => pu_reset,
      pu_sof => pu_sof,
      pu_sof_ack => pu_sof_ack,
      pu_eof => pu_eof,
      pu_eof_ack => pu_eof_ack,
      request_frame => request_frame,
      request_frame_ack => request_frame_ack,

      pu_config_regs_vector => pu_config_regs,
      pu_status_regs_vector => pu_status_regs,

  ------------------------------------------
  -- added by akzare: ended here
  ------------------------------------------
		
      -- MAP USER PORTS ABOVE THIS LINE ------------------
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_RdCE                    => user_Bus2IP_RdCE,
      Bus2IP_WrCE                    => user_Bus2IP_WrCE,
      IP2Bus_Data                    => user_IP2Bus_Data,
      IP2Bus_RdAck                   => user_IP2Bus_RdAck,
      IP2Bus_WrAck                   => user_IP2Bus_WrAck,
      IP2Bus_Error                   => user_IP2Bus_Error,
      IP2Bus_MstRd_Req               => ipif_IP2Bus_MstRd_Req,
      IP2Bus_MstWr_Req               => ipif_IP2Bus_MstWr_Req,
      IP2Bus_Mst_Addr                => ipif_IP2Bus_Mst_Addr,
      IP2Bus_Mst_BE                  => ipif_IP2Bus_Mst_BE,
      IP2Bus_Mst_Length              => ipif_IP2Bus_Mst_Length,
      IP2Bus_Mst_Type                => ipif_IP2Bus_Mst_Type,
      IP2Bus_Mst_Lock                => ipif_IP2Bus_Mst_Lock,
      IP2Bus_Mst_Reset               => ipif_IP2Bus_Mst_Reset,
      Bus2IP_Mst_CmdAck              => ipif_Bus2IP_Mst_CmdAck,
      Bus2IP_Mst_Cmplt               => ipif_Bus2IP_Mst_Cmplt,
      Bus2IP_Mst_Error               => ipif_Bus2IP_Mst_Error,
      Bus2IP_Mst_Rearbitrate         => ipif_Bus2IP_Mst_Rearbitrate,
      Bus2IP_Mst_Cmd_Timeout         => ipif_Bus2IP_Mst_Cmd_Timeout,
      Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
      Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
      Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
      Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
      Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
      Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
      IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
      IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
      IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
      IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
      IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
      IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
      IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
      IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
      Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
      Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n,
      IP2Bus_IntrEvent               => user_IP2Bus_IntrEvent
    );

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data, intr_IP2Bus_Data ) is
  begin

    case ipif_Bus2IP_CS is
      when "10" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "01" => ipif_IP2Bus_Data <= intr_IP2Bus_Data;
      when others => ipif_IP2Bus_Data <= (others => '0');
    end case;

  end process IP2BUS_DATA_MUX_PROC;

  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck or intr_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck or intr_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error or intr_IP2Bus_Error;

  user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(CONTROLLER_CE_INDEX to CONTROLLER_CE_INDEX+CONTROLLER_NUM_REG-1);
  user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(CONTROLLER_CE_INDEX to CONTROLLER_CE_INDEX+CONTROLLER_NUM_REG-1);

end IMP;
