-------------------------------------------------------------------------------
-- xemac.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This file contains proprietary and confidential information of       **
--  **  Xilinx, Inc. ("Xilinx"), that is distributed under a license         **
--  **  from Xilinx, and may be used, copied and/or disclosed only           **
--  **  pursuant to the terms of a valid license agreement with Xilinx.      **
--  **                                                                       **
--  **  XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION                **
--  **  ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER           **
--  **  EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                  **
--  **  LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,            **
--  **  MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx        **
--  **  does not warrant that functions included in the Materials will       **
--  **  meet the requirements of Licensee, or that the operation of the      **
--  **  Materials will be uninterrupted or error-free, or that defects       **
--  **  in the Materials will be corrected. Furthermore, Xilinx does         **
--  **  not warrant or make any representations regarding use, or the        **
--  **  results of the use, of the Materials in terms of correctness,        **
--  **  accuracy, reliability or otherwise.                                  **
--  **                                                                       **
--  **  Xilinx products are not designed or intended to be fail-safe,        **
--  **  or for use in any application requiring fail-safe performance,       **
--  **  such as life-support or safety devices or systems, Class III         **
--  **  medical devices, nuclear facilities, applications related to         **
--  **  the deployment of airbags, or any other applications that could      **
--  **  lead to death, personal injury or severe property or                 **
--  **  environmental damage (individually and collectively, "critical       **
--  **  applications"). Customer assumes the sole risk and liability         **
--  **  of any use of Xilinx products in critical applications,              **
--  **  subject only to applicable laws and regulations governing            **
--  **  limitations on product liability.                                    **
--  **                                                                       **
--  **  Copyright 2007, 2008, 2009 Xilinx, Inc.                              **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        xemac.vhd
--
-- Description:     Design file for the Ethernet Lite MAC with
--                  IPIF elements included. 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
--  hardorb_fpga.vhd
--      \
--      \-- xemac.vhd
--           \
--           \-- xps_ipif_ssp1.vhd
--           \-- mdio_if.vhd
--           \-- emac_dpram.vhd                     
--           \    \                     
--           \    \-- RAMB16_S4_S36
--           \                          
--           \    
--           \-- emac.vhd                     
--                \                     
--                \                     
--                \-- receive.vhd
--                \      rx_statemachine.vhd
--                \      rx_intrfce.vhd
--                \         ethernetlite_v1_01_b_dmem_v2.edn
--                \      crcgenrx.vhd
--                \                     
--                \-- transmit.vhd
--                       crcgentx.vhd
--                          crcnibshiftreg
--                       tx_intrfce.vhd
--                          ethernetlite_v1_01_b_dmem_v2.edn
--                       tx_statemachine.vhd
--                       deferral.vhd
--                          cntr5bit.vhd
--                          defer_state.vhd
--                       bocntr.vhd
--                          lfsr16.vhd
--                       msh_cnt.vhd
--                       ld_arith_reg.vhd
--
-------------------------------------------------------------------------------
-- Author:         MSH
-- History:
--  RSK            11/06/06
-- ^^^^^^
--                 First Version, Based on opb_ethernetlite v1.01.b
--  ~~~~~
--  SK             12/06/07 updated version and removed license attribute
-- ^^^^^^
--                 Updated Version, Based on hardorb_fpga v1.00.a
--                 Removed the attribute "check_license" to make the core free 
--                 core
--  ~~~~~
--  PVK       03/05/2009    Version v3.00.a
-- ^^^^^^^
-- 1) Fixed CR:479779 (Adding Burst capability to Core). Updated PLB slave 
--    interface from plbv46_slave_single_v1_01_a to plbv46_slave_burst_v1_01_a.
-- 2) Added local register implemention for the Ethernetlite registers.
-- 3) Added MDIO interface for PHY register access.
-- 4) Added internal loopback support to the core.
-- ~~~~~~~
--  PVK       08/06/2009    Version v3.01.a
-- ^^^^^^^
--  1) Fixed CR:527536(Tx Pong buffer cannot be used by EMAClite driver in 
--     interrupt mode). Added pong_soft_status bit in PONG control register. 
-- ~~~~~~~
-- Last Modified: Feb 2010 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY Hard ORB project
-- (University of Potsdam, Computer Science Department)
-- ~~~~~~~
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- hardorb_fpga_v3_01_a library is used for hardorb_fpga_v3_01_a 
-- component declarations
-------------------------------------------------------------------------------
library hardorb_fpga_v3_01_a;
use hardorb_fpga_v3_01_a.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different 
-- function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.family.all;

-------------------------------------------------------------------------------
-- Vcomponents from unisim library is used for FIFO instatiation
-- function declarations
-------------------------------------------------------------------------------
library unisim;
use unisim.Vcomponents.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
-------------------------------------------------------------------------------
-- C_DUPLEX               -- 1 = full duplex, 0 = half duplex
-- C_TX_PING_PONG         -- 1 = ping-pong memory used for transmit buffer
-- C_RX_PING_PONG         -- 1 = ping-pong memory used for receive buffer
-- C_INCLUDE_MDIO         -- 1 = Include MDIO Innterface, 0 = No MDIO Interface
-- C_FAMILY               -- Target device family (spartan3e, spartan3a,
--                           spartan3an, spartan3af, virtex4 or virtex5)
-- C_BASEADDR             -- Base Address of this device
-- C_HIGHADDR             -- High Address of this device 
--                           (using word addressing for each byte)
-- C_SPLB_CLK_PERIOD_PS   -- The period of the PLB clock in ps
-- C_SPLB_AWIDTH          -- Width of the PLB Address Bus
-- C_SPLB_DWIDTH          -- Width of the PLB Data Bus
-- C_SPLB_P2P             -- Optimize slave interface(plbv46_slave_single)
--                           for a point to point connection
-- C_SPLB_MID_WIDTH       -- The width of the Master ID bus
--                           This is set to log2(C_SPLB_NUM_MASTERS)
-- C_SPLB_NUM_MASTERS     -- The number of Master Devices connected to the PLB
-- C_SPLB_NATIVE_DWIDTH   -- Width of slave data bus
-- C_SPLB_SUPPORT_BURSTS  -- Enable PLB Burst support
-- C_SPLB_SMALLEST_MASTER -- PLB smallest master datawidth
--
-------------------------------------------------------------------------------
-- Definition of Ports:
--
-- PLB Interface
--   System signals
--     SPLB_Clk           -- PLB clock                                                  
--     SPLB_Rst           -- PLB Reset                                               
--   Bus Slave signals   
--     PLB_ABus           -- PLB address bus                                             
--     PLB_PAValid        -- PLB primary address valid indicator
--     PLB_masterID       -- PLB current master identifier
--     PLB_RNW            -- PLB read not write                                           
--     PLB_BE             -- PLB byte enables                                              
--     PLB_size           -- PLB transfer size
--     PLB_type           -- PLB transfer type
--     PLB_wrDBus         -- PLB Write Data Bus
--   Slave Response signals    
--     Sl_addrAck         -- Slave address acknowledge
--     Sl_SSize           -- Slave data bus size
--     Sl_wait            -- Slave wait indicator
--     Sl_rearbitrate     -- Slave rearbitrate bus indicator
--     Sl_wrDAck          -- Slave write data acknowledge
--     Sl_wrComp          -- Slave write transfer complete indicator
--     Sl_rdDBus          -- Slave read bus                                         
--     Sl_rdDAck          -- Slave read data acknowledge
--     Sl_rdComp          -- Slave read transfer complete indicator
--     Sl_MBusy           -- Slave busy indicator
--     Sl_MWrErr          -- Slave write error indicator
--     Sl_MRdErr          -- Slave read error indicator
--   Unused Bus Slave signals
--     PLB_UABus          -- PLB upper address bus
--     PLB_SAValid        -- PLB secondary address valid indicator
--     PLB_rdPrim         -- PLB secondary to primary read request indicator
--     PLB_wrPrim         -- PLB secondary to primary write request indicator
--     PLB_abort          -- PLB abort bus request indicator
--     PLB_busLock        -- PLB bus lock
--     PLB_MSize          -- PLB master data bus size
--     PLB_lockErr        -- PLB lock error indicator
--     PLB_wrBurst        -- PLB burst write transfer indicator
--     PLB_rdBurst        -- PLB burst read transfer indicator
--     PLB_wrPendReq      -- PLB pending write bus request indicator
--     PLB_rdPendReq      -- PLB pending read bus request indicator
--     PLB_wrPendPri      -- PLB pending write request priority 
--     PLB_rdPendPri      -- PLB pending read request priority
--     PLB_reqPri         -- PLB current request priority
--     PLB_TAttribute     -- PLB Transfer Attribute bus
--   Unused Slave Response signals
--     Sl_wrBTerm         -- Slave terminate write burst transfer
--     Sl_rdWdAddr        -- Slave read word address
--     Sl_rdBTerm         -- Slave terminate read burst transfer
--     Sl_MIRQ            -- Slave interrupt indicator
--  Interrupts           
--     IP2INTC_Irpt       -- Interrupt to processor
--                 
--  Ethernet
--       PHY_tx_clk       -- Ethernet tranmit clock
--       PHY_rx_clk       -- Ethernet receive clock
--       PHY_crs          -- Ethernet carrier sense
--       PHY_dv           -- Ethernet receive data valid
--       PHY_rx_data      -- Ethernet receive data
--       PHY_col          -- Ethernet collision indicator
--       PHY_rx_er        -- Ethernet receive error
--       PHY_rst_n        -- Ethernet PHY Reset
--       PHY_tx_en        -- Ethernet transmit enable
--       PHY_tx_data      -- Ethernet transmit data
--       Loopback         -- Internal Loopback enable
--       PHY_MDIO_I       -- Ethernet PHY MDIO data input 
--       PHY_MDIO_O       -- Ethernet PHY MDIO data output 
--       PHY_MDIO_T       -- Ethernet PHY MDIO data 3-state control
--       PHY_MDC          -- Ethernet PHY management clock
-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
entity xemac is
  generic (
    -- akzare  
    C_DEBUG_DWIDTH       : integer := 32;	
    C_DEBUG_MODE         : integer := 0;	-- 0 = disable, 1 = enable
    C_NUM_TRIG_SIGNALS   : integer := 1;	
    C_ICMP_MODE          : integer := 1;	-- 0 = disable, 1 = enable
    DEST_IP              : STD_LOGIC_VECTOR := x"c0a80102";
    DEST_TCPCLNT_PORT    : STD_LOGIC_VECTOR (15 downto 0) := x"BC14";
    SRC_TCPCLNT_PORT     : STD_LOGIC_VECTOR (15 downto 0) := x"DFCC"; -- Source TCP Client Port
    NODE_IP              : std_logic_vector := x"c0a8010a"; -- ip address
    C_TCP_OPERATION_MODE : integer := 0;	-- 0 = NoTCP, 1 = TCP_Server, 2 = TCP_Client, 3 = TCP_Server_Client
    NODE_TCPPORT         : std_logic_vector := x"BC14"; -- TCP port for GIOP protocol 
    NODE_TCPPAYLOAD      : STD_LOGIC_VECTOR := x"0400";
    C_NPI_BURST_SIZE     : integer := 256;
    C_NPI_ADDR_WIDTH     : integer := 32;
    C_NPI_DATA_WIDTH     : integer := 64;
    C_NPI_BE_WIDTH       : integer := 8;
    C_NPI_RDWDADDR_WIDTH : integer := 4;
    -- akzare  

    C_DUPLEX         : integer := 1; -- 1 = full duplex, 0 = half duplex
    C_RX_PING_PONG   : integer := 0; -- 1 = ping-pong memory used for 
                                     --     receive buffer
    C_TX_PING_PONG   : integer := 0; -- 1 = ping-pong memory used for 
                                     --     transmit buffer
    C_INCLUDE_MDIO   : integer := 1; -- 1 = Include MDIO interface
                                     -- 0 = No MDIO interface
--    NODE_MAC         : bit_vector := x"00005e00FACE"; 
    NODE_MAC         : std_logic_vector := x"000A3501CB9E"; -- akzare TEST (MAC address of Orest 141.89.52.43) & bit_vector -> std_logic_vector
    
                                     --  power up defaul MAC address
    C_BASEADDR       : std_logic_vector := X"60000000";
                                     --  Assigned Base Address for
                                     --  this device (system byte address)
    C_HIGHADDR       : std_logic_vector := X"60003fff";
                                     -- Maximum Address for this device (system
                                     -- byte address xxxx3fff)  
                                     -- (using word addressing for each byte)
    C_FAMILY               : string := "virtex5";
    C_SPLB_AWIDTH          : integer := 32;
    C_SPLB_DWIDTH          : integer := 32;
    C_SPLB_P2P             : integer := 0;
    C_SPLB_MID_WIDTH       : integer := 3;
    C_SPLB_NUM_MASTERS     : integer := 8;
    C_SPLB_SUPPORT_BURSTS  : integer := 0;
    C_SPLB_SMALLEST_MASTER : integer := 32;
    C_SPLB_CLK_PERIOD_PS   : integer := 10000;
    C_SPLB_NATIVE_DWIDTH   : integer := 32
    );
  port (     
------------------------ ChipScope TEST (akzare) -------------------    
    DEBUG_D_I  	   : in std_logic_vector (C_DEBUG_DWIDTH-1 downto 0);    
    DEBUG_D_O  	   : out std_logic_vector (C_DEBUG_DWIDTH-1 downto 0);    
    DEBUG_D_T  	   : out std_logic_vector (C_DEBUG_DWIDTH-1 downto 0); 
------------------------ ChipScope TEST (akzare) -------------------    
    trig_sig      				: out std_logic_vector (C_NUM_TRIG_SIGNALS-1 downto 0);    
------------ Memory Controller Interface, NPI mode (akzare) --------    
    NPI_Clk               : in std_logic;
    NPI_RST               : in std_logic;
    NPI_Addr              : out std_logic_vector(C_NPI_ADDR_WIDTH - 1 downto 0);
    NPI_AddrReq           : out std_logic;
    NPI_AddrAck           : in std_logic;
    NPI_RNW               : out std_logic;
    NPI_Size              : out std_logic_vector(3 downto 0);
    NPI_WrFIFO_Data       : out std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
    NPI_WrFIFO_BE         : out std_logic_vector(C_NPI_BE_WIDTH - 1 downto 0);
    NPI_WrFIFO_Push       : out std_logic;
    NPI_RdFIFO_Data       : in std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
    NPI_RdFIFO_Pop        : out std_logic;
    NPI_RdFIFO_RdWdAddr   : in std_logic_vector(C_NPI_RDWDADDR_WIDTH - 1 downto 0);
    NPI_WrFIFO_Empty      : in std_logic;
    NPI_WrFIFO_AlmostFull : in std_logic;
    NPI_WrFIFO_Flush      : out std_logic;
    NPI_RdFIFO_Empty      : in std_logic;
    NPI_RdFIFO_Flush      : out std_logic;
    NPI_RdFIFO_Latency    : in std_logic_vector(1 downto 0);
    NPI_RdModWr           : out std_logic;
    NPI_InitDone          : in std_logic;
------------ Memory Controller Interface, NPI mode (akzare) --------    

--------------- Memory Controller Interface, VFBC mode (Adil) -----    
	VFBC2_cmd_clk 				: out std_logic;
	VFBC2_cmd_reset 			: out std_logic;
	VFBC2_cmd_data 				: out std_logic_vector (31 downto 0);
	VFBC2_cmd_write 			: out std_logic;
	VFBC2_cmd_end 				: out std_logic;
	VFBC2_cmd_full 				: in std_logic;
	VFBC2_cmd_almost_full 	: in std_logic;
	VFBC2_cmd_idle 				: in std_logic;
	VFBC2_wd_clk 				: out std_logic;
	VFBC2_wd_reset 				: out std_logic;
	VFBC2_wd_write 				: out std_logic;
	VFBC2_wd_end_burst 		: out std_logic;
	VFBC2_wd_flush 				: out std_logic;
	VFBC2_wd_data 				: out std_logic_vector (31 downto 0);
	VFBC2_wd_data_be 			: out std_logic_vector (3 downto 0);
	VFBC2_wd_full 				: in std_logic;
	VFBC2_wd_almost_full 		: in std_logic;
	VFBC2_rd_clk 				: out std_logic;
	VFBC2_rd_reset 				: out std_logic;
	VFBC2_rd_read 				: out std_logic;
	VFBC2_rd_end_burst 		: out std_logic;
	VFBC2_rd_flush 				: out std_logic;
	VFBC2_rd_data 				: in std_logic_vector (31 downto 0);
	VFBC2_rd_empty 				: in std_logic;
	VFBC2_rd_almost_empty 	: in std_logic;
--------------- Memory Controller Interface, VFBC mode (Adil) ----- 

-------------- External Trigger Signals for measurement (akzare) -------------------    
--    EXT_TRIG_D  	       : out std_logic_vector (3 downto 0);    
--    EXT_TRIG_D  	       : in std_logic_vector (3 downto 0);    

    EXT_TRIG_D_I  	       : in std_logic_vector (3 downto 0);    
    EXT_TRIG_D_O  	       : out std_logic_vector (3 downto 0);    
    EXT_TRIG_D_T    	     : out std_logic_vector (3 downto 0);    
-------------- External Trigger Signals for measurement (akzare) -------------------    

    -- PLB Interface
    SPLB_Clk       : in  std_logic;
    SPLB_Rst       : in  std_logic;
    PLB_ABus       : in  std_logic_vector(0 to 31);
    PLB_UABus      : in  std_logic_vector(0 to 31);
    PLB_PAValid    : in  std_logic;
    PLB_SAValid    : in  std_logic;
    PLB_rdPrim     : in  std_logic;
    PLB_wrPrim     : in  std_logic;
    PLB_masterID   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort      : in  std_logic;
    PLB_busLock    : in  std_logic;
    PLB_RNW        : in  std_logic;
    PLB_BE         : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_MSize      : in  std_logic_vector(0 to 1);
    PLB_size       : in  std_logic_vector(0 to 3);
    PLB_type       : in  std_logic_vector(0 to 2);
    PLB_lockErr    : in  std_logic;
    PLB_wrDBus     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst    : in  std_logic;
    PLB_rdBurst    : in  std_logic;
    PLB_wrPendReq  : in  std_logic;
    PLB_rdPendReq  : in  std_logic;
    PLB_wrPendPri  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri  : in  std_logic_vector(0 to 1);
    PLB_reqPri     : in  std_logic_vector(0 to 1);
    PLB_TAttribute : in  std_logic_vector(0 to 15);
    Sl_addrAck     : out std_logic;
    Sl_SSize       : out std_logic_vector(0 to 1);
    Sl_wait        : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck      : out std_logic;
    Sl_wrComp      : out std_logic;
    Sl_wrBTerm     : out std_logic;
    Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr    : out std_logic_vector(0 to 3);
    Sl_rdDAck      : out std_logic;
    Sl_rdComp      : out std_logic;
    Sl_rdBTerm     : out std_logic;
    Sl_MBusy       : out std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr      : out std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr      : out std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ        : out std_logic_vector (0 to C_SPLB_NUM_MASTERS-1);
    IP2INTC_Irpt   : out std_logic;
    
	 -- LEDs
	 GPIO_IO			 : out std_logic_vector (7 downto 0);
	 
    -- Ethernet Interface
    PHY_tx_clk     : in std_logic;
    PHY_rx_clk     : in std_logic;
    PHY_crs        : in std_logic;
    PHY_dv         : in std_logic;
    PHY_rx_data    : in std_logic_vector (3 downto 0);
    PHY_col        : in std_logic;
    PHY_rx_er      : in std_logic;
    PHY_tx_en      : out std_logic;
    PHY_tx_data    : out std_logic_vector (3 downto 0);
    Loopback       : out std_logic;
   
    -- MDIO Interface
    PHY_MDIO_I     : in  std_logic;
    PHY_MDIO_O     : out std_logic;
    PHY_MDIO_T     : out std_logic;
    PHY_MDC        : out std_logic  
		
   ); 

end xemac;


architecture imp of xemac is


-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant MDIO_CNT         : integer := ((200000/C_SPLB_CLK_PERIOD_PS)+1);
constant IP2BUS_DATA_ZERO : std_logic_vector(0 to 31) := X"00000000";


-------------------------------------------------------------------------------
--  Signal and Type Declarations
-------------------------------------------------------------------------------
signal ip2bus_wrack     : std_logic;
signal ip2bus_rdack     : std_logic;
signal phy_rx_data_i    : std_logic_vector (0 to 3);
signal phy_tx_data_i    : std_logic_vector (0 to 3);
signal tx_DPM_ce        : std_logic;
signal tx_DPM_ce_i      : std_logic; -- added 03-03-05 MSH
signal tx_DPM_adr       : std_logic_vector (0 to 11);
signal tx_DPM_wr_data   : std_logic_vector (0 to 3);
signal tx_DPM_rd_data   : std_logic_vector (0 to 3);
signal tx_ping_rd_data  : std_logic_vector (0 to 3);
signal tx_pong_rd_data  : std_logic_vector (0 to 3) := (others => '0');
signal tx_DPM_wr_rd_n   : std_logic;              
signal rx_DPM_ce        : std_logic;
signal rx_DPM_ce_i      : std_logic; -- added 03-03-05 MSH
signal rx_DPM_adr       : std_logic_vector (0 to 11);
signal rx_DPM_wr_data   : std_logic_vector (0 to 3);
signal rx_DPM_rd_data   : std_logic_vector (0 to 3);
signal rx_ping_rd_data  : std_logic_vector (0 to 3);
signal rx_pong_rd_data  : std_logic_vector (0 to 3) := (others => '0');
signal rx_DPM_wr_rd_n   : std_logic;
signal IPIF_tx_Ping_CE  : std_logic;
signal IPIF_tx_Pong_CE  : std_logic := '0';
signal IPIF_rx_Ping_CE  : std_logic;
signal IPIF_rx_Pong_CE  : std_logic := '0';
signal tx_ping_data_out : std_logic_vector (0 to 31);
signal tx_pong_data_out : std_logic_vector (0 to 31) := (others => '0');
signal rx_ping_data_out : std_logic_vector (0 to 31);
signal rx_pong_data_out : std_logic_vector (0 to 31) := (others => '0');
signal dpm_wr_ack       : std_logic;
signal dpm_rd_ack       : std_logic;
signal rx_done          : std_logic;
signal rx_done_d1       : std_logic := '0';
signal tx_done          : std_logic;
signal tx_done_d1       : std_logic := '0';
signal tx_done_d2       : std_logic := '0';
signal tx_ping_ce       : std_logic;
signal tx_pong_ping_l   : std_logic := '0';
signal tx_idle          : std_logic;
signal rx_idle          : std_logic;
signal rx_ping_ce       : std_logic;
signal rx_pong_ping_l   : std_logic := '0';
signal reg_access             : std_logic;
signal reg_en                 : std_logic;
signal tx_ping_reg_en         : std_logic;
signal tx_pong_reg_en         : std_logic;
signal rx_ping_reg_en         : std_logic;
signal rx_pong_reg_en         : std_logic;
signal tx_ping_ctrl_reg_en    : std_logic;
signal tx_ping_length_reg_en  : std_logic;
signal tx_pong_ctrl_reg_en    : std_logic;
signal tx_pong_length_reg_en  : std_logic;
signal rx_ping_ctrl_reg_en    : std_logic;
signal rx_pong_ctrl_reg_en    : std_logic;
signal loopback_en            : std_logic;
signal tx_intr_en             : std_logic;
signal ping_mac_program       : std_logic;
signal pong_mac_program       : std_logic;
signal ping_tx_status         : std_logic;
signal pong_tx_status         : std_logic;
signal ping_pkt_lenth         : std_logic_vector(0 to 15);
signal pong_pkt_lenth         : std_logic_vector(0 to 15);
signal rx_intr_en             : std_logic;
signal ping_rx_status         : std_logic;
signal pong_rx_status         : std_logic;
signal ping_tx_done           : std_logic;
signal mdio_data_out          : std_logic_vector(0 to 31);
signal reg_data_out           : std_logic_vector(0 to 31);
signal mdio_reg_en            : std_logic;
signal gie_reg                : std_logic;
signal gie_reg_en             : std_logic;
signal gie_enable             : std_logic;
signal tx_packet_length       : std_logic_vector(0 to 15);
signal stat_reg_en            : std_logic;
signal status_reg             : std_logic_vector(0 to 5);
signal ping_mac_prog_done     : std_logic;
signal transmit_start         : std_logic;
signal mac_program_start      : std_logic;
signal rx_buffer_ready        : std_logic;
signal dpm_addr_ack           : std_logic;
signal control_reg            : std_logic;
signal length_reg             : std_logic;
signal word_access            : std_logic;
signal reg_access_i           : std_logic;
signal ip2intc_irpt_i         : std_logic;
signal reg_access_d1          : std_logic;
signal ping_soft_status       : std_logic;
signal pong_soft_status       : std_logic;

                              
-------------------------------------------------------------------------------
-- New ipif_ssp1 signal declaration                                          --
-------------------------------------------------------------------------------

signal temp_Bus2IP_Addr: std_logic_vector(0 to C_SPLB_AWIDTH - 1);
signal bus2ip_addr     : std_logic_vector(0 to 12);
signal Bus2IP_Data     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH  - 1);
signal bus2ip_ce       : std_logic;
signal Bus2IP_RdCE     : std_logic;
signal Bus2IP_WrCE     : std_logic;
signal Bus2IP_Clk      : std_logic;
signal Bus2IP_Reset    : std_logic;
signal IP2Bus_Data     : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH -1);
signal bus2ip_addr_d1  : std_logic_vector(0 to 12);
signal tx_ping_ce_en   : std_logic;
signal rx_ping_ce_en   : std_logic;
signal bus2ip_ce_d1    : std_logic;
signal bus2ip_rdreq_d1 : std_logic;
signal bus2ip_wrreq    : std_logic;
signal bus2ip_rdreq    : std_logic;
signal bus2ip_burst    : std_logic;
signal bus2ip_be       : std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH/8)-1);
signal ip2bus_addrack  : std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- New HardORB FPGA signal declaration (akzare)                              --
-------------------------------------------------------------------------------

signal OrbCmd_start_tx : std_logic;
signal rx_done_SW : std_logic;
signal tx_done_SW : std_logic;
signal OrbCmd_clr_rx_stats : std_logic;
signal tx_ping_rd_data_MAC : std_logic_vector (0 to 3);
signal tx_packet_len_SW : std_logic_vector (0 to 15);

------------------------ ChipScope TEST (akzare) -------------------    
signal tst_macnewFrameByte  : std_logic; 
signal tst_macframeData     : std_logic_vector (0 to 7); 
       
signal tst_tcphndl_wrRAM : std_logic;
signal tst_tcphndl_wrData : std_logic_vector (0 to 7); 

signal tst_tcpcmpltRec: STD_LOGIC;
signal tst_tcpnewByteRec: STD_LOGIC;
signal tst_tcpinByteRec: STD_LOGIC_VECTOR (7 downto 0);
signal tst_tcpbusyXmit: STD_LOGIC;
signal tst_tcpsendTCP: STD_LOGIC;

signal tst_ipnewFrame: STD_LOGIC;
signal tst_ipframeType: STD_LOGIC;
signal tst_ipcnt: STD_LOGIC_VECTOR (5 downto 0);
signal tst_ipinByte: STD_LOGIC_VECTOR (7 downto 0);
signal tst_ipnewByte: STD_LOGIC;
signal tst_ipnewDatagram: STD_LOGIC;
signal tst_ippresstate: STD_LOGIC_VECTOR (3 downto 0);

signal tst_tcppresstateRec: STD_LOGIC_VECTOR (3 downto 0);
signal tst_tcppresstateXmit: STD_LOGIC_VECTOR (3 downto 0);
signal tst_tcppresstateSrv: STD_LOGIC_VECTOR (3 downto 0);
signal tst_tcprx_done: STD_LOGIC;

signal tst_arprecpresstate: STD_LOGIC_VECTOR (1 downto 0);
signal tst_arprecnewFrame: STD_LOGIC;
signal tst_arprecframeType: STD_LOGIC;

signal tst_arpxmitpresstate: STD_LOGIC_VECTOR (3 downto 0);

signal tst_macxmit_start: STD_LOGIC;
signal tst_arpxmit_genFrame: STD_LOGIC;

signal tst_DMA_DREQ: STD_LOGIC;
signal tst_DMA_DACK: STD_LOGIC;
signal tst_DMA_INIT: STD_LOGIC;
signal tst_DMA_DATA: STD_LOGIC_VECTOR (31 downto 0);

signal tst_burst_cnt_one: STD_LOGIC;
signal tst_burst_cnt: STD_LOGIC_VECTOR (5 downto 0);

signal int_NPI_AddrReq: std_logic;
signal int_NPI_RNW: std_logic;
signal int_NPI_Size: std_logic_vector(3 downto 0);
signal int_NPI_RdModWr: std_logic;
signal int_NPI_Addr: std_logic_vector(31 downto 0);
signal int_NPI_RdFIFO_Flush: std_logic;
signal int_NPI_WrFIFO_Push: std_logic;

signal int_NPI_WrFIFO_Data: std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);

signal int_PHY_tx_en : std_logic;

signal int_trig_sig : std_logic_vector (C_NUM_TRIG_SIGNALS-1 downto 0);    

signal tst_user_read : STD_LOGIC;
signal tst_user_drdy : STD_LOGIC;
signal tst_fifo_data_out : std_logic_vector(7 downto 0);
signal tst_fifo_wr_count : std_logic_vector(10 downto 0);
signal tst_fifowr_rd_count : std_logic_vector(10 downto 0); 
signal tst_fifo_wr_en : STD_LOGIC;

signal counter : std_logic_vector(3 downto 0);

signal tst_mactx_goto_SFD : std_logic; 
signal tst_mactx_SFD : std_logic; 

signal tst_tcp_RcvOvrHd_TrigSg : std_logic; 

signal transmit_start_d1 :std_logic;

------------------------ ChipScope TEST (akzare) -------------------    

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------
component SRL16E
    generic (
      INIT : bit_vector := X"0000"
      );

  port  (
    Q   : out std_logic; --[out]
    A0  : in  std_logic; --[in]
    A1  : in  std_logic; --[in]
    A2  : in  std_logic; --[in]
    A3  : in  std_logic; --[in]
    CE  : in  std_logic; --[in]
    CLK : in  std_logic; --[in]
    D   : in  std_logic  --[in]
  );
end component;


component FDR
  port (
    Q : out std_logic;
    C : in std_logic;
    D : in std_logic;
    R : in std_logic
  );
end component;

component FDRE
  port (
    Q  : out std_logic;
    C  : in std_logic;
    CE : in std_logic;
    D  : in std_logic;
    R  : in std_logic
  );
end component;

component LUT4
   generic(INIT : bit_vector);
   port (
     O  : out std_logic;
     I0 : in std_logic;
     I1 : in std_logic;
     I2 : in std_logic;
     I3 : in std_logic
   );
end component;

begin
------------------------ ChipScope TEST (akzare) -------------------    
NPI_AddrReq <= int_NPI_AddrReq;
NPI_RNW <= int_NPI_RNW;
NPI_Size <= int_NPI_Size;
NPI_RdModWr <= int_NPI_RdModWr;
NPI_Addr <= int_NPI_Addr;
NPI_WrFIFO_Push <= int_NPI_WrFIFO_Push;
NPI_WrFIFO_Data <= int_NPI_WrFIFO_Data;
NPI_RdFIFO_Flush <= int_NPI_RdFIFO_Flush;
trig_sig <= int_trig_sig;
PHY_tx_en <= int_PHY_tx_en;

   DEBUG_D_T <= (others => '1');	-- High Z, Input mode

--   DEBUG_D_O(0) <= NPI_Clk;
--   DEBUG_D_O(1) <= int_NPI_AddrReq;
--
--   DEBUG_D_O(2) <= int_NPI_Addr(7);
--   DEBUG_D_O(3) <= int_NPI_Addr(8);
--   DEBUG_D_O(4) <= int_NPI_Addr(9);
--   DEBUG_D_O(5) <= int_NPI_Addr(10);
--   DEBUG_D_O(6) <= int_NPI_Addr(11);
--   DEBUG_D_O(7) <= int_NPI_Addr(12);
--
--   DEBUG_D_O(2) <= int_NPI_WrFIFO_Push;
--   DEBUG_D_O(3) <= int_NPI_WrFIFO_Data(0);
--   DEBUG_D_O(4) <= int_NPI_WrFIFO_Data(1);
--   DEBUG_D_O(5) <= int_NPI_WrFIFO_Data(2);
--   DEBUG_D_O(6) <= int_NPI_WrFIFO_Data(3);
--   DEBUG_D_O(7) <= int_NPI_WrFIFO_Data(4);
--   DEBUG_D_O(8) <= int_NPI_WrFIFO_Data(5);
--   DEBUG_D_O(9) <= int_NPI_WrFIFO_Data(6);
--   DEBUG_D_O(10) <= int_NPI_WrFIFO_Data(7);
--   DEBUG_D_O(11) <= int_NPI_WrFIFO_Data(8);
--   DEBUG_D_O(12) <= int_NPI_WrFIFO_Data(9);
--   DEBUG_D_O(13) <= int_NPI_WrFIFO_Data(10);
--   DEBUG_D_O(14) <= int_NPI_WrFIFO_Data(11);
--   DEBUG_D_O(15) <= int_NPI_WrFIFO_Data(12);
--   DEBUG_D_O(16) <= int_NPI_WrFIFO_Data(13);
--   DEBUG_D_O(17) <= int_NPI_WrFIFO_Data(14);
--   DEBUG_D_O(18) <= int_NPI_WrFIFO_Data(15);
--   DEBUG_D_O(19) <= int_NPI_WrFIFO_Data(16);
--   DEBUG_D_O(20) <= int_NPI_WrFIFO_Data(17);
--   DEBUG_D_O(21) <= int_NPI_WrFIFO_Data(18);
--   DEBUG_D_O(22) <= int_NPI_WrFIFO_Data(19);
--   DEBUG_D_O(23) <= int_NPI_WrFIFO_Data(20);
--   DEBUG_D_O(24) <= int_NPI_WrFIFO_Data(21);
--   DEBUG_D_O(25) <= int_NPI_WrFIFO_Data(22);
--   DEBUG_D_O(26) <= int_NPI_WrFIFO_Data(23);
--   DEBUG_D_O(27) <= int_NPI_WrFIFO_Data(24);
--   DEBUG_D_O(28) <= int_NPI_WrFIFO_Data(25);
--   DEBUG_D_O(29) <= int_NPI_WrFIFO_Data(26);
--   DEBUG_D_O(30) <= int_NPI_WrFIFO_Data(27);
--   DEBUG_D_O(31) <= int_NPI_WrFIFO_Data(28);
--   DEBUG_D_O(32) <= int_NPI_WrFIFO_Data(29);
--   DEBUG_D_O(33) <= int_NPI_WrFIFO_Data(30);
--   DEBUG_D_O(34) <= int_NPI_WrFIFO_Data(31);

--   DEBUG_D_O(11) <= NPI_AddrAck;
--   DEBUG_D_O(12) <= int_NPI_Addr(0);
--   DEBUG_D_O(13) <= int_NPI_Addr(1);
--   DEBUG_D_O(14) <= int_NPI_Addr(2);
--   DEBUG_D_O(15) <= int_NPI_Addr(3);
--   DEBUG_D_O(16) <= int_NPI_Addr(4);
--   DEBUG_D_O(17) <= int_NPI_Addr(5);
--   DEBUG_D_O(18) <= int_NPI_Addr(6);
--   DEBUG_D_O(19) <= int_NPI_Addr(7);
--   DEBUG_D_O(20) <= int_NPI_Addr(8);
--   DEBUG_D_O(21) <= int_NPI_Addr(9);
--   DEBUG_D_O(22) <= int_NPI_Addr(10);
--   DEBUG_D_O(23) <= int_NPI_Addr(11);
--   DEBUG_D_O(24) <= int_NPI_Addr(12);
--   DEBUG_D_O(25) <= int_NPI_Addr(13);
--   DEBUG_D_O(26) <= int_NPI_Addr(14);

--   DEBUG_D_O(23) <= int_NPI_Size(0);
--   DEBUG_D_O(24) <= int_NPI_Size(1);
--   DEBUG_D_O(25) <= int_NPI_Size(2);
--   DEBUG_D_O(26) <= int_NPI_Size(3);

--   DEBUG_D_O(27) <= tst_fifowr_rd_count(0);
--   DEBUG_D_O(28) <= tst_fifowr_rd_count(1);
--   DEBUG_D_O(29) <= tst_fifowr_rd_count(2);
--   DEBUG_D_O(30) <= tst_fifowr_rd_count(3);
--   DEBUG_D_O(31) <= tst_fifowr_rd_count(4);
--   DEBUG_D_O(32) <= tst_fifowr_rd_count(5);
--   DEBUG_D_O(33) <= tst_fifowr_rd_count(6);
--   DEBUG_D_O(34) <= tst_fifowr_rd_count(7);

--   DEBUG_D_O(33) <= EXT_TRIG_D_I(0);
--   DEBUG_D_O(34) <= EXT_TRIG_D_I(2);
--
--   DEBUG_D_O(35) <= NPI_WrFIFO_Empty;

----   DEBUG_D_O(9) <= NPI_RdFIFO_Data(0);
----   DEBUG_D_O(10) <= NPI_RdFIFO_Data(1);
----   DEBUG_D_O(11) <= NPI_RdFIFO_Data(2);
----   DEBUG_D_O(12) <= NPI_RdFIFO_Data(3);
----   DEBUG_D_O(13) <= NPI_RdFIFO_Data(4);
----   DEBUG_D_O(14) <= NPI_RdFIFO_Data(5);
----   DEBUG_D_O(15) <= NPI_RdFIFO_Data(6);
----   DEBUG_D_O(16) <= NPI_RdFIFO_Data(7);
----   DEBUG_D_O(17) <= NPI_RdFIFO_Data(8);
----   DEBUG_D_O(18) <= NPI_RdFIFO_Data(9);
----   DEBUG_D_O(19) <= NPI_RdFIFO_Data(10);
----   DEBUG_D_O(20) <= NPI_RdFIFO_Data(11);
----   DEBUG_D_O(21) <= NPI_RdFIFO_Data(12);
----   DEBUG_D_O(22) <= NPI_RdFIFO_Data(13);
----   DEBUG_D_O(23) <= NPI_RdFIFO_Data(14);
----   DEBUG_D_O(24) <= NPI_RdFIFO_Data(15);
--
--

--   DEBUG_D_O(8) <= tst_fifo_wr_count(0);
--   DEBUG_D_O(9) <= tst_fifo_wr_count(1);
--   DEBUG_D_O(10) <= tst_fifo_wr_count(2);
--   DEBUG_D_O(11) <= tst_fifo_wr_count(3);
--   DEBUG_D_O(12) <= tst_fifo_wr_count(4);
--   DEBUG_D_O(13) <= tst_fifo_wr_count(5);
--   DEBUG_D_O(14) <= tst_fifo_wr_count(6);
--   DEBUG_D_O(15) <= tst_fifo_wr_count(7);
--   DEBUG_D_O(16) <= tst_fifo_wr_count(8);
----   DEBUG_D_O(16) <= tst_user_read;
--   DEBUG_D_O(17) <= tst_user_drdy;
--   DEBUG_D_O(18) <= tst_fifo_data_out(0);
--   DEBUG_D_O(19) <= tst_fifo_data_out(1);
--   DEBUG_D_O(20) <= tst_fifo_data_out(2);
--   DEBUG_D_O(21) <= tst_fifo_data_out(3);
--   DEBUG_D_O(22) <= tst_fifo_data_out(4);
--   DEBUG_D_O(23) <= tst_fifo_data_out(5);
--   DEBUG_D_O(24) <= tst_fifo_data_out(6);
--   DEBUG_D_O(25) <= tst_fifo_data_out(7);
--
--   DEBUG_D_O(26) <= tst_burst_cnt_one;
--   DEBUG_D_O(27) <= tst_burst_cnt(0);
--   DEBUG_D_O(28) <= tst_burst_cnt(1);
--   DEBUG_D_O(29) <= tst_burst_cnt(2);
--   DEBUG_D_O(30) <= tst_burst_cnt(3);
--   DEBUG_D_O(31) <= tst_fifo_wr_en;-- NPI_RdFIFO_Empty;

--   DEBUG_D_O(0) <= tst_DMA_DREQ;
--   DEBUG_D_O(1) <= tst_DMA_DACK;
--   DEBUG_D_O(2) <= tst_DMA_INIT;
--   DEBUG_D_O(3) <= tst_DMA_DATA(0);
--   DEBUG_D_O(4) <= tst_DMA_DATA(1);
--   DEBUG_D_O(5) <= tst_DMA_DATA(2);
--   DEBUG_D_O(6) <= tst_DMA_DATA(3);
--   DEBUG_D_O(7) <= tst_DMA_DATA(4);
--   DEBUG_D_O(8) <= tst_DMA_DATA(5);
--   DEBUG_D_O(9) <= tst_DMA_DATA(6);
--   DEBUG_D_O(10) <= tst_DMA_DATA(7);
--   DEBUG_D_O(11) <= tst_DMA_DATA(8);
--   DEBUG_D_O(12) <= tst_DMA_DATA(9);
--   DEBUG_D_O(13) <= tst_DMA_DATA(10);
--   DEBUG_D_O(14) <= tst_DMA_DATA(11);
--   DEBUG_D_O(15) <= tst_DMA_DATA(12);
--   DEBUG_D_O(16) <= tst_DMA_DATA(13);
--   DEBUG_D_O(17) <= tst_DMA_DATA(14);
--   DEBUG_D_O(18) <= tst_DMA_DATA(15);


   DEBUG_D_O(0) <= tst_macnewFrameByte;
   DEBUG_D_O(1) <= tst_macframeData(0);
   DEBUG_D_O(2) <= tst_macframeData(1);
   DEBUG_D_O(3) <= tst_macframeData(2);
   DEBUG_D_O(4) <= tst_macframeData(3);

--   DEBUG_D_O(1) <= EXT_TRIG_D(0);
--   DEBUG_D_O(2) <= EXT_TRIG_D(2);
--   DEBUG_D_O(3) <= EXT_TRIG_D(1);
--   DEBUG_D_O(4) <= EXT_TRIG_D(3);
   
--   DEBUG_D_O(5) <= tst_macframeData(4);
--   DEBUG_D_O(6) <= tst_macframeData(5);
--   DEBUG_D_O(7) <= tst_macframeData(6);
--   DEBUG_D_O(8) <= tst_macframeData(7);
--
   DEBUG_D_O(5) <= tst_tcppresstateSrv(0);
   DEBUG_D_O(6) <= tst_tcppresstateSrv(1);
   DEBUG_D_O(7) <= tst_tcppresstateSrv(2);
   DEBUG_D_O(8) <= tst_tcppresstateSrv(3);
   
--
----  DEBUG_D_O(9) <= tst_tcpcmpltRec;
----
----  DEBUG_D_O(10) <= tst_tcphndl_wrRAM;
----  DEBUG_D_O(11) <= tst_tcphndl_wrData(0);
----  DEBUG_D_O(12) <= tst_tcphndl_wrData(1);
----  DEBUG_D_O(13) <= tst_tcphndl_wrData(2);
----  DEBUG_D_O(14) <= tst_tcphndl_wrData(3);
----  DEBUG_D_O(15) <= tst_tcphndl_wrData(4);
----  DEBUG_D_O(16) <= tst_tcphndl_wrData(5);
----  DEBUG_D_O(17) <= tst_tcphndl_wrData(6);
----  DEBUG_D_O(18) <= tst_tcphndl_wrData(7);
----
--
----  DEBUG_D_O(9) <= tst_ipframeType;
----  DEBUG_D_O(10) <= tst_ipnewFrame;
--
--  DEBUG_D_O(9) <= tst_arprecpresstate(0);
--  DEBUG_D_O(10) <= tst_arprecpresstate(1);
--
   DEBUG_D_O(9) <= tst_tcppresstateXmit(0);
   DEBUG_D_O(10) <= tst_tcppresstateXmit(1);
   DEBUG_D_O(11) <= tst_tcppresstateXmit(2);
   DEBUG_D_O(12) <= tst_tcppresstateXmit(3);
--
--  DEBUG_D_O(11) <= IP2INTC_Irpt;
--  DEBUG_D_O(11) <= tst_ipnewDatagram;
--  DEBUG_D_O(12) <= tst_macxmit_start;
  DEBUG_D_O(13) <= tst_arpxmit_genFrame;

--  DEBUG_D_O(14) <= tst_ipframeType;
--  DEBUG_D_O(15) <= tst_ipnewFrame;

  DEBUG_D_O(14) <= tst_mactx_goto_SFD;
  DEBUG_D_O(15) <= tst_mactx_SFD;

--  DEBUG_D_O(16) <= tst_ipnewByte;

--   DEBUG_D_O(13) <= tst_tcppresstateRec(0);
--   DEBUG_D_O(14) <= tst_tcppresstateRec(1);
--   DEBUG_D_O(15) <= tst_tcppresstateRec(2);
   DEBUG_D_O(16) <= tst_tcppresstateRec(3);


--tst_ipcnt: out STD_LOGIC_VECTOR (5 downto 0);
--tst_ipinByte: out STD_LOGIC_VECTOR (7 downto 0);

   DEBUG_D_O(17) <= tst_arprecnewFrame;
   
--   DEBUG_D_O(17) <= int_trig_sig(0);
--   DEBUG_D_O(18) <= tst_tcp_RcvOvrHd_TrigSg;
--
----  DEBUG_D_O(17) <= tst_tcpnewByteRec;
--   DEBUG_D_O(18) <= tst_tcpinByteRec(0);
--   DEBUG_D_O(19) <= tst_tcpinByteRec(1);
--   DEBUG_D_O(20) <= tst_tcpinByteRec(2);
--   DEBUG_D_O(21) <= tst_tcpinByteRec(3);
--   DEBUG_D_O(22) <= tst_tcpinByteRec(4);
--   DEBUG_D_O(23) <= tst_tcpinByteRec(5);
--   DEBUG_D_O(24) <= tst_tcpinByteRec(6);
--   DEBUG_D_O(25) <= tst_tcpinByteRec(7);
--
----  
--  DEBUG_D_O(18) <= tst_ipinByte(0);
--  DEBUG_D_O(19) <= tst_ipinByte(1);
--  DEBUG_D_O(20) <= tst_ipinByte(2);
--  DEBUG_D_O(21) <= tst_ipinByte(3);
--  DEBUG_D_O(22) <= tst_ipinByte(4);
--  DEBUG_D_O(23) <= tst_ipinByte(5);
--  DEBUG_D_O(24) <= tst_ipinByte(6);
--  DEBUG_D_O(25) <= tst_ipinByte(7);

  DEBUG_D_O(18) <= tx_ping_rd_data(0);
  DEBUG_D_O(19) <= tx_ping_rd_data(1);
  DEBUG_D_O(20) <= tx_ping_rd_data(2);
  DEBUG_D_O(21) <= tx_ping_rd_data(3);
  
  DEBUG_D_O(22) <= tx_DPM_adr(7);
  DEBUG_D_O(23) <= tx_DPM_adr(8);
  DEBUG_D_O(24) <= tx_DPM_adr(9);
  DEBUG_D_O(25) <= tx_DPM_adr(10);
  DEBUG_D_O(26) <= tx_DPM_adr(11);
  
--
----  DEBUG_D_O(26) <= tst_ipnewDatagram;
----  DEBUG_D_O(26) <= tst_tcprx_done;
--   DEBUG_D_O(26) <= tst_arprecframeType;
--
--  DEBUG_D_O(31) <= tst_ippresstate(0);
--  DEBUG_D_O(32) <= tst_ippresstate(1);
--  DEBUG_D_O(33) <= tst_ippresstate(2);
--  DEBUG_D_O(34) <= tst_ippresstate(3);
--
--  DEBUG_D_O(35) <= tst_ipnewByte;

  DEBUG_D_O(31) <= phy_tx_data_i(0);
  DEBUG_D_O(32) <= phy_tx_data_i(1);
  DEBUG_D_O(33) <= phy_tx_data_i(2);
  DEBUG_D_O(34) <= phy_tx_data_i(3);

  DEBUG_D_O(35) <= int_PHY_tx_en;
--
--   DEBUG_D_O(27) <= tst_tcprx_done;
   DEBUG_D_O(27) <= tst_arpxmitpresstate(0);
   DEBUG_D_O(28) <= tst_arpxmitpresstate(1);
   DEBUG_D_O(29) <= tst_arpxmitpresstate(2);
   DEBUG_D_O(30) <= tst_arpxmitpresstate(3);


--  DEBUG_D_O(31) <= tst_tcprx_done;
------------------------ ChipScope TEST (akzare) -------------------    

---------- External Trigger Signals for timing measurements --------
EXT_TRIG_SERVER : if (C_TCP_OPERATION_MODE = 1) generate -- Server

EXT_TRIG_PROCESS:process (Bus2IP_Clk)
begin
  if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
    if (Bus2IP_Reset = '1') then
--       int_trig_sig(1) <= '0'; Adil : putted it in comment to permit the use of server mode (avoid errors)
      counter  <= (others => '0');
    else
      counter  <= counter+1;

       transmit_start_d1 <= transmit_start;
       if (int_trig_sig(0) = '1' and transmit_start = '1' and transmit_start_d1 = '0') then
--          int_trig_sig(1) <= '1'; Adil : putted it in comment to permit the use of server mode (avoid errors)
       elsif (EXT_TRIG_D_I(1) = '1') then
--          int_trig_sig(1) <= '0'; Adil : putted it in comment to permit the use of server mode (avoid errors)
       end if;
    end if;
 	end if;
end process EXT_TRIG_PROCESS;

	EXT_TRIG_D_T(0) <= '1';	-- High Z, Input mode
	EXT_TRIG_D_T(1) <= '1';	-- High Z, Input mode
	EXT_TRIG_D_T(2) <= '1';	-- High Z, Input mode
	EXT_TRIG_D_T(3) <= '1';	-- High Z, Input mode

	EXT_TRIG_D_O(0) <= counter(2);	
	EXT_TRIG_D_O(2) <= counter(3);	

	EXT_TRIG_D_O(1) <= '0';	
	EXT_TRIG_D_O(3) <= '0';	
--	EXT_TRIG_D_O(0) <= '0';	
--	EXT_TRIG_D_O(2) <= '0';	
end generate;

EXT_TRIG_CLIENT : if (C_TCP_OPERATION_MODE = 2) generate -- Client

	EXT_TRIG_D_T(0) <= '0';	-- Non High Z, Output mode
	EXT_TRIG_D_T(1) <= '0';	-- Non High Z, Output mode
	EXT_TRIG_D_T(2) <= '0';	-- Non High Z, Output mode
	EXT_TRIG_D_T(3) <= '0';	-- Non High Z, Output mode

  EXT_TRIG_D_O(1) <= int_trig_sig(0);
  EXT_TRIG_D_O(3) <= int_trig_sig(0);

	EXT_TRIG_D_O(0) <= counter(1);	
	EXT_TRIG_D_O(2) <= counter(2);	

end generate;

---------- External Trigger Signals for timing measurements --------

   ----------------------------------------------------------------------------
   -- HardORB FPGA switch (akzare)
   ----------------------------------------------------------------------------
   ORB_SW : entity hardorb_fpga_v3_01_a.orb_switch 
     generic map 
     (
       C_FAMILY            => C_FAMILY,
       C_DEBUG_MODE        => C_DEBUG_MODE,
       C_ICMP_MODE         => C_ICMP_MODE,
       DEST_IP             => DEST_IP,
       DEST_TCPCLNT_PORT   => DEST_TCPCLNT_PORT,
       SRC_TCPCLNT_PORT    => SRC_TCPCLNT_PORT,
       DEVICE_IP           => NODE_IP,
       C_TCP_OPERATION_MODE => C_TCP_OPERATION_MODE,
       DEVICE_MAC          => NODE_MAC, --To_StdLogicVector(NODE_MAC),
       DEVICE_TCP_PORT     => NODE_TCPPORT,
       DEVICE_TCP_PAYLOAD  => NODE_TCPPAYLOAD,
       C_NPI_BURST_SIZE     => C_NPI_BURST_SIZE,
       C_NPI_ADDR_WIDTH     => C_NPI_ADDR_WIDTH,
       C_NPI_DATA_WIDTH     => C_NPI_DATA_WIDTH,
       C_NPI_BE_WIDTH       => C_NPI_BE_WIDTH,
       C_NPI_RDWDADDR_WIDTH => C_NPI_RDWDADDR_WIDTH
     )
     port  map
     (
       tst_user_dreq       => gie_reg_en,
       TCP_StrtClnt        => gie_reg_en,

       NPI_Clk             => NPI_Clk,
       NPI_RST             => NPI_RST,
       NPI_Addr            => int_NPI_Addr,
       NPI_AddrReq         => int_NPI_AddrReq,
       NPI_AddrAck         => NPI_AddrAck,
       NPI_RNW             => int_NPI_RNW,
       NPI_Size            => int_NPI_Size,
       NPI_WrFIFO_Data     => int_NPI_WrFIFO_Data,
       NPI_WrFIFO_BE       => NPI_WrFIFO_BE,
       NPI_WrFIFO_Push     => int_NPI_WrFIFO_Push,
       NPI_RdFIFO_Data     => NPI_RdFIFO_Data,
       NPI_RdFIFO_Pop      => NPI_RdFIFO_Pop,
       NPI_RdFIFO_RdWdAddr => NPI_RdFIFO_RdWdAddr,
       NPI_WrFIFO_Empty    => NPI_WrFIFO_Empty,
       NPI_WrFIFO_AlmostFull => NPI_WrFIFO_AlmostFull,
       NPI_WrFIFO_Flush    => NPI_WrFIFO_Flush,
       NPI_RdFIFO_Empty    => NPI_RdFIFO_Empty,
       NPI_RdFIFO_Flush    => int_NPI_RdFIFO_Flush,
       NPI_RdFIFO_Latency  => NPI_RdFIFO_Latency,
       NPI_RdModWr         => int_NPI_RdModWr,
       NPI_InitDone        => NPI_InitDone,
		 
		 --------------- Memory Controller Interface, VFBC mode (Adil) -----
		 VFBC2_cmd_clk 				=> VFBC2_cmd_clk,
		 VFBC2_cmd_reset 			=> VFBC2_cmd_reset,
		 VFBC2_cmd_data 			=> VFBC2_cmd_data,
		 VFBC2_cmd_write 			=> VFBC2_cmd_write,
		 VFBC2_cmd_end 				=> VFBC2_cmd_end,
		 VFBC2_cmd_full				=> VFBC2_cmd_full,
		 VFBC2_cmd_almost_full	=> VFBC2_cmd_almost_full,  
		 VFBC2_cmd_idle 			=>	VFBC2_cmd_idle,		
		 VFBC2_wd_clk				=> VFBC2_wd_clk, 					
		 VFBC2_wd_reset				=> VFBC2_wd_reset, 				
		 VFBC2_wd_write				=> VFBC2_wd_write, 				
		 VFBC2_wd_end_burst		=> VFBC2_wd_end_burst, 			
		 VFBC2_wd_flush				=> VFBC2_wd_flush, 				
		 VFBC2_wd_data				=> VFBC2_wd_data, 				
		 VFBC2_wd_data_be 			=> VFBC2_wd_data_be,	
		 VFBC2_wd_full 				=> VFBC2_wd_full,				
		 VFBC2_wd_almost_full 	=> VFBC2_wd_almost_full,		
		 VFBC2_rd_clk				=> VFBC2_rd_clk, 					
		 VFBC2_rd_reset				=> VFBC2_rd_reset, 				
		 VFBC2_rd_read				=> VFBC2_rd_read, 				
		 VFBC2_rd_end_burst		=> VFBC2_rd_end_burst, 			
		 VFBC2_rd_flush				=> VFBC2_rd_flush, 				
		 VFBC2_rd_data				=> VFBC2_rd_data, 				
		 VFBC2_rd_empty				=> VFBC2_rd_empty, 				
		 VFBC2_rd_almost_empty	=> VFBC2_rd_almost_empty,
		 --------------- Memory Controller Interface, VFBC mode (Adil) -----

       Clk                 => Bus2IP_Clk,
       Rst                 => Bus2IP_Reset,
		 PHY_rx_clk				=> PHY_rx_clk,
		 
		 -- LEDs
		 GPIO_IO => GPIO_IO,

       -- TX path (in)
       tx_DPM_adr_MAC      => tx_DPM_adr,
       tx_ping_rd_data_MAC => tx_ping_rd_data_MAC,
       transmit_start      => transmit_start,
       tx_done_MAC         => tx_done,

       -- Control path (out)
       OrbCmd_start_tx     => OrbCmd_start_tx,

       -- TX path (out)
       tx_done_SW         => tx_done_SW,
       tx_ping_rd_data_SW => tx_ping_rd_data,
       tx_packet_len_SW   => tx_packet_len_SW,
       
       -- RX path (in)
       rx_ping_ce          => rx_ping_ce,  
       rx_DPM_wr_rd_n      => rx_DPM_wr_rd_n, 
       rx_DPM_adr          => rx_DPM_adr,  
       rx_DPM_wr_data      => rx_DPM_wr_data, 
       rx_done             => rx_done,

------------------------ ChipScope TEST (akzare) -------------------    
tst_macnewFrameByte  => tst_macnewFrameByte, 
tst_macframeData     => tst_macframeData, 

tst_tcphndl_wrRAM => tst_tcphndl_wrRAM,
tst_tcphndl_wrData => tst_tcphndl_wrData,

tst_tcpcmpltRec => tst_tcpcmpltRec,
tst_tcpnewByteRec => tst_tcpnewByteRec,
tst_tcpinByteRec => tst_tcpinByteRec,
tst_tcpbusyXmit => tst_tcpbusyXmit,
tst_tcpsendTCP => tst_tcpsendTCP,

tst_ipnewFrame => tst_ipnewFrame,
tst_ipframeType => tst_ipframeType,
tst_ipcnt => tst_ipcnt,
tst_ipinByte => tst_ipinByte,
tst_ipnewByte => tst_ipnewByte, 
tst_ipnewDatagram => tst_ipnewDatagram,
tst_ippresstate => tst_ippresstate,

tst_tcppresstateRec => tst_tcppresstateRec,
tst_tcppresstateXmit => tst_tcppresstateXmit,
tst_tcppresstateSrv => tst_tcppresstateSrv,
tst_tcprx_done => tst_tcprx_done,

tst_arprecpresstate => tst_arprecpresstate,
tst_arprecnewFrame => tst_arprecnewFrame,
tst_arprecframeType => tst_arprecframeType,

tst_arpxmitpresstate => tst_arpxmitpresstate,

tst_macxmit_start => tst_macxmit_start,
tst_arpxmit_genFrame => tst_arpxmit_genFrame,

tst_DMA_DREQ => tst_DMA_DREQ,
tst_DMA_DACK => tst_DMA_DACK,
tst_DMA_INIT => tst_DMA_INIT,
tst_DMA_DATA => tst_DMA_DATA,

tst_burst_cnt_one => tst_burst_cnt_one,
tst_burst_cnt => tst_burst_cnt,

tst_user_read => tst_user_read,
tst_user_drdy => tst_user_drdy,
tst_fifo_data_out => tst_fifo_data_out,

tst_fifo_wr_count => tst_fifo_wr_count,
tst_fifowr_rd_count => tst_fifowr_rd_count,
tst_fifo_wr_en => tst_fifo_wr_en,

tst_tcp_RcvOvrHd_TrigSg => tst_tcp_RcvOvrHd_TrigSg,
------------------------ ChipScope TEST (akzare) -------------------    
       triger_signal       => int_trig_sig(0),
       
       -- RX path (out)
       OrbCmd_clr_rx_stats => OrbCmd_clr_rx_stats,
       rx_done_SW          => rx_done_SW
       );
   -- akzare: end
  
  
   -- IP2INTC_Irpt generation if global interrupt is enable
   ip2intc_irpt_i <= gie_enable and ((rx_done_SW and rx_intr_en) or -- akzare rx_done -> rx_done_SW
                                     (tx_done_SW and tx_intr_en)); -- akzare tx_done -> tx_done_SW
   ----------------------------------------------------------------------------
   -- IP2INTC_IRPT register 
   ----------------------------------------------------------------------------
   IP2INTC_IRPT_REG_I: FDR
     port map (
       Q => IP2INTC_Irpt ,  --[out]
       C => Bus2IP_Clk ,    --[in]
       D => ip2intc_irpt_i, --[in]
       R => Bus2IP_Reset    --[in]
     );

   ----------------------------------------------------------------------------
   -- IPIF interface 
   ----------------------------------------------------------------------------
   XPS_IPIF_I : entity hardorb_fpga_v3_01_a.xps_ipif_ssp1 
     generic map 
     (
           C_FAMILY                => C_FAMILY,
           C_SPLB_AWIDTH           => C_SPLB_AWIDTH,
           C_SPLB_DWIDTH           => C_SPLB_DWIDTH,
           C_SPLB_P2P              => C_SPLB_P2P,
           C_SPLB_MID_WIDTH        => C_SPLB_MID_WIDTH,
           C_SPLB_NUM_MASTERS      => C_SPLB_NUM_MASTERS,
           C_SPLB_SUPPORT_BURSTS   => C_SPLB_SUPPORT_BURSTS,
           C_SPLB_SMALLEST_MASTER  => C_SPLB_SMALLEST_MASTER,
           C_SPLB_NATIVE_DWIDTH    => C_SPLB_NATIVE_DWIDTH ,
           C_BASEADDR              => C_BASEADDR,
           C_HIGHADDR              => C_HIGHADDR
     )
     port  map
     (
             SPLB_Clk              => SPLB_Clk,
             SPLB_Rst              => SPLB_Rst,
             PLB_ABus              => PLB_ABus,
             PLB_UABus             => PLB_UABus,
             PLB_PAValid           => PLB_PAValid,
             PLB_SAValid           => PLB_SAValid,
             PLB_rdPrim            => PLB_rdPrim,
             PLB_wrPrim            => PLB_wrPrim,
             PLB_masterID          => PLB_masterID,
             PLB_abort             => PLB_abort,
             PLB_busLock           => PLB_busLock,
             PLB_RNW               => PLB_RNW,
             PLB_BE                => PLB_BE,
             PLB_MSize             => PLB_MSize,
             PLB_size              => PLB_size,
             PLB_type              => PLB_type,
             PLB_lockErr           => PLB_lockErr,
             PLB_wrDBus            => PLB_wrDBus,
             PLB_wrBurst           => PLB_wrBurst,
             PLB_rdBurst           => PLB_rdBurst,
             PLB_wrPendReq         => PLB_wrPendReq,
             PLB_rdPendReq         => PLB_rdPendReq,
             PLB_wrPendPri         => PLB_wrPendPri,
             PLB_rdPendPri         => PLB_rdPendPri,
             PLB_reqPri            => PLB_reqPri,
             PLB_TAttribute        => PLB_TAttribute,
             Sl_addrAck            => Sl_addrAck,
             Sl_SSize              => Sl_SSize,
             Sl_wait               => Sl_wait,
             Sl_rearbitrate        => Sl_rearbitrate,
             Sl_wrDAck             => Sl_wrDAck,
             Sl_wrComp             => Sl_wrComp,
             Sl_wrBTerm            => Sl_wrBTerm,
             Sl_rdDBus             => Sl_rdDBus,
             Sl_rdWdAddr           => Sl_rdWdAddr,
             Sl_rdDAck             => Sl_rdDAck,
             Sl_rdComp             => Sl_rdComp,
             Sl_rdBTerm            => Sl_rdBTerm,
             Sl_MBusy              => Sl_MBusy,
             Sl_MWrErr             => Sl_MWrErr,
             Sl_MRdErr             => Sl_MRdErr,
             Sl_MIRQ               => Sl_MIRQ,
             Bus2IP_Clk            => Bus2IP_Clk,
             Bus2IP_Reset          => Bus2IP_Reset,
             IP2Bus_Data           => IP2Bus_Data,
             Bus2IP_Data           => Bus2IP_Data,
             Bus2IP_Addr           => temp_Bus2IP_Addr,
             Bus2IP_RdCE           => Bus2IP_RdCE,
             Bus2IP_WrCE           => Bus2IP_WrCE,
             Bus2IP_WrReq          => bus2ip_wrreq,        
             Bus2IP_RdReq          => bus2ip_rdreq, 
             Bus2IP_BE             => bus2ip_be,
             Bus2IP_Burst          => bus2ip_burst,
             IP2Bus_AddrAck        => ip2bus_addrack,          
             IP2Bus_WrAck          => ip2bus_wrack,
             IP2Bus_RdAck          => ip2bus_rdack
     );
     
   ----------------------------------------------------------------------------
   -- Usinng 12-bits of Bus2IP_addr for decoding
   ----------------------------------------------------------------------------
   BUS2IP_ADD_GEN:for i in 0 to 12 generate
      bus2ip_addr(i) <=temp_Bus2IP_Addr((temp_Bus2IP_Addr'high - 12) + i);
   end generate;

   -- PHY_tx_data conversion
   PHY_tx_data(0) <= phy_tx_data_i(3);
   PHY_tx_data(1) <= phy_tx_data_i(2);
   PHY_tx_data(2) <= phy_tx_data_i(1);
   PHY_tx_data(3) <= phy_tx_data_i(0);                 
   
   -- PHY_rx_data conversion
   phy_rx_data_i(0) <= PHY_rx_data(3);
   phy_rx_data_i(1) <= PHY_rx_data(2);
   phy_rx_data_i(2) <= PHY_rx_data(1);
   phy_rx_data_i(3) <= PHY_rx_data(0);      

   ----------------------------------------------------------------------------
   -- EMAC
   ----------------------------------------------------------------------------   
   EMAC_I: entity hardorb_fpga_v3_01_a.emac
     generic map (
       C_DEBUG_MODE        => C_DEBUG_MODE,
       
       C_DUPLEX            => C_DUPLEX,
       NODE_MAC            => to_bitvector(NODE_MAC), -- akzare NODE_MAC -> to_bitvector(NODE_MAC)
       C_FAMILY            => C_FAMILY  
       )                   
     port map (            
       Clk                 => Bus2IP_Clk,
       Rst                 => Bus2IP_Reset,
       Phy_tx_clk          => PHY_tx_clk,
       Phy_rx_clk          => PHY_rx_clk,
       Phy_crs             => phy_crs,
       Phy_dv              => Phy_dv,
       Phy_rx_data         => Phy_rx_data_i,
       Phy_col             => Phy_col,
       Phy_rx_er           => Phy_rx_er,
       Phy_tx_en           => int_Phy_tx_en,
       Phy_tx_data         => Phy_tx_data_i,
       Tx_DPM_ce           => tx_DPM_ce_i, -- changed 03-03-05
       Tx_DPM_adr          => tx_DPM_adr,
       Tx_DPM_wr_data      => tx_DPM_wr_data,
       Tx_DPM_rd_data      => tx_DPM_rd_data,
       Tx_DPM_wr_rd_n      => tx_DPM_wr_rd_n,
       Tx_done             => tx_done,
       Tx_pong_ping_l      => tx_pong_ping_l,
       Tx_idle             => tx_idle,
       Rx_idle             => rx_idle,
       Rx_DPM_ce           => rx_DPM_ce_i, -- changed 03-03-05
       Rx_DPM_adr          => rx_DPM_adr,
       Rx_DPM_wr_data      => rx_DPM_wr_data,
       Rx_DPM_rd_data      => rx_DPM_rd_data,
       Rx_DPM_wr_rd_n      => rx_DPM_wr_rd_n ,
       Rx_done             => rx_done,
       Rx_pong_ping_l      => rx_pong_ping_l,
       Tx_packet_length    => tx_packet_length,
       Transmit_start      => transmit_start,
       Mac_program_start   => mac_program_start,
------------------------ TEST -------------------    
         tst_mactx_goto_SFD =>  tst_mactx_goto_SFD,
         tst_mactx_SFD =>  tst_mactx_SFD,
------------------------ TEST -------------------    
       
       Rx_buffer_ready     => rx_buffer_ready 
       );
   ----------------------------------------------------------------------------   
   
   -- This core only supports word access
   word_access <= '1' when bus2ip_be="1111" else '0';
  
   -- DPRAM buffer chip enable generation
   bus2ip_ce     <= (Bus2IP_RdCE or Bus2IP_WrCE) and word_access;
   tx_ping_ce_en <= not Bus2IP_Addr(0) and not Bus2IP_Addr(1);
   rx_ping_ce_en <= Bus2IP_Addr(0) and not Bus2IP_Addr(1);
   
   IPIF_tx_Ping_CE <= bus2ip_ce_d1 and tx_ping_ce_en;
   IPIF_rx_Ping_CE <= bus2ip_ce_d1 and rx_ping_ce_en;
   
   -- IP2Bus_Ack generation
   ip2bus_wrack    <= dpm_wr_ack;
   ip2bus_rdack    <= dpm_rd_ack;
   ip2bus_addrack  <= dpm_addr_ack;
   
   -- Address ack generation
   dpm_addr_ack <= (bus2ip_wrreq or bus2ip_rdreq) ;
   
    
   -- IP2Bus_Data generation
   IP2BUS_DATA_GENERATE: for i in 0 to 31 generate
      IP2Bus_Data(i) <= ((
                          (tx_ping_data_out(i) and IPIF_tx_Ping_CE)  or
                          (tx_pong_data_out(i) and IPIF_tx_Pong_CE)  or
                          (rx_ping_data_out(i) and IPIF_rx_Ping_CE)  or
                          (rx_pong_data_out(i) and IPIF_rx_Pong_CE)
                         ) and not reg_access_d1)
                        or
                        ((
                          (reg_data_out(i)  and not mdio_reg_en) or
                          (mdio_data_out(i) and     mdio_reg_en)    
                         ) and reg_access_d1) ;

   end generate IP2BUS_DATA_GENERATE;   


   ----------------------------------------------------------------------------
   -- ADDR_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process registers bus2ip_addr and bus2ip_ce and bus2ip_rdreq to  
   -- support burst transactions on DPRAM.
   ----------------------------------------------------------------------------
   ADDR_REG_PROCESS:process (Bus2IP_Clk)
   begin
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then
            bus2ip_addr_d1  <= (others =>'0');
            bus2ip_ce_d1    <= '0';
            bus2ip_rdreq_d1 <= '0';
         else
            bus2ip_addr_d1  <= bus2ip_addr;      
            bus2ip_ce_d1    <= bus2ip_ce;
            bus2ip_rdreq_d1 <= bus2ip_rdreq;
         end if;
      end if;
   end process;   
   
   
   ----------------------------------------------------------------------------
   -- RD_ACK_PROCESS
   ----------------------------------------------------------------------------
   -- This process generate read ack for the IPIF using bus2ip_rdreq
   ----------------------------------------------------------------------------
   RD_ACK_PROCESS:process (Bus2IP_Clk)
   begin
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then
            dpm_rd_ack <= '0';
         elsif (bus2ip_rdreq_d1 = '1') then
            dpm_rd_ack <= '1';
         else
            dpm_rd_ack <= '0';
         end if;
      end if;
   end process;   
   
   ----------------------------------------------------------------------------
   -- WR_ACK_PROCESS
   ----------------------------------------------------------------------------
   -- This process generate write ack for the IPIF using bus2ip_wrreq
   ----------------------------------------------------------------------------
   WR_ACK_PROCESS:process (Bus2IP_Clk)
   begin
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then
            dpm_wr_ack <= '0';
         elsif (bus2ip_wrreq = '1') then
            dpm_wr_ack <= '1';
         else
            dpm_wr_ack <= '0';
         end if;
      end if;
   end process;   
   

   ----------------------------------------------------------------------------
   -- DPM_TX_RD_DATA_GENERATE
   ----------------------------------------------------------------------------
   -- This logic generates tx_DPM_rd_data for transmit section from 
   -- tx_ping_buffer and tx_pong_buffer. 
   ----------------------------------------------------------------------------
   DPM_TX_RD_DATA_GENERATE: for i in 0 to 3 generate
      tx_DPM_rd_data(i) <= (tx_ping_rd_data(i) and not tx_pong_ping_l 
                                               and (not tx_idle)) or
                            (tx_pong_rd_data(i) and     tx_pong_ping_l
                                                and (not tx_idle));    
   end generate DPM_TX_RD_DATA_GENERATE; 

   ----------------------------------------------------------------------------
   -- DPM_RX_RD_DATA_GENERATE
   ----------------------------------------------------------------------------
   -- This logic generates rx_DPM_rd_data for receive section from 
   -- rx_ping_buffer and rx_pong_buffer. 
   ----------------------------------------------------------------------------
   DPM_RX_RD_DATA_GENERATE: for i in 0 to 3 generate
      rx_DPM_rd_data(i) <= (rx_ping_rd_data(i) and not rx_pong_ping_l) or
                           (rx_pong_rd_data(i) and     rx_pong_ping_l);
   end generate DPM_RX_RD_DATA_GENERATE;
    
   -- Chip enable generation
   tx_ping_ce <= tx_DPM_ce and not tx_pong_ping_l;
   tx_DPM_ce  <= tx_DPM_ce_i;
   rx_DPM_ce  <= rx_DPM_ce_i;
   rx_ping_ce <= rx_DPM_ce and not rx_pong_ping_l; 
   
   ----------------------------------------------------------------------------
   -- TX_PING Buffer 
   ----------------------------------------------------------------------------
   TX_PING: entity hardorb_fpga_v3_01_a.emac_dpram
     generic map (
       C_FAMILY             => C_FAMILY
       )
     port map (   
       Clk                  => Bus2IP_Clk                 ,
       Rst                  => Bus2IP_Reset               ,
       Ce_a                 => tx_ping_ce                 ,
       Wr_rd_n_a            => tx_DPM_wr_rd_n             ,
       Adr_a                => tx_DPM_adr                 ,
       Data_in_a            => tx_DPM_wr_data             ,
       Data_out_a           => tx_ping_rd_data_MAC        , -- akzare tx_ping_rd_data -> tx_ping_rd_data_MAC
       Ce_b                 => IPIF_tx_Ping_CE            , 
       Wr_rd_n_b            => dpm_wr_ack                 ,
       Adr_b                => bus2ip_addr_d1(2 to 10)    ,
       Data_in_b( 0 to  7)  => Bus2IP_Data(24 to 31)      ,
       Data_in_b( 8 to 15)  => Bus2IP_Data(16 to 23)      ,
       Data_in_b(16 to 23)  => Bus2IP_Data( 8 to 15)      ,
       Data_in_b(24 to 31)  => Bus2IP_Data( 0 to  7)      ,
       Data_out_b( 0 to  7) => tx_ping_data_out(24 to 31) ,
       Data_out_b( 8 to 15) => tx_ping_data_out(16 to 23) ,
       Data_out_b(16 to 23) => tx_ping_data_out( 8 to 15) ,
       Data_out_b(24 to 31) => tx_ping_data_out( 0 to  7)  
       );          
   
  
   ----------------------------------------------------------------------------
   -- RX_PING Buffer 
   ----------------------------------------------------------------------------
   RX_PING: entity hardorb_fpga_v3_01_a.emac_dpram
     generic map (
       C_FAMILY             => C_FAMILY
       )
     port map (         
       Clk                  => Bus2IP_Clk                 ,
       Rst                  => Bus2IP_Reset               , 
       Ce_a                 => rx_ping_ce                 ,  
       Wr_rd_n_a            => rx_DPM_wr_rd_n             , 
       Adr_a                => rx_DPM_adr                 ,  
       Data_in_a            => rx_DPM_wr_data             , 
       Data_out_a           => rx_ping_rd_data            , 
       Ce_b                 => IPIF_rx_Ping_CE            ,
       Wr_rd_n_b            => dpm_wr_ack                 ,
       Adr_b                => bus2ip_addr_d1(2 to 10)    ,
       Data_in_b( 0 to  7)  => Bus2IP_Data(24 to 31)      ,
       Data_in_b( 8 to 15)  => Bus2IP_Data(16 to 23)      ,
       Data_in_b(16 to 23)  => Bus2IP_Data( 8 to 15)      ,
       Data_in_b(24 to 31)  => Bus2IP_Data( 0 to  7)      ,
       Data_out_b( 0 to  7) => rx_ping_data_out(24 to 31) ,
       Data_out_b( 8 to 15) => rx_ping_data_out(16 to 23) ,
       Data_out_b(16 to 23) => rx_ping_data_out( 8 to 15) ,
       Data_out_b(24 to 31) => rx_ping_data_out( 0 to  7) 
       );
      

   ----------------------------------------------------------------------------
   -- TX Done register 
   ----------------------------------------------------------------------------
   TX_DONE_D1_I: FDR
     port map (
       Q => tx_done_d1 , --[out]
       C => Bus2IP_Clk , --[in]
       D => tx_done    , --[in]
       R => Bus2IP_Reset --[in]
     );
       
   TX_DONE_D2_I: FDR
     port map (
       Q => tx_done_d2 , --[out]
       C => Bus2IP_Clk , --[in]
       D => tx_done_d1 , --[in]
       R => Bus2IP_Reset --[in]
     );

   ----------------------------------------------------------------------------
   -- Transmit Pong memory generate
   ----------------------------------------------------------------------------
   TX_PONG_GEN: if C_TX_PING_PONG = 1 generate
   
      signal tx_pong_ce        : std_logic;
      signal pp_tog_ce         : std_logic;
      
      attribute INIT                  : string;
      
      -- attribute INIT of PP_TOG_LUT_I: label is "1111";
      
      Begin
      
         TX_PONG_I: entity hardorb_fpga_v3_01_a.emac_dpram
           generic map (
             C_FAMILY             => C_FAMILY
             )                    
           port map (             
             Clk                  => Bus2IP_Clk                 ,
             Rst                  => Bus2IP_Reset               ,
             Ce_a                 => tx_pong_ce                 , 
             Wr_rd_n_a            => tx_DPM_wr_rd_n             ,
             Adr_a                => tx_DPM_adr                 ,
             Data_in_a            => tx_DPM_wr_data             ,
             Data_out_a           => tx_pong_rd_data            ,
             Ce_b                 => IPIF_tx_Pong_CE            ,      
             Wr_rd_n_b            => dpm_wr_ack                 ,
             Adr_b                => bus2ip_addr_d1(2 to 10)    ,
             Data_in_b( 0 to  7)  => Bus2IP_Data(24 to 31)      ,
             Data_in_b( 8 to 15)  => Bus2IP_Data(16 to 23)      ,
             Data_in_b(16 to 23)  => Bus2IP_Data( 8 to 15)      ,
             Data_in_b(24 to 31)  => Bus2IP_Data( 0 to  7)      ,
             Data_out_b( 0 to  7) => tx_pong_data_out(24 to 31) ,
             Data_out_b( 8 to 15) => tx_pong_data_out(16 to 23) ,
             Data_out_b(16 to 23) => tx_pong_data_out( 8 to 15) ,
             Data_out_b(24 to 31) => tx_pong_data_out( 0 to  7) 
             );          
      
      -- TX Pong Buffer Chip enable
      tx_pong_ce <= tx_DPM_ce and tx_pong_ping_l;
      
      IPIF_tx_Pong_CE <= bus2ip_ce and not Bus2IP_Addr(0) 
                                       and Bus2IP_Addr(1);
      
      -------------------------------------------------------------------------
      -- TX_PONG_PING_L_PROCESS
      -------------------------------------------------------------------------
      -- This process generate tx_pong_ping_l for TX PING/PONG buffer access
      -------------------------------------------------------------------------
      TX_PONG_PING_L_PROCESS:process (Bus2IP_Clk)
      begin   -- process
          if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if (Bus2IP_Reset = '1') then
                tx_pong_ping_l <= '0';
             elsif (tx_done_d1 = '1' ) then
                   tx_pong_ping_l <= not tx_pong_ping_l;
             elsif (pong_tx_status = '1' and ping_tx_status = '0' ) then
                   tx_pong_ping_l <= '1';
             elsif (pong_tx_status = '0' and ping_tx_status = '1' ) then
                   tx_pong_ping_l <= '0';
             else
                tx_pong_ping_l <= tx_pong_ping_l;
             end if;
          end if;
      end process;   

   end generate TX_PONG_GEN; 
   
   
   
   ----------------------------------------------------------------------------
   -- RX Done register 
   ----------------------------------------------------------------------------
   RX_DONE_D1_I: FDR
     port map (
       Q => rx_done_d1 , --[out]
       C => Bus2IP_Clk , --[in]
       D => rx_done_SW , --[in] -- akzare rx_done -> rx_done_SW
       R => Bus2IP_Reset --[in]
     );
   
   ----------------------------------------------------------------------------
   -- Receive Pong memory generate
   ----------------------------------------------------------------------------
   RX_PONG_GEN: if C_RX_PING_PONG = 1 generate
   
      signal rx_pong_ce        : std_logic;
   
      Begin
      
        RX_PONG_I: entity hardorb_fpga_v3_01_a.emac_dpram
          generic map (
            C_FAMILY             => C_FAMILY
            )                    
          port map (             
            Clk                  => Bus2IP_Clk                 ,
            Rst                  => Bus2IP_Reset               ,
            Ce_a                 => rx_pong_ce                 , 
            Wr_rd_n_a            => rx_DPM_wr_rd_n             ,
            Adr_a                => rx_DPM_adr                 ,
            Data_in_a            => rx_DPM_wr_data             ,
            Data_out_a           => rx_pong_rd_data            ,
            Ce_b                 => IPIF_rx_Pong_CE            ,      
            Wr_rd_n_b            => dpm_wr_ack                 ,
            Adr_b                => bus2ip_addr_d1(2 to 10)    ,
            Data_in_b( 0 to  7)  => Bus2IP_Data(24 to 31)      ,
            Data_in_b( 8 to 15)  => Bus2IP_Data(16 to 23)      ,
            Data_in_b(16 to 23)  => Bus2IP_Data( 8 to 15)      ,
            Data_in_b(24 to 31)  => Bus2IP_Data( 0 to  7)      ,
            Data_out_b( 0 to  7) => rx_pong_data_out(24 to 31) ,
            Data_out_b( 8 to 15) => rx_pong_data_out(16 to 23) ,
            Data_out_b(16 to 23) => rx_pong_data_out( 8 to 15) ,
            Data_out_b(24 to 31) => rx_pong_data_out( 0 to  7) 
            );          
      
      -- RX Pong Buffer enable
      rx_pong_ce <= rx_DPM_ce and rx_pong_ping_l;
   
      IPIF_rx_Pong_CE <= bus2ip_ce  and Bus2IP_Addr(0) 
                                    and Bus2IP_Addr(1);
      -------------------------------------------------------------------------
      -- RX_PONG_PING_L_PROCESS
      -------------------------------------------------------------------------
      -- This process generate rx_pong_ping_l for RX PING/PONG buffer access
      -------------------------------------------------------------------------
        RX_PONG_PING_L_PROCESS:process (Bus2IP_Clk)
         begin   -- process
            if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
               if (Bus2IP_Reset = '1') then
                  rx_pong_ping_l <= '0';
               elsif (rx_done_d1 = '1') then
                  if rx_pong_ping_l = '0' then
                     rx_pong_ping_l <= '1';
                  else
                     rx_pong_ping_l <= '0';
                 end if;
               else
                  rx_pong_ping_l <= rx_pong_ping_l;
               end if;
            end if;
         end process;   

   end generate RX_PONG_GEN; 

   ----------------------------------------------------------------------------
   -- Regiter Address Decoding
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   -- Register Address Space
   -----------------------------------------
   -- **** MDIO Registers offset ****
   --       Address Register    => 0x07E4
   --       Write Data Register => 0x07E8
   --       Read Data Register  => 0x07Ec
   --       Control Register    => 0x07F0
   -----------------------------------------
   -- **** Transmit Registers offset ****
   --       Ping Length Register  => 0x07F4
   --       Ping Control Register => 0x07FC
   --       Pong Length  Register => 0x0FF4
   --       Pong Control Register => 0x0FFC
   -----------------------------------------
   -- **** Receive Registers offset ****
   --       Ping Control Register => 0x17FC
   --       Pong Control Register => 0x1FFC
   ------------------------------------------
   -- bus2ip_addr(0 to 12)= plb_addr (19 to 31)
   ----------------------------------------------------------------------------
   reg_access_i <= '1' when bus2ip_ce = '1' and bus2ip_addr(2 to 7) = "111111" 
                 else '0';
   
   
   -- Register access enable
   reg_en <= reg_access and (not bus2ip_burst);
   
   -- TX/RX PING/PONG address decode
   tx_ping_reg_en <= reg_en and (not bus2ip_addr(0)) and (not bus2ip_addr(1));
   rx_ping_reg_en <= reg_en and (    bus2ip_addr(0)) and (not bus2ip_addr(1));

   -- Status/Control/Length address decode
   stat_reg_en <= not (bus2ip_addr(8) and bus2ip_addr(9) and bus2ip_addr(10));
   control_reg <= bus2ip_addr(8) and      bus2ip_addr(9)  and bus2ip_addr(10);
   length_reg  <= bus2ip_addr(8) and (not bus2ip_addr(9)) and bus2ip_addr(10);
   gie_reg     <= bus2ip_addr(8) and bus2ip_addr(9) and (not bus2ip_addr(10));
                                                          


   ---- TX/RX Ping/Pong Control/Length reg enable
   tx_ping_ctrl_reg_en   <= tx_ping_reg_en and control_reg; 
   tx_ping_length_reg_en <= tx_ping_reg_en and length_reg;
   rx_ping_ctrl_reg_en   <= rx_ping_reg_en and control_reg;
   gie_reg_en            <= tx_ping_reg_en and gie_reg;

   
   ----------------------------------------------------------------------------
   -- REG_ACCESS_PROCESS  
   ----------------------------------------------------------------------------
   -- Registering the reg_access to break long timing path 
   ----------------------------------------------------------------------------
   REG_ACCESS_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            reg_access     <= '0'; 
            reg_access_d1  <= '0'; 
         else   
            -- TX/RX Ping/Pong Control/Length reg enable
            reg_access     <= reg_access_i; 
            reg_access_d1  <= reg_access; 
         end if;
      end if;   
   end process REG_ACCESS_PROCESS;
 
   ----------------------------------------------------------------------------
   -- TX_PONG_REG_GEN : Receive Pong Register generate
   ----------------------------------------------------------------------------
   -- This Logic is included only if both the buffers are enabled. 
   ----------------------------------------------------------------------------
   TX_PONG_REG_GEN: if C_TX_PING_PONG = 1 generate

      tx_pong_reg_en      <= reg_en and (not bus2ip_addr(0)) 
                                    and (bus2ip_addr(1));
      tx_pong_ctrl_reg_en <= '1' when (tx_pong_reg_en='1') and 
                                      (control_reg='1')    else
                             '0';

      tx_pong_length_reg_en <= '1' when (tx_pong_reg_en='1') and 
                                        (length_reg='1') else
                               '0';

      -------------------------------------------------------------------------
      -- TX_PONG_CTRL_REG_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request and
      -- the control register is enabled.
      -------------------------------------------------------------------------
      TX_PONG_CTRL_REG_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               pong_mac_program   <= '0';
               pong_tx_status     <= '0';
               pong_soft_status   <= '0';
            elsif (Bus2IP_WrCE = '1' and tx_pong_ctrl_reg_en = '1') then         
               --  Load Pong Control Register with PLB
               --  data if there is a write request
               --  and the control register is enabled
               pong_soft_status   <= Bus2IP_Data(0);
               pong_mac_program   <= Bus2IP_Data(30);
               pong_tx_status     <= Bus2IP_Data(31);
            -- Clear the status bit when trnasmit complete
            elsif (tx_done_d1 = '1' and tx_pong_ping_l = '1') then 
               pong_tx_status     <= '0';
               pong_mac_program   <= '0';
            end if;
         end if;
      end process TX_PONG_CTRL_REG_PROCESS;

      -------------------------------------------------------------------------
      -- TX_PONG_LENGTH_REG_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request and
      -- the length register is enabled.
      -------------------------------------------------------------------------
      TX_PONG_LENGTH_REG_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               pong_pkt_lenth <= (others=>'0');
            elsif (Bus2IP_WrCE = '1' and tx_pong_length_reg_en = '1') then         
               --  Load Packet length Register with PLB
               --  data if there is a write request
               --  and the length register is enabled
               pong_pkt_lenth <= Bus2IP_Data(16 to 31);
            end if;
         end if;
      end process TX_PONG_LENGTH_REG_PROCESS;

   end generate TX_PONG_REG_GEN; 

   ----------------------------------------------------------------------------
   -- NO_TX_PING_SIG :No Pong registers
   ----------------------------------------------------------------------------
   NO_TX_PING_SIG: if C_TX_PING_PONG = 0 generate
   
      tx_pong_ping_l        <= '0';
      tx_pong_length_reg_en <= '0';
      tx_pong_ctrl_reg_en   <= '0';
      pong_pkt_lenth        <= (others=>'0');
      pong_mac_program      <= '0';
      pong_tx_status        <= '0';
      IPIF_tx_Pong_CE       <= '0';
      tx_pong_data_out      <= (others=>'0');
      tx_pong_rd_data       <= (others=>'0');


   end generate NO_TX_PING_SIG;


   ----------------------------------------------------------------------------
   -- RX_PONG_REG_GEN: Receive Pong Register generate
   ----------------------------------------------------------------------------
   -- This Logic is included only if both the buffers are enabled. 
   ----------------------------------------------------------------------------
   RX_PONG_REG_GEN: if C_RX_PING_PONG = 1 generate

      rx_pong_reg_en      <= reg_en and (bus2ip_addr(0)) and (bus2ip_addr(1));
      rx_pong_ctrl_reg_en <= '1' when (rx_pong_reg_en='1') and 
                                      (control_reg='1')    else
                             '0';

      -- Receive frame indicator                     
      rx_buffer_ready     <= not (ping_rx_status and pong_rx_status);                   

      -------------------------------------------------------------------------
      -- RX_PONG_CTRL_REG_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request and
      -- the Pong control register is enabled.
      -------------------------------------------------------------------------
      RX_PONG_CTRL_REG_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
                pong_rx_status   <= '0';
            elsif (Bus2IP_WrCE = '1' and rx_pong_ctrl_reg_en = '1') then            
               --  Load Control Register with PLB
               --  data if there is a write request
               --  and the control register is enabled
               pong_rx_status   <= Bus2IP_Data(31);
            -- Clear the status bit when trnasmit complete
            --elsif (rx_done_d1 = '1' and rx_pong_ping_l = '1') then   
            elsif (rx_done = '1' and rx_pong_ping_l = '1') then   
               pong_rx_status   <= '1';
            end if;
         end if;
      end process RX_PONG_CTRL_REG_PROCESS;

   end generate RX_PONG_REG_GEN; 

   ----------------------------------------------------------------------------
   -- No Pong registers
   ----------------------------------------------------------------------------
   NO_RX_PING_SIG: if C_RX_PING_PONG = 0 generate
   
      rx_pong_ping_l      <= '0';
      rx_pong_reg_en      <= '0';
      rx_pong_ctrl_reg_en <= '0';
      pong_rx_status      <= '0';
      IPIF_rx_Pong_CE     <= '0';
      rx_pong_rd_data     <= (others=>'0');
      rx_pong_data_out    <= (others=>'0');

      -- Receive frame indicator                     
      rx_buffer_ready     <= not ping_rx_status ;                   

   end generate NO_RX_PING_SIG;
   
   ----------------------------------------------------------------------------
   -- TX_PING_CTRL_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   ----------------------------------------------------------------------------
   TX_PING_CTRL_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            tx_intr_en       <= '0';
            ping_mac_program <= '0';
            ping_tx_status   <= '0';
            ping_soft_status <= '0';
         elsif (Bus2IP_WrCE = '1' and tx_ping_ctrl_reg_en = '1') then            
            --  Load Control Register with PLB
            --  data if there is a write request
            --  and the control register is enabled
            ping_soft_status <= Bus2IP_Data(0);
--            tx_intr_en       <= Bus2IP_Data(28); -- akzare : Force TX interrupt enable
            ping_mac_program <= Bus2IP_Data(30);
            ping_tx_status   <= Bus2IP_Data(31);
         elsif (OrbCmd_start_tx = '1') then -- akzare            
            ping_tx_status   <= '1'; -- akzare
         -- Clear the status bit when trnasmit complete
         elsif (tx_done_d1 = '1' and tx_pong_ping_l = '0') then   
            ping_tx_status   <= '0';
            ping_mac_program <= '0';
         else -- akzare
            tx_intr_en       <= '1'; -- akzare : Force TX interrupt enable
         end if;
      end if;
   end process TX_PING_CTRL_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- TX_LOOPBACK_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   ----------------------------------------------------------------------------
   TX_LOOPBACK_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            loopback_en      <= '0';
         elsif (Bus2IP_WrCE = '1' and tx_ping_ctrl_reg_en = '1'
                                  and tx_idle='1'               ) then            
            --  Load loopback Register with PLB
            --  data if there is a write request
            --  and the Loopback register is enabled
            loopback_en      <= Bus2IP_Data(27);
         -- Clear the status bit when trnasmit complete
         end if;
      end if;
   end process TX_LOOPBACK_REG_PROCESS;

  Loopback <= loopback_en;

   ----------------------------------------------------------------------------
   -- TX_PING_LENGTH_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the Length register is enabled.
   ----------------------------------------------------------------------------
   TX_PING_LENGTH_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            ping_pkt_lenth <= (others=>'0');
         elsif (Bus2IP_WrCE = '1' and tx_ping_length_reg_en = '1') then            
            --  Load Packet length Register with PLB
            --  data if there is a write request
            --  and the length register is enabled
            ping_pkt_lenth <= Bus2IP_Data(16 to 31);
         elsif (OrbCmd_start_tx = '1') then   -- akzare
            ping_pkt_lenth <= tx_packet_len_SW; -- akzare
         end if;
      end if;
   end process TX_PING_LENGTH_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- GIE_EN_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the GIE register is enabled.
   ----------------------------------------------------------------------------
   GIE_EN_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            gie_enable <= '0';
--         elsif (Bus2IP_WrCE = '1' and gie_reg_en = '1') then -- akzare               
            --  Load Global Interrupt Enable Register with PLB
            --  data if there is a write request
            --  and the length register is enabled
--            gie_enable <= Bus2IP_Data(0);
         else -- akzare : Force interrupt enable              
            gie_enable <= '1'; 
         end if;
      end if;
   end process GIE_EN_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- RX_PING_CTRL_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the Ping control register is enabled.
   ----------------------------------------------------------------------------
   RX_PING_CTRL_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
             rx_intr_en       <= '0';
             ping_rx_status   <= '0';
         elsif (Bus2IP_WrCE = '1' and rx_ping_ctrl_reg_en = '1') then            
            --  Load Control Register with PLB
            --  data if there is a write request
            --  and the control register is enabled
--            rx_intr_en       <= Bus2IP_Data(28); -- akzare : Force interrupt enable
            ping_rx_status   <= Bus2IP_Data(31);
         elsif ( OrbCmd_clr_rx_stats = '1' ) then -- akzare  
            ping_rx_status   <= '0'; -- akzare
         -- Clear the status bit when trnasmit complete
         elsif (rx_done_SW = '1' and rx_pong_ping_l = '0') then  -- akzare rx_done -> rx_done_SW 
            ping_rx_status   <= '1'; -- akzare
         else -- akzare : Force interrupt enable
            rx_intr_en       <= '1'; 
         end if;
      end if;
   end process RX_PING_CTRL_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- REGISTER_READ_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   ----------------------------------------------------------------------------
   REGISTER_READ_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
            reg_data_out   <= (others=>'0');
         elsif (Bus2IP_RdCE = '1' and tx_ping_ctrl_reg_en = '1') then            
         -- TX PING Control Register Read through PLB
            reg_data_out(31)   <= ping_tx_status;
            reg_data_out(30)   <= ping_mac_program;
            reg_data_out(29)   <= '0';
            reg_data_out(28)   <= tx_intr_en;
            reg_data_out(27)   <= loopback_en;
            reg_data_out(0)    <= ping_soft_status; 
            reg_data_out(1 to 26)   <= (others=>'0');
         elsif (Bus2IP_RdCE = '1' and tx_pong_ctrl_reg_en = '1') then            
         -- TX PONG Control Register Read through PLB 
            reg_data_out(31)   <= pong_tx_status;
            reg_data_out(30)   <= pong_mac_program;
            reg_data_out(1 to 29)   <= (others=>'0');
            reg_data_out(0)    <= pong_soft_status;
         elsif (Bus2IP_RdCE = '1' and tx_ping_length_reg_en = '1') then            
         -- TX PING Length Register Read through PLB 
            reg_data_out(0 to 15)   <= (others=>'0');
            reg_data_out(16 to 31)  <= ping_pkt_lenth;
         elsif (Bus2IP_RdCE = '1' and tx_pong_length_reg_en = '1') then            
         -- TX PONG Length Register Read through PLB 
            reg_data_out(0 to 15)   <= (others=>'0');
            reg_data_out(16 to 31)  <= pong_pkt_lenth;
         elsif (Bus2IP_RdCE = '1' and rx_ping_ctrl_reg_en = '1') then            
         -- RX PING Control Register Read through PLB 
            reg_data_out(31)   <= ping_rx_status;
            reg_data_out(30)   <= '0';
            reg_data_out(29)   <= '0';
            reg_data_out(28)   <= rx_intr_en;
            reg_data_out(0 to 27)   <= (others=>'0');
         elsif (Bus2IP_RdCE = '1' and rx_pong_ctrl_reg_en = '1') then            
         -- RX PONG Control Register Read through PLB 
            reg_data_out(31)   <= pong_rx_status;
            reg_data_out(0 to 30)   <= (others=>'0');
         elsif (Bus2IP_RdCE = '1' and gie_reg_en = '1') then               
         -- GIE Register Read through PLB 
            reg_data_out(0)   <= gie_enable;
            reg_data_out(1 to 31)   <= (others=>'0');
         elsif (Bus2IP_RdCE = '1' and stat_reg_en = '1') then               
         -- Common Status Register Read through PLB 
            reg_data_out(31)   <= status_reg(5);
            reg_data_out(30)   <= status_reg(4);
            reg_data_out(29)   <= status_reg(3);
            reg_data_out(28)   <= status_reg(2);
            reg_data_out(27)   <= status_reg(1);
            reg_data_out(26)   <= status_reg(0);
            reg_data_out(0 to 25)   <= (others=>'0');
         else 
            reg_data_out <= (others=>'0');
         end if;
      end if;
   end process REGISTER_READ_PROCESS;

   ----------------------------------------------------------------------------
   -- COMMON_STATUS_REG_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   -- status_reg        : std_logic_vector(0 to 5);
   -- status reg address = 0x07E0
   -- status_reg(5) : Ping TX complete
   -- status_reg(4) : Pong TX complete
   -- status_reg(3) : Ping RX complete
   -- status_reg(2) : Pong RX complete
   -- status_reg(1) : Ping MAC program complete
   -- status_reg(0) : Pong MAC program complete
   -- All Status bit will be cleared after reading this register
   ----------------------------------------------------------------------------
   COMMON_STATUS_REG_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
             status_reg   <= (others=>'0');
         elsif (tx_done = '1') then 
            if (tx_pong_ping_l = '0' and ping_mac_program='0' ) then
               status_reg    <= (others=>'0');
               status_reg(5) <= '1';
            elsif (tx_pong_ping_l = '0' and ping_mac_program='1' ) then    
               status_reg    <= (others=>'0');
               status_reg(1) <= '1';
            elsif (tx_pong_ping_l = '1' and pong_mac_program='0' ) then    
               status_reg    <= (others=>'0');
               status_reg(4) <= '1';
            elsif (tx_pong_ping_l = '1' and pong_mac_program='1' ) then    
               status_reg    <= (others=>'0');
               status_reg(0) <= '1';
            end if;   
         elsif (rx_done_d1 = '1') then
            if (rx_pong_ping_l = '0') then
               status_reg    <= (others=>'0');
               status_reg(3) <= '1';
            else
               status_reg    <= (others=>'0');
               status_reg(2) <= '1';
            end if;   
         end if;
      end if;
   end process COMMON_STATUS_REG_PROCESS;

   ----------------------------------------------------------------------------
   -- TX_LENGTH_MUX_PROCESS
   ----------------------------------------------------------------------------
   -- This process loads data from the PLB when there is a write request and 
   -- the control register is enabled.
   ----------------------------------------------------------------------------
   TX_LENGTH_MUX_PROCESS : process (Bus2IP_Clk)
   begin  -- process
      if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if (Bus2IP_Reset = '1') then 
             tx_packet_length   <= (others=>'0');
         elsif (tx_pong_ping_l = '1') then               
            --  Load Control Register with PLB
            tx_packet_length <= pong_pkt_lenth;
         -- Clear the status bit when trnasmit complete
         else
            tx_packet_length <= ping_pkt_lenth;
         end if;
      end if;
   end process TX_LENGTH_MUX_PROCESS;

   -- Tx Start indicator
   transmit_start <= ((ping_tx_status and not ping_mac_program) or 
                      (pong_tx_status and not pong_mac_program)) and
                       not tx_done_d2;
   
   -- MAC program start indicator
   mac_program_start <= (ping_tx_status and ping_mac_program) or 
                        (pong_tx_status and pong_mac_program);

   ----------------------------------------------------------------------------
   
   ----------------------------------------------------------------------------
   -- MDIO_GEN :- Include MDIO interface if the parameter C_INCLUDE_MDIO = 1
   ----------------------------------------------------------------------------
   MDIO_GEN: if C_INCLUDE_MDIO = 1 generate
   
      signal mdio_addr_en       : std_logic;
      signal mdio_wr_data_en    : std_logic;
      signal mdio_rd_data_en    : std_logic;
      signal mdio_ctrl_en       : std_logic;
      signal mdio_op_i          : std_logic;
      signal mdio_en_i          : std_logic;
      signal mdio_req_i         : std_logic;
      signal mdio_done_i        : std_logic;
      signal mdio_wr_data_reg   : std_logic_vector(15 downto 0);
      signal mdio_rd_data_reg   : std_logic_vector(15 downto 0);
      signal mdio_phy_addr      : std_logic_vector(4 downto 0);
      signal mdio_reg_addr      : std_logic_vector(4 downto 0);
      signal mdio_clk_i         : std_logic;
      signal clk_cnt            : integer range 0 to 63;
   begin
   
      -- MDIO reg enable
      mdio_reg_en     <= (mdio_addr_en    or 
                          mdio_wr_data_en or 
                          mdio_rd_data_en or 
                          mdio_ctrl_en       ) and (not bus2ip_burst);
                          
      -- MDIO address reg enable
      mdio_addr_en    <= reg_en and (not bus2ip_addr(8))
                                and (not bus2ip_addr(9))
                                and (    bus2ip_addr(10));
   
      -- MDIO write data reg enable
      mdio_wr_data_en <= reg_en and (not bus2ip_addr(8))
                                and (    bus2ip_addr(9))
                                and (not bus2ip_addr(10));
   
      -- MDIO read data reg enable
      mdio_rd_data_en <= reg_en and (not bus2ip_addr(8))
                                and (    bus2ip_addr(9))
                                and (    bus2ip_addr(10));
   
      -- MDIO controlreg enable
      mdio_ctrl_en    <= reg_en and (    bus2ip_addr(8))
                                and (not bus2ip_addr(9))
                                and (not bus2ip_addr(10));                             
   
   
      -------------------------------------------------------------------------
      -- MDIO_CTRL_REG_WR_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request and
      -- the MDIO control register is enabled.
      -------------------------------------------------------------------------
      MDIO_CTRL_REG_WR_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               mdio_en_i    <= '0';
               mdio_req_i   <= '0';
            elsif (Bus2IP_WrCE = '1' and mdio_ctrl_en= '1') then               
               --  Load MDIO Control Register with PLB
               --  data if there is a write request
               --  and the control register is enabled
               mdio_en_i    <= Bus2IP_Data(28);
               mdio_req_i   <= Bus2IP_Data(31);
            -- Clear the status bit when trnasmit complete
            elsif mdio_done_i = '1' then   
               mdio_req_i   <=  '0';
            end if;
         end if;
      end process MDIO_CTRL_REG_WR_PROCESS;
   
      -------------------------------------------------------------------------
      -- MDIO_ADDR_REG_WR_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request and
      -- the MDIO Address register is enabled.
      -------------------------------------------------------------------------
      MDIO_ADDR_REG_WR_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               mdio_phy_addr <= (others =>'0');
               mdio_reg_addr <= (others =>'0');
               mdio_op_i     <= '0'; 
            elsif (Bus2IP_WrCE = '1' and mdio_addr_en= '1') then               
               --  Load MDIO ADDR Register with PLB
               --  data if there is a write request
               --  and the Address register is enabled
               mdio_phy_addr <= Bus2IP_Data(22 to 26);
               mdio_reg_addr <= Bus2IP_Data(27 to 31);
               mdio_op_i     <= Bus2IP_Data(21);
               
            end if;
         end if;
      end process MDIO_ADDR_REG_WR_PROCESS;
   
      -------------------------------------------------------------------------
      -- MDIO_WRITE_REG_WR_PROCESS
      -------------------------------------------------------------------------
      -- This process loads data from the PLB when there is a write request  
      -- and the MDIO Write register is enabled.
      -------------------------------------------------------------------------
      MDIO_WRITE_REG_WR_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               mdio_wr_data_reg <= (others =>'0');
            elsif (Bus2IP_WrCE = '1' and mdio_wr_data_en= '1') then            
               --  Load MDIO Write Data Register with PLB
               --  data if there is a write request
               --  and the Write Data register is enabled
               mdio_wr_data_reg <= Bus2IP_Data(16 to 31);
               
            end if;
         end if;
      end process MDIO_WRITE_REG_WR_PROCESS;
      
      -------------------------------------------------------------------------
      -- MDIO_REG_RD_PROCESS
      -------------------------------------------------------------------------
      -- This process allows MDIO register read from the PLB when there is a
      -- read request and the MDIO registers are enabled.
      -------------------------------------------------------------------------
      MDIO_REG_RD_PROCESS : process (Bus2IP_Clk)
      begin  -- process
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then 
               mdio_data_out <= (others =>'0');
            elsif (Bus2IP_RdCE = '1' and mdio_addr_en= '1') then               
               --  MDIO Address Register Read through PLB
               mdio_data_out(27 to 31) <= mdio_reg_addr;
               mdio_data_out(22 to 26) <= mdio_phy_addr;
               mdio_data_out(21)       <= mdio_op_i;
               mdio_data_out(0  to 20) <= (others=>'0');
            elsif (Bus2IP_RdCE = '1' and mdio_wr_data_en= '1') then               
               --  MDIO Write Data Register Read through PLB
               mdio_data_out(16 to 31) <= mdio_wr_data_reg;
               mdio_data_out(0  to 15) <= (others=>'0');
            elsif (Bus2IP_RdCE = '1' and mdio_rd_data_en= '1') then               
               --  MDIO Read Data Register Read through PLB
               mdio_data_out(16 to 31) <= mdio_rd_data_reg;
               mdio_data_out(0  to 15) <= (others=>'0');
            elsif (Bus2IP_RdCE = '1' and mdio_ctrl_en= '1') then               
               --  MDIO Control Register Read through PLB
               mdio_data_out(31) <= mdio_req_i;
               mdio_data_out(30) <= '0';
               mdio_data_out(29) <= '0';
               mdio_data_out(28) <= mdio_en_i;
               mdio_data_out(0  to 27) <= (others=>'0');
            else
               mdio_data_out <= (others =>'0');
            end if;
         end if;
      end process MDIO_REG_RD_PROCESS;
   
      -------------------------------------------------------------------------
      -- PROCESS : MDIO_CLK_COUNTER 
      -------------------------------------------------------------------------
      -- Generating MDIO clock. The minimum period for MDC clock is 400 ns. 
      -------------------------------------------------------------------------
      MDIO_CLK_COUNTER : process(Bus2IP_Clk)
      begin
         if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1' ) then
               clk_cnt  <= MDIO_CNT;
               mdio_clk_i <= '0';
            elsif (clk_cnt = 0) then
               clk_cnt    <= MDIO_CNT;
               mdio_clk_i <= not mdio_clk_i;
            else 
               clk_cnt <= clk_cnt - 1;
            end if;
         end if;
      end process;
   
      -------------------------------------------------------------------------
      -- MDIO master interface module
      -------------------------------------------------------------------------
      MDIO_IF_I: entity hardorb_fpga_v3_01_a.mdio_if
         port map (             
            Clk            => Bus2IP_Clk       , 
            Rst            => Bus2IP_Reset     ,
            MDIO_CLK       => mdio_clk_i       ,
            MDIO_en        => mdio_en_i        ,
            MDIO_OP        => mdio_op_i        ,
            MDIO_Req       => mdio_req_i       ,
            MDIO_PHY_AD    => mdio_phy_addr    ,      
            MDIO_REG_AD    => mdio_reg_addr    ,
            MDIO_WR_DATA   => mdio_wr_data_reg ,
            MDIO_RD_DATA   => mdio_rd_data_reg ,
            PHY_MDIO_I     => PHY_MDIO_I       ,
            PHY_MDIO_O     => PHY_MDIO_O       ,
            PHY_MDIO_T     => PHY_MDIO_T       ,
            PHY_MDC        => PHY_MDC          ,
            MDIO_done      => mdio_done_i
            );          
      
   
   end generate MDIO_GEN; 
   
   ----------------------------------------------------------------------------
   -- NO_MDIO_GEN :- Include MDIO interface if the parameter C_INCLUDE_MDIO = 0
   ----------------------------------------------------------------------------
   NO_MDIO_GEN: if C_INCLUDE_MDIO = 0 generate
   begin 
      
      mdio_data_out <= (others=>'0');
      mdio_reg_en   <= '0';
      PHY_MDIO_O    <= '0';
      PHY_MDIO_T    <= '1';

   end generate NO_MDIO_GEN; 

end imp;



