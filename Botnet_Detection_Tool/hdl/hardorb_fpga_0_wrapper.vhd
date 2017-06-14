-------------------------------------------------------------------------------
-- hardorb_fpga_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library hardorb_fpga_v3_01_a;
use hardorb_fpga_v3_01_a.all;

entity hardorb_fpga_0_wrapper is
  port (
    DEBUG_D_I : in std_logic_vector(35 downto 0);
    DEBUG_D_O : out std_logic_vector(35 downto 0);
    DEBUG_D_T : out std_logic_vector(35 downto 0);
    trig_sig : out std_logic_vector(0 to 0);
    NPI_Clk : in std_logic;
    NPI_RST : in std_logic;
    NPI_Addr : out std_logic_vector(31 downto 0);
    NPI_AddrReq : out std_logic;
    NPI_AddrAck : in std_logic;
    NPI_RNW : out std_logic;
    NPI_Size : out std_logic_vector(3 downto 0);
    NPI_RdModWr : out std_logic;
    NPI_WrFIFO_Data : out std_logic_vector(31 downto 0);
    NPI_WrFIFO_BE : out std_logic_vector(3 downto 0);
    NPI_WrFIFO_Push : out std_logic;
    NPI_RdFIFO_Data : in std_logic_vector(31 downto 0);
    NPI_RdFIFO_Pop : out std_logic;
    NPI_RdFIFO_RdWdAddr : in std_logic_vector(3 downto 0);
    NPI_WrFIFO_Empty : in std_logic;
    NPI_WrFIFO_AlmostFull : in std_logic;
    NPI_WrFIFO_Flush : out std_logic;
    NPI_RdFIFO_Empty : in std_logic;
    NPI_RdFIFO_Flush : out std_logic;
    NPI_RdFIFO_Latency : in std_logic_vector(1 downto 0);
    NPI_InitDone : in std_logic;
    VFBC2_cmd_clk : out std_logic;
    VFBC2_cmd_reset : out std_logic;
    VFBC2_cmd_data : out std_logic_vector(31 downto 0);
    VFBC2_cmd_write : out std_logic;
    VFBC2_cmd_end : out std_logic;
    VFBC2_cmd_almost_full : in std_logic;
    VFBC2_cmd_full : in std_logic;
    VFBC2_cmd_idle : in std_logic;
    VFBC2_wd_clk : out std_logic;
    VFBC2_wd_reset : out std_logic;
    VFBC2_wd_write : out std_logic;
    VFBC2_wd_end_burst : out std_logic;
    VFBC2_wd_flush : out std_logic;
    VFBC2_wd_data : out std_logic_vector(31 downto 0);
    VFBC2_wd_data_be : out std_logic_vector(3 downto 0);
    VFBC2_wd_almost_full : in std_logic;
    VFBC2_wd_full : in std_logic;
    VFBC2_rd_clk : out std_logic;
    VFBC2_rd_reset : out std_logic;
    VFBC2_rd_read : out std_logic;
    VFBC2_rd_end_burst : out std_logic;
    VFBC2_rd_flush : out std_logic;
    VFBC2_rd_data : in std_logic_vector(31 downto 0);
    VFBC2_rd_empty : in std_logic;
    VFBC2_rd_almost_empty : in std_logic;
    EXT_TRIG_D_I : in std_logic_vector(3 downto 0);
    EXT_TRIG_D_O : out std_logic_vector(3 downto 0);
    EXT_TRIG_D_T : out std_logic_vector(3 downto 0);
    PHY_tx_clk : in std_logic;
    PHY_rx_clk : in std_logic;
    PHY_crs : in std_logic;
    PHY_dv : in std_logic;
    PHY_rx_data : in std_logic_vector(3 downto 0);
    PHY_col : in std_logic;
    PHY_rx_er : in std_logic;
    PHY_rst_n : out std_logic;
    PHY_tx_en : out std_logic;
    PHY_tx_data : out std_logic_vector(3 downto 0);
    PHY_MDC : out std_logic;
    PHY_MDIO_I : in std_logic;
    PHY_MDIO_O : out std_logic;
    PHY_MDIO_T : out std_logic;
    IP2INTC_Irpt : out std_logic;
    SPLB_Clk : in std_logic;
    SPLB_Rst : in std_logic;
    PLB_ABus : in std_logic_vector(0 to 31);
    PLB_UABus : in std_logic_vector(0 to 31);
    PLB_PAValid : in std_logic;
    PLB_SAValid : in std_logic;
    PLB_rdPrim : in std_logic;
    PLB_wrPrim : in std_logic;
    PLB_masterID : in std_logic_vector(0 to 0);
    PLB_abort : in std_logic;
    PLB_busLock : in std_logic;
    PLB_RNW : in std_logic;
    PLB_BE : in std_logic_vector(0 to 15);
    PLB_MSize : in std_logic_vector(0 to 1);
    PLB_size : in std_logic_vector(0 to 3);
    PLB_type : in std_logic_vector(0 to 2);
    PLB_lockErr : in std_logic;
    PLB_wrDBus : in std_logic_vector(0 to 127);
    PLB_wrBurst : in std_logic;
    PLB_rdBurst : in std_logic;
    PLB_wrPendReq : in std_logic;
    PLB_rdPendReq : in std_logic;
    PLB_wrPendPri : in std_logic_vector(0 to 1);
    PLB_rdPendPri : in std_logic_vector(0 to 1);
    PLB_reqPri : in std_logic_vector(0 to 1);
    PLB_TAttribute : in std_logic_vector(0 to 15);
    Sl_addrAck : out std_logic;
    Sl_SSize : out std_logic_vector(0 to 1);
    Sl_wait : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck : out std_logic;
    Sl_wrComp : out std_logic;
    Sl_wrBTerm : out std_logic;
    Sl_rdDBus : out std_logic_vector(0 to 127);
    Sl_rdWdAddr : out std_logic_vector(0 to 3);
    Sl_rdDAck : out std_logic;
    Sl_rdComp : out std_logic;
    Sl_rdBTerm : out std_logic;
    Sl_MBusy : out std_logic_vector(0 to 0);
    Sl_MWrErr : out std_logic_vector(0 to 0);
    Sl_MRdErr : out std_logic_vector(0 to 0);
    Sl_MIRQ : out std_logic_vector(0 to 0);
    leds_GPIO_IO : out std_logic_vector(7 downto 0)
  );
end hardorb_fpga_0_wrapper;

architecture STRUCTURE of hardorb_fpga_0_wrapper is

  component hardorb_fpga is
    generic (
      C_RECOMPILE : INTEGER;
      C_DEBUG_DWIDTH : INTEGER;
      C_DEBUG_MODE : INTEGER;
      C_NUM_TRIG_SIGNALS : INTEGER;
      C_ICMP_MODE : INTEGER;
      C_TCP_OPERATION_MODE : INTEGER;
      C_DEST_IP : std_logic_vector;
      C_SRC_TCPCLNT_PORT : std_logic_vector;
      C_DEST_TCPCLNT_PORT : std_logic_vector;
      C_NODE_IP : std_logic_vector;
      C_NODE_MAC : std_logic_vector;
      C_NODE_TCPPORT : std_logic_vector;
      C_NODE_TCPPAYLOAD : std_logic_vector;
      C_NPI_BURST_SIZE : integer;
      C_NPI_ADDR_WIDTH : INTEGER;
      C_NPI_DATA_WIDTH : integer;
      C_NPI_BE_WIDTH : integer;
      C_NPI_RDWDADDR_WIDTH : integer;
      C_FAMILY : STRING;
      C_BASEADDR : std_logic_vector;
      C_HIGHADDR : std_logic_vector;
      C_SPLB_CLK_PERIOD_PS : INTEGER;
      C_SPLB_AWIDTH : INTEGER;
      C_SPLB_DWIDTH : INTEGER;
      C_SPLB_P2P : INTEGER;
      C_SPLB_MID_WIDTH : INTEGER;
      C_SPLB_NUM_MASTERS : INTEGER;
      C_SPLB_NATIVE_DWIDTH : INTEGER;
      C_SPLB_SMALLEST_MASTER : INTEGER;
      C_SPLB_SUPPORT_BURSTS : INTEGER;
      C_INCLUDE_MDIO : INTEGER;
      C_INCLUDE_INTERNAL_LOOPBACK : INTEGER;
      C_DUPLEX : INTEGER;
      C_TX_PING_PONG : INTEGER;
      C_RX_PING_PONG : INTEGER
    );
    port (
      DEBUG_D_I : in std_logic_vector(C_DEBUG_DWIDTH-1 downto 0);
      DEBUG_D_O : out std_logic_vector(C_DEBUG_DWIDTH-1 downto 0);
      DEBUG_D_T : out std_logic_vector(C_DEBUG_DWIDTH-1 downto 0);
      trig_sig : out std_logic_vector((C_NUM_TRIG_SIGNALS-1) to 0);
      NPI_Clk : in std_logic;
      NPI_RST : in std_logic;
      NPI_Addr : out std_logic_vector(31 downto 0);
      NPI_AddrReq : out std_logic;
      NPI_AddrAck : in std_logic;
      NPI_RNW : out std_logic;
      NPI_Size : out std_logic_vector(3 downto 0);
      NPI_RdModWr : out std_logic;
      NPI_WrFIFO_Data : out std_logic_vector((C_NPI_DATA_WIDTH-1) downto 0);
      NPI_WrFIFO_BE : out std_logic_vector((C_NPI_DATA_WIDTH/8-1) downto 0);
      NPI_WrFIFO_Push : out std_logic;
      NPI_RdFIFO_Data : in std_logic_vector((C_NPI_DATA_WIDTH-1) downto 0);
      NPI_RdFIFO_Pop : out std_logic;
      NPI_RdFIFO_RdWdAddr : in std_logic_vector(3 downto 0);
      NPI_WrFIFO_Empty : in std_logic;
      NPI_WrFIFO_AlmostFull : in std_logic;
      NPI_WrFIFO_Flush : out std_logic;
      NPI_RdFIFO_Empty : in std_logic;
      NPI_RdFIFO_Flush : out std_logic;
      NPI_RdFIFO_Latency : in std_logic_vector(1 downto 0);
      NPI_InitDone : in std_logic;
      VFBC2_cmd_clk : out std_logic;
      VFBC2_cmd_reset : out std_logic;
      VFBC2_cmd_data : out std_logic_vector(31 downto 0);
      VFBC2_cmd_write : out std_logic;
      VFBC2_cmd_end : out std_logic;
      VFBC2_cmd_almost_full : in std_logic;
      VFBC2_cmd_full : in std_logic;
      VFBC2_cmd_idle : in std_logic;
      VFBC2_wd_clk : out std_logic;
      VFBC2_wd_reset : out std_logic;
      VFBC2_wd_write : out std_logic;
      VFBC2_wd_end_burst : out std_logic;
      VFBC2_wd_flush : out std_logic;
      VFBC2_wd_data : out std_logic_vector(31 downto 0);
      VFBC2_wd_data_be : out std_logic_vector(3 downto 0);
      VFBC2_wd_almost_full : in std_logic;
      VFBC2_wd_full : in std_logic;
      VFBC2_rd_clk : out std_logic;
      VFBC2_rd_reset : out std_logic;
      VFBC2_rd_read : out std_logic;
      VFBC2_rd_end_burst : out std_logic;
      VFBC2_rd_flush : out std_logic;
      VFBC2_rd_data : in std_logic_vector(31 downto 0);
      VFBC2_rd_empty : in std_logic;
      VFBC2_rd_almost_empty : in std_logic;
      EXT_TRIG_D_I : in std_logic_vector(3 downto 0);
      EXT_TRIG_D_O : out std_logic_vector(3 downto 0);
      EXT_TRIG_D_T : out std_logic_vector(3 downto 0);
      PHY_tx_clk : in std_logic;
      PHY_rx_clk : in std_logic;
      PHY_crs : in std_logic;
      PHY_dv : in std_logic;
      PHY_rx_data : in std_logic_vector(3 downto 0);
      PHY_col : in std_logic;
      PHY_rx_er : in std_logic;
      PHY_rst_n : out std_logic;
      PHY_tx_en : out std_logic;
      PHY_tx_data : out std_logic_vector(3 downto 0);
      PHY_MDC : out std_logic;
      PHY_MDIO_I : in std_logic;
      PHY_MDIO_O : out std_logic;
      PHY_MDIO_T : out std_logic;
      IP2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to (C_SPLB_AWIDTH-1));
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to (C_SPLB_MID_WIDTH-1));
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to ((C_SPLB_DWIDTH/8)-1));
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MWrErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MRdErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MIRQ : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      leds_GPIO_IO : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  hardorb_fpga_0 : hardorb_fpga
    generic map (
      C_RECOMPILE => 1,
      C_DEBUG_DWIDTH => 36,
      C_DEBUG_MODE => 0,
      C_NUM_TRIG_SIGNALS => 1,
      C_ICMP_MODE => 1,
      C_TCP_OPERATION_MODE => 1,
      C_DEST_IP => X"C0A80102",
      C_SRC_TCPCLNT_PORT => X"DFCC",
      C_DEST_TCPCLNT_PORT => X"E28C",
      C_NODE_IP => X"C0A8010A",
      C_NODE_MAC => X"000A3501CB9E",
      C_NODE_TCPPORT => X"99E4",
      C_NODE_TCPPAYLOAD => X"0580",
      C_NPI_BURST_SIZE => 128,
      C_NPI_ADDR_WIDTH => 32,
      C_NPI_DATA_WIDTH => 32,
      C_NPI_BE_WIDTH => 4,
      C_NPI_RDWDADDR_WIDTH => 4,
      C_FAMILY => "virtex5",
      C_BASEADDR => X"c2800000",
      C_HIGHADDR => X"c280ffff",
      C_SPLB_CLK_PERIOD_PS => 13333,
      C_SPLB_AWIDTH => 32,
      C_SPLB_DWIDTH => 128,
      C_SPLB_P2P => 0,
      C_SPLB_MID_WIDTH => 1,
      C_SPLB_NUM_MASTERS => 1,
      C_SPLB_NATIVE_DWIDTH => 32,
      C_SPLB_SMALLEST_MASTER => 128,
      C_SPLB_SUPPORT_BURSTS => 1,
      C_INCLUDE_MDIO => 1,
      C_INCLUDE_INTERNAL_LOOPBACK => 0,
      C_DUPLEX => 1,
      C_TX_PING_PONG => 0,
      C_RX_PING_PONG => 0
    )
    port map (
      DEBUG_D_I => DEBUG_D_I,
      DEBUG_D_O => DEBUG_D_O,
      DEBUG_D_T => DEBUG_D_T,
      trig_sig => trig_sig,
      NPI_Clk => NPI_Clk,
      NPI_RST => NPI_RST,
      NPI_Addr => NPI_Addr,
      NPI_AddrReq => NPI_AddrReq,
      NPI_AddrAck => NPI_AddrAck,
      NPI_RNW => NPI_RNW,
      NPI_Size => NPI_Size,
      NPI_RdModWr => NPI_RdModWr,
      NPI_WrFIFO_Data => NPI_WrFIFO_Data,
      NPI_WrFIFO_BE => NPI_WrFIFO_BE,
      NPI_WrFIFO_Push => NPI_WrFIFO_Push,
      NPI_RdFIFO_Data => NPI_RdFIFO_Data,
      NPI_RdFIFO_Pop => NPI_RdFIFO_Pop,
      NPI_RdFIFO_RdWdAddr => NPI_RdFIFO_RdWdAddr,
      NPI_WrFIFO_Empty => NPI_WrFIFO_Empty,
      NPI_WrFIFO_AlmostFull => NPI_WrFIFO_AlmostFull,
      NPI_WrFIFO_Flush => NPI_WrFIFO_Flush,
      NPI_RdFIFO_Empty => NPI_RdFIFO_Empty,
      NPI_RdFIFO_Flush => NPI_RdFIFO_Flush,
      NPI_RdFIFO_Latency => NPI_RdFIFO_Latency,
      NPI_InitDone => NPI_InitDone,
      VFBC2_cmd_clk => VFBC2_cmd_clk,
      VFBC2_cmd_reset => VFBC2_cmd_reset,
      VFBC2_cmd_data => VFBC2_cmd_data,
      VFBC2_cmd_write => VFBC2_cmd_write,
      VFBC2_cmd_end => VFBC2_cmd_end,
      VFBC2_cmd_almost_full => VFBC2_cmd_almost_full,
      VFBC2_cmd_full => VFBC2_cmd_full,
      VFBC2_cmd_idle => VFBC2_cmd_idle,
      VFBC2_wd_clk => VFBC2_wd_clk,
      VFBC2_wd_reset => VFBC2_wd_reset,
      VFBC2_wd_write => VFBC2_wd_write,
      VFBC2_wd_end_burst => VFBC2_wd_end_burst,
      VFBC2_wd_flush => VFBC2_wd_flush,
      VFBC2_wd_data => VFBC2_wd_data,
      VFBC2_wd_data_be => VFBC2_wd_data_be,
      VFBC2_wd_almost_full => VFBC2_wd_almost_full,
      VFBC2_wd_full => VFBC2_wd_full,
      VFBC2_rd_clk => VFBC2_rd_clk,
      VFBC2_rd_reset => VFBC2_rd_reset,
      VFBC2_rd_read => VFBC2_rd_read,
      VFBC2_rd_end_burst => VFBC2_rd_end_burst,
      VFBC2_rd_flush => VFBC2_rd_flush,
      VFBC2_rd_data => VFBC2_rd_data,
      VFBC2_rd_empty => VFBC2_rd_empty,
      VFBC2_rd_almost_empty => VFBC2_rd_almost_empty,
      EXT_TRIG_D_I => EXT_TRIG_D_I,
      EXT_TRIG_D_O => EXT_TRIG_D_O,
      EXT_TRIG_D_T => EXT_TRIG_D_T,
      PHY_tx_clk => PHY_tx_clk,
      PHY_rx_clk => PHY_rx_clk,
      PHY_crs => PHY_crs,
      PHY_dv => PHY_dv,
      PHY_rx_data => PHY_rx_data,
      PHY_col => PHY_col,
      PHY_rx_er => PHY_rx_er,
      PHY_rst_n => PHY_rst_n,
      PHY_tx_en => PHY_tx_en,
      PHY_tx_data => PHY_tx_data,
      PHY_MDC => PHY_MDC,
      PHY_MDIO_I => PHY_MDIO_I,
      PHY_MDIO_O => PHY_MDIO_O,
      PHY_MDIO_T => PHY_MDIO_T,
      IP2INTC_Irpt => IP2INTC_Irpt,
      SPLB_Clk => SPLB_Clk,
      SPLB_Rst => SPLB_Rst,
      PLB_ABus => PLB_ABus,
      PLB_UABus => PLB_UABus,
      PLB_PAValid => PLB_PAValid,
      PLB_SAValid => PLB_SAValid,
      PLB_rdPrim => PLB_rdPrim,
      PLB_wrPrim => PLB_wrPrim,
      PLB_masterID => PLB_masterID,
      PLB_abort => PLB_abort,
      PLB_busLock => PLB_busLock,
      PLB_RNW => PLB_RNW,
      PLB_BE => PLB_BE,
      PLB_MSize => PLB_MSize,
      PLB_size => PLB_size,
      PLB_type => PLB_type,
      PLB_lockErr => PLB_lockErr,
      PLB_wrDBus => PLB_wrDBus,
      PLB_wrBurst => PLB_wrBurst,
      PLB_rdBurst => PLB_rdBurst,
      PLB_wrPendReq => PLB_wrPendReq,
      PLB_rdPendReq => PLB_rdPendReq,
      PLB_wrPendPri => PLB_wrPendPri,
      PLB_rdPendPri => PLB_rdPendPri,
      PLB_reqPri => PLB_reqPri,
      PLB_TAttribute => PLB_TAttribute,
      Sl_addrAck => Sl_addrAck,
      Sl_SSize => Sl_SSize,
      Sl_wait => Sl_wait,
      Sl_rearbitrate => Sl_rearbitrate,
      Sl_wrDAck => Sl_wrDAck,
      Sl_wrComp => Sl_wrComp,
      Sl_wrBTerm => Sl_wrBTerm,
      Sl_rdDBus => Sl_rdDBus,
      Sl_rdWdAddr => Sl_rdWdAddr,
      Sl_rdDAck => Sl_rdDAck,
      Sl_rdComp => Sl_rdComp,
      Sl_rdBTerm => Sl_rdBTerm,
      Sl_MBusy => Sl_MBusy,
      Sl_MWrErr => Sl_MWrErr,
      Sl_MRdErr => Sl_MRdErr,
      Sl_MIRQ => Sl_MIRQ,
      leds_GPIO_IO => leds_GPIO_IO
    );

end architecture STRUCTURE;

