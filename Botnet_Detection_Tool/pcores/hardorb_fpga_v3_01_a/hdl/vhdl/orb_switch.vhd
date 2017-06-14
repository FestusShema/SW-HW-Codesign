-------------------------------------------------------------------------------
-- orb_switch.vhd
--
-- Author(s):     Ali Akbar Zarezadeh (akzare)
-- (University of Potsdam, Computer Science Department)
-- HardORB FPGA project (PICSY project)
-- Created:       Dec 2009
-- Last Modified: June 2013 (Adil)
-- 
-- Hard ORB implementation inside the FPGA
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library hardorb_fpga_v3_01_a;
use hardorb_fpga_v3_01_a.all;
--use work.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
-------------------------------------------------------------------------------
--  NODE_MAC               -- EMACLite MAC address
-------------------------------------------------------------------------------
-- Definition of Ports:
--
--  Clk                    -- System Clock
--  Rst                    -- System Reset

entity orb_switch is
  generic (
    C_FAMILY            : string := "virtex5";

    C_DEBUG_MODE        : integer := 0;	-- 0 = disable, 1 = enable
    C_ICMP_MODE         : integer := 1;	-- 0 = disable, 1 = enable
    DEST_IP             : STD_LOGIC_VECTOR (31 downto 0) := x"c0a80102";
    DEST_TCPCLNT_PORT   : STD_LOGIC_VECTOR (15 downto 0) := x"BC14";
    SRC_TCPCLNT_PORT    : STD_LOGIC_VECTOR (15 downto 0) := x"DFCC"; -- Source TCP Client Port
    DEVICE_IP           : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a";
    C_TCP_OPERATION_MODE : integer := 0;	-- 0 = NoTCP, 1 = TCP_Server, 2 = TCP_Client, 3 = TCP_Server_Client
    DEVICE_MAC          : STD_LOGIC_VECTOR (47 downto 0) := x"000A3501CB9E";
    DEVICE_TCP_PORT     : STD_LOGIC_VECTOR (15 downto 0) := x"BC14";
    DEVICE_TCP_PAYLOAD  : STD_LOGIC_VECTOR (15 downto 0) := x"0400"; -- 1024-byte payload

    C_RD_MEMBLK_ADDR    : std_logic_vector := x"00000000";
    C_WR_MEMBLK_ADDR    : std_logic_vector := x"07600000";

    C_TOTAL_BYTE_NUM     : integer := 128;
--    C_TOTAL_BYTE_NUM     : integer := 256;
--    C_TOTAL_BYTE_NUM     : integer := 512;
--    C_TOTAL_BYTE_NUM     : integer := 1000;
--    C_TOTAL_BYTE_NUM     : integer := 1024;
--    C_TOTAL_BYTE_NUM     : integer := 1408;

    C_NPI_BURST_SIZE     : integer := 256; -- Burst size in BYTEs
    C_NPI_ADDR_WIDTH     : integer := 32;
    C_NPI_DATA_WIDTH     : integer := 64;
    C_NPI_BE_WIDTH       : integer := 8;
    C_NPI_RDWDADDR_WIDTH : integer := 4;
    C_FIFO_DEPTH         : integer := 4096 -- Fifo depth in BYTEs
    );                
  port (              
    tst_user_dreq         : in     std_logic;

    NPI_Clk               : in     std_logic;
    NPI_RST               : in     std_logic;
    NPI_Addr              : out    std_logic_vector(C_NPI_ADDR_WIDTH - 1 downto 0);
    NPI_AddrReq           : out    std_logic;
    NPI_AddrAck           : in     std_logic;
    NPI_RNW               : out    std_logic;
    NPI_Size              : out    std_logic_vector(3 downto 0);
    NPI_WrFIFO_Data       : out    std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
    NPI_WrFIFO_BE         : out    std_logic_vector(C_NPI_BE_WIDTH - 1 downto 0);
    NPI_WrFIFO_Push       : out    std_logic;
    NPI_RdFIFO_Data       : in     std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
    NPI_RdFIFO_Pop        : out    std_logic;
    NPI_RdFIFO_RdWdAddr   : in     std_logic_vector(C_NPI_RDWDADDR_WIDTH - 1 downto 0);
    NPI_WrFIFO_Empty      : in     std_logic;
    NPI_WrFIFO_AlmostFull : in     std_logic;
    NPI_WrFIFO_Flush      : out    std_logic;
    NPI_RdFIFO_Empty      : in     std_logic;
    NPI_RdFIFO_Flush      : out    std_logic;
    NPI_RdFIFO_Latency    : in     std_logic_vector(1 downto 0);
    NPI_RdModWr           : out    std_logic;
    NPI_InitDone          : in     std_logic;
	 
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

    TCP_StrtClnt          : in std_logic;

    Clk                 : in std_logic;
    Rst                 : in std_logic;
	 PHY_rx_clk				: in std_logic;
	 
	 GPIO_IO					: out std_logic_vector (7 downto 0);

    transmit_start      : in std_logic;
    tx_done_MAC         : in std_logic;
    
    tx_DPM_adr_MAC      : in std_logic_vector (0 to 11);
    tx_ping_rd_data_MAC : in std_logic_vector (0 to 3);

    OrbCmd_start_tx     : out std_logic;
    tx_done_SW          : out std_logic;

    tx_ping_rd_data_SW  : out std_logic_vector (0 to 3);
    tx_packet_len_SW    : out std_logic_vector (0 to 15);


    rx_ping_ce          : in std_logic;
    rx_DPM_wr_rd_n      : in std_logic;
    rx_DPM_adr          : in std_logic_vector (0 to 11);
    rx_DPM_wr_data      : in std_logic_vector (0 to 3);

    rx_done             : in std_logic;

------------------------ TEST -------------------    
tst_macnewFrameByte  : out std_logic; 
tst_macframeData     : out std_logic_vector (0 to 7); 

tst_tcphndl_wrRAM : out std_logic;
tst_tcphndl_wrData : out std_logic_vector (0 to 7); 

tst_tcpcmpltRec: out STD_LOGIC;
tst_tcpnewByteRec: out STD_LOGIC;
tst_tcpinByteRec: out STD_LOGIC_VECTOR (7 downto 0);
tst_tcpbusyXmit: out STD_LOGIC;
tst_tcpsendTCP: out STD_LOGIC;

tst_ipnewFrame: out STD_LOGIC;
tst_ipframeType: out STD_LOGIC;
tst_ipcnt: out STD_LOGIC_VECTOR (5 downto 0);
tst_ipinByte: out STD_LOGIC_VECTOR (7 downto 0);
tst_ipnewByte: out STD_LOGIC;
tst_ipnewDatagram: out STD_LOGIC;
tst_ippresstate: out STD_LOGIC_VECTOR (3 downto 0);

tst_tcppresstateRec: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcppresstateXmit: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcppresstateSrv: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcprx_done: out STD_LOGIC;

tst_arprecpresstate: out STD_LOGIC_VECTOR (1 downto 0);
tst_arprecnewFrame: out STD_LOGIC;
tst_arprecframeType: out STD_LOGIC;

tst_arpxmitpresstate: out STD_LOGIC_VECTOR (3 downto 0);

tst_macxmit_start: out STD_LOGIC;
tst_arpxmit_genFrame: out STD_LOGIC;

tst_DMA_DREQ: out STD_LOGIC;
tst_DMA_DACK: out STD_LOGIC;
tst_DMA_INIT: out STD_LOGIC;
tst_DMA_DATA: out STD_LOGIC_VECTOR (31 downto 0);

tst_burst_cnt_one: out STD_LOGIC;
tst_burst_cnt: out STD_LOGIC_VECTOR (5 downto 0);

tst_user_read : out STD_LOGIC;
tst_user_drdy : out STD_LOGIC;
tst_fifo_data_out : out std_logic_vector(7 downto 0);

tst_fifo_wr_count : out std_logic_vector(10 downto 0);
tst_fifowr_rd_count : out std_logic_vector(10 downto 0);
tst_fifo_wr_en: out STD_LOGIC;

tst_tcp_RcvOvrHd_TrigSg: out STD_LOGIC;
------------------------ TEST -------------------    
    triger_signal       : out std_logic;

    OrbCmd_clr_rx_stats : out std_logic;
    rx_done_SW          : out std_logic
    );
end orb_switch;

architecture Behavioral of orb_switch is
-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
  signal transmit_start_prev: std_logic;
  signal rec_hard_orb_en : std_logic;
  signal hrd_orb_wr_xbuf_en : std_logic;

  signal tx_DPM_wr_ORB : std_logic_vector(0 to 0);
  signal tx_DPM_adr_ORB : std_logic_vector (0 to 10);
  signal tx_DPM_wr_data_ORB : std_logic_vector (0 to 7);
  signal tx_ping_rd_data_ORB : std_logic_vector (0 to 3);
  -- separate buufer for ARP protocol to protect original message
  signal tx_DPM_wr_ARP : std_logic_vector(0 to 0);
  signal tx_DPM_adr_ARP : std_logic_vector (0 to 10);
  signal tx_DPM_wr_data_ARP : std_logic_vector (0 to 7);
  signal tx_ping_rd_data_ARP : std_logic_vector (0 to 3);
  signal arp_en : std_logic;

  signal rx_DPM_wr_data_byte : std_logic_vector (0 to 7);
  signal rx_DPM_wr_data_byte_d0 : std_logic_vector (0 to 7);
  signal rx_DPM_wr_data_byte_d1 : std_logic_vector (0 to 7);
  signal rx_DPM_wr_data_new_byte : std_logic;
  signal rx_DPM_wr_data_new_byte_toggle : std_logic;
  signal rx_DPM_wr_data_new_byte_d1 : std_logic;

-- filter
  signal filter_ip : std_logic; -- Adil
  signal filter_tcp : std_logic; -- Adil
  signal filter_protocol_in : std_logic_vector (7 downto 0); --Adil
  signal filter_src_ip_in : std_logic_vector (31 downto 0); --Adil
  signal filter_dst_ip_in : std_logic_vector (31 downto 0); --Adil
  signal filter_src_port_in : std_logic_vector (15 downto 0); --Adil
  signal filter_dst_port_in : std_logic_vector (15 downto 0); --Adil
  signal filter_newByteRecv : std_logic; --Adil
  signal	filter_TCPdataLen			: std_logic_vector (15 downto 0); --Adil
  signal filter_TCPdata 			: std_logic_vector (7 downto 0); --Adil
  signal filter_TCPdataValid	   : std_logic; --Adil
  signal filter_nbTCPDataByteRec : std_logic_vector (15 downto 0); --Adil
  signal filter_TCPdataCompletelyRcvd : std_logic; --Adil
  signal filter_newTCPMessage		: std_logic; --Adil

  -- IP layer
--  signal arpiprec_frameType : std_logic;
--  signal arpiprec_newFrame : std_logic;
--  signal iprec_endframe : std_logic;
--  signal iprec_endframe_d1 : std_logic;
--  signal iprec_framevalid : std_logic; -- Todo: just use it for validity of frame
  
--  signal iprec_wrRAM : std_logic;
--  signal iprec_complete : std_logic;
  signal iprec_newDatagram : std_logic;
  signal iprec_datagramSize : std_logic_vector (15 downto 0);
  signal iprec_protocol : std_logic_vector (7 downto 0);
  signal iprec_sourceIP : std_logic_vector (31 downto 0);
  signal iprec_destIP : std_logic_vector (31 downto 0); -- Adil
  
  signal ipxmit_sendDatagram : std_logic;
  signal ipxmit_datagramSize : std_logic_vector (15 downto 0);
  signal ipxmit_destinationIP: std_logic_vector (31 downto 0);
  signal ipxmit_protocol: std_logic_vector (7 downto 0);
  
  signal ipxmit_complete : std_logic;
  signal ipxmit_frameSent : std_logic;

  signal ipxmit_wrRAM : std_logic;
  signal ipxmit_wrData : std_logic_vector (7 downto 0);
--  signal ipxmit_wrAddr : std_logic_vector (18 downto 0);
  signal ipxmit_wrAddr : std_logic_vector (7 downto 0);
  signal ipxmit_sendFrame : std_logic;
  signal ipxmit_frameSize : std_logic_vector (10 downto 0);
  signal ipxmit_ARPIP: std_logic_vector (31 downto 0);
  
  -- ICMP layer
  signal icmprply_newDatagram : std_logic;
  signal icmprply_datagramSize : std_logic_vector (15 downto 0);
  signal icmprply_protocolIn : std_logic_vector (7 downto 0);
  signal icmprply_sourceIP : std_logic_vector (31 downto 0);
  signal icmprply_filter : std_logic; --Adil
  signal icmprply_complete : std_logic;
  signal icmprply_rdData : std_logic_vector (7 downto 0);
  
  signal icmprply_wrRAM : std_logic;
  signal icmprply_wrRAM_cmplt : std_logic;
  signal icmprply_wrData : std_logic_vector (7 downto 0);
  signal icmprply_wrAddr : std_logic_vector (7 downto 0);
  signal icmprply_sendDatagramSize : std_logic_vector (15 downto 0);
  signal icmprply_sendDatagram : std_logic;
  signal icmprply_destinationIP : std_logic_vector (31 downto 0);
  signal icmprply_protocolOut : std_logic_vector (7 downto 0);

  -- TCP layer
  signal tcp_client_start : std_logic := '1'; -- Adil : Added signal to force TCP client to send packets (test)
  signal tcphndl_filter_ip : std_logic; --Adil (for filtering)
  signal tcphndl_filter_port : std_logic; --Adil (for filtering)
--  signal tcphndl_virus_detect : std_logic; --Adil
  signal	tcphndl_TCPdataLen			: STD_LOGIC_VECTOR (15 downto 0); --Adil
  signal tcphndl_TCPdata 			: STD_LOGIC_VECTOR (7 downto 0); --Adil
  signal tcphndl_TCPdataValid	   : STD_LOGIC; --Adil
  signal tcphndl_nbTCPDataByteRec : STD_LOGIC_VECTOR (15 downto 0); --Adil
  signal tcphndl_TCPdataCompletelyRcvd : std_logic; --Adil
  signal tcphndl_newDatagram : std_logic;
  signal tcphndl_datagramSize : std_logic_vector (15 downto 0);
  signal tcphndl_protocolIn : std_logic_vector (7 downto 0);
  signal tcphndl_sourceIP : std_logic_vector (31 downto 0);
  signal tcphndl_srcport : std_logic_vector (15 downto 0); -- Adil (for filtering)
  signal tcphndl_dstport : std_logic_vector (15 downto 0); -- Adil (for filtering)
  signal tcphndl_newByteRecv : std_logic; --Adil
  signal tcphndl_newTCPMessage : std_logic;
--  signal tcphndl_complete : std_logic;
  signal tcphndl_recNewByte : std_logic;
  signal tcphndl_rdData : std_logic_vector (7 downto 0);
  signal tcphndl_rdDataMem : std_logic_vector (7 downto 0);

  signal tcphndl_rdRAM : std_logic;
  signal tcphndl_mpmc_dreq : std_logic;
  signal tcphndl_mpmc_reset : std_logic;
  signal tcphndl_rdRAM_cmplt : std_logic;
  signal tcphndl_wrRAM : std_logic;
  signal tcphndl_wrRAM_cmplt : std_logic;
  signal tcphndl_wrData : std_logic_vector (7 downto 0);
  signal tcphndl_wrAddr : std_logic_vector (10 downto 0);
  signal tcphndl_sendDatagramSize : std_logic_vector (15 downto 0);
  signal tcphndl_sendDatagram : std_logic;
  signal tcphndl_destinationIP : std_logic_vector (31 downto 0);
  signal tcphndl_protocolOut : std_logic_vector (7 downto 0);

  signal tcpclnt_mpmc_reset : std_logic;
  signal tcpclnt_mpmc_dmareq : std_logic;
  signal tcpclnt_mpmc_wrData : std_logic_vector (7 downto 0);
  signal tcpclnt_mpmc_wr : std_logic;
  signal tcpclnt_mpmc_fifo_full : std_logic;

  signal tcp_data_toggle : std_logic;

--  signal ip_xmit_state_cnt : std_logic_vector (3 downto 0);
--  signal icmp_xmit_state_cnt : std_logic_vector (3 downto 0);
  signal eth_xmit_state_cnt : std_logic_vector (3 downto 0);

  -- ARP layer
  signal arpiprec_newFrame: STD_LOGIC;
  signal arpiprec_frameType: STD_LOGIC;
--  signal arprec_endFrame: STD_LOGIC;
  signal arprec_frameValid: STD_LOGIC;
  signal arprec_ARPSendAvail: STD_LOGIC;
  signal arprec_requestIP: STD_LOGIC_VECTOR (31 downto 0);
  signal arprec_genARPRep: STD_LOGIC;
  signal arprec_genARPIP: STD_LOGIC_VECTOR (31 downto 0);
  signal arprec_lookupMAC: STD_LOGIC_VECTOR (47 downto 0);
  signal arprec_validEntry: STD_LOGIC;

  signal arpxmit_complete: STD_LOGIC;
  signal arpxmit_frameSent: STD_LOGIC;
  signal arpxmit_sendFrame: STD_LOGIC;
  signal arpxmit_frameLen: STD_LOGIC_VECTOR (10 downto 0);
  signal arpxmit_targetIP: STD_LOGIC_VECTOR (31 downto 0);
  signal arpxmit_ARPEntryValid: STD_LOGIC;
  signal arpxmit_genARPReply: STD_LOGIC;
  signal arpxmit_genARPIP: STD_LOGIC_VECTOR (31 downto 0);
  signal arpxmit_lookupMAC: STD_LOGIC_VECTOR (47 downto 0);
  signal arpxmit_wrRAM: STD_LOGIC;
  signal arpxmit_wrData: STD_LOGIC_VECTOR (7 downto 0);
  signal arpxmit_wrAddr: STD_LOGIC_VECTOR (7 downto 0);
  signal arpxmit_sendingFrame: STD_LOGIC;
  signal arpxmit_sendingReply: STD_LOGIC;
  signal arpxmit_targetMAC: STD_LOGIC_VECTOR (47 downto 0);
  signal arpxmit_genFrame: STD_LOGIC;
  signal arpxmit_frameType: STD_LOGIC;
  signal arpxmit_lookupIP: STD_LOGIC_VECTOR (31 downto 0);
  signal arpxmit_frameSize: STD_LOGIC_VECTOR (10 downto 0);

  signal fifo_init : std_logic;
  signal DMA_RD_INIT : std_logic;
  signal DMA_RD_DREQ : std_logic;
  signal DMA_RD_DACK : std_logic;
  signal DMA_RD_DACK_D1 : std_logic;
  signal DMA_RD_DATA : std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
  signal USER_RD_RST : std_logic;
  signal USER_RD_DREQ : std_logic;
  signal USER_READ : std_logic;
  signal USER_RD_DRDY : std_logic;
  signal FIFORD_DATA_OUT : std_logic_vector(7 downto 0);
  signal FIFORD_WR_COUNT : std_logic_VECTOR(10 downto 0);
  signal mpmc_rd_dreq_state_cnt : std_logic_VECTOR(1 downto 0);
  signal DMA_RD_BURST_END : std_logic;

  signal DMA_WR : std_logic;
  signal DMA_WR_DATA : std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
  signal DMA_FIFOWR_RD_COUNT : std_logic_vector(10 downto 0);
  signal DMA_WR_DRDY : std_logic;
  
  signal tcp_RcvOvrHd_TrigSg : std_logic;
  signal tcp_RcvOvrHd_TrigSg_d : std_logic;
  signal triger_signal_clnt : std_logic;
  signal triger_signal_srv : std_logic;

component txorb_dpmem_v4
	port (
	clka: IN std_logic;
	wea: IN std_logic_VECTOR(0 downto 0);
	addra: IN std_logic_VECTOR(10 downto 0);
	dina: IN std_logic_VECTOR(7 downto 0);
	clkb: IN std_logic;
	addrb: IN std_logic_VECTOR(11 downto 0);
	doutb: OUT std_logic_VECTOR(3 downto 0));
end component;

component txorb_dpmem_s6
	port (
	clka: IN std_logic;
	wea: IN std_logic_VECTOR(0 downto 0);
	addra: IN std_logic_VECTOR(10 downto 0);
	dina: IN std_logic_VECTOR(7 downto 0);
	clkb: IN std_logic;
	addrb: IN std_logic_VECTOR(11 downto 0);
	doutb: OUT std_logic_VECTOR(3 downto 0));
end component;

begin
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_macnewFrameByte <= rx_DPM_wr_data_new_byte_d1; 
tst_macframeData <= rx_DPM_wr_data_byte;        

tst_tcphndl_wrRAM <= tcphndl_wrRAM; 
tst_tcphndl_wrData <= tcphndl_wrData;        

tst_ipnewFrame <= arpiprec_newFrame;
tst_ipframeType <= arpiprec_frameType;

tst_ipnewDatagram <= iprec_newDatagram;

tst_macxmit_start <= transmit_start;
tst_arpxmit_genFrame <= arpxmit_genFrame;

tst_DMA_DREQ <= DMA_RD_DREQ;
tst_DMA_DACK <= DMA_RD_DACK;
tst_DMA_INIT <= DMA_RD_INIT;
tst_DMA_DATA <= DMA_RD_DATA;

tst_user_read <= USER_READ;
tst_user_drdy <= USER_RD_DRDY;
tst_fifo_data_out <= FIFORD_DATA_OUT;

tst_fifo_wr_count <= FIFORD_WR_COUNT;
tst_fifowr_rd_count <= DMA_FIFOWR_RD_COUNT;

tst_tcp_RcvOvrHd_TrigSg <= tcp_RcvOvrHd_TrigSg;
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_macnewFrameByte <= '0'; 
tst_macframeData <= (others => '0');        

tst_tcphndl_wrRAM <= '0'; 
tst_tcphndl_wrData <= (others => '0');        

tst_ipnewFrame <= '0';
tst_ipframeType <= '0';

tst_ipnewDatagram <= '0';

tst_macxmit_start <= '0';
tst_arpxmit_genFrame <= '0';

tst_DMA_DREQ <= '0';
tst_DMA_DACK <= '0';
tst_DMA_INIT <= '0';
tst_DMA_DATA <= (others => '0');

tst_user_read <= '0';
tst_user_drdy <= '0';
tst_fifo_data_out <= (others => '0');

tst_fifo_wr_count <= (others => '0');
tst_fifowr_rd_count <= (others => '0');

tst_tcp_RcvOvrHd_TrigSg <= '0';
end generate;
------------------------ TEST -------------------    

gen_v4 : if (C_FAMILY = "virtex5") generate
TX_DPRAM : txorb_dpmem_v4
port map (
   clka => Clk,
   dina => tx_DPM_wr_data_ORB,
   addra => tx_DPM_adr_ORB,
   wea => tx_DPM_wr_ORB,
   clkb => Clk,
   addrb => tx_DPM_adr_MAC,
   doutb => tx_ping_rd_data_ORB);

TX_DPRAM_ARP : txorb_dpmem_v4
port map (
   clka => Clk,
   dina => tx_DPM_wr_data_ARP,
   addra => tx_DPM_adr_ARP,
   wea => tx_DPM_wr_ARP,
   clkb => Clk,
   addrb => tx_DPM_adr_MAC,
   doutb => tx_ping_rd_data_ARP);
End Generate;

gen_s6 : if (C_FAMILY = "spartan6" or C_FAMILY = "spartan6t") generate
TX_DPRAM : txorb_dpmem_s6
port map (
   clka => Clk,
   dina => tx_DPM_wr_data_ORB,
   addra => tx_DPM_adr_ORB,
   wea => tx_DPM_wr_ORB,
   clkb => Clk,
   addrb => tx_DPM_adr_MAC,
   doutb => tx_ping_rd_data_ORB);
TX_DPRAM_ARP : txorb_dpmem_s6
port map (
   clka => Clk,
   dina => tx_DPM_wr_data_ARP,
   addra => tx_DPM_adr_ARP,
   wea => tx_DPM_wr_ARP,
   clkb => Clk,
   addrb => tx_DPM_adr_MAC,
   doutb => tx_ping_rd_data_ARP);
End Generate;


fifo_i : entity hardorb_fpga_v3_01_a.d_fifo
--fifo_i : entity work.d_fifo
generic map (
   C_DEBUG_MODE                  => C_DEBUG_MODE,
   C_TCP_OPERATION_MODE          => C_TCP_OPERATION_MODE,
   C_FAMILY                      => C_FAMILY,
   C_VD_DATA_WIDTH               => C_NPI_DATA_WIDTH)
port map (
-- System interface      
   Sys_Clk                       => Clk,                    -- Base system clock
   NPI_CLK                       => NPI_CLK,
   Sys_Rst                       => fifo_init,

-- DMA Channel interface
   DMA_RD_DREQ                   => DMA_RD_DREQ,
   DMA_RD_DACK                   => DMA_RD_DACK,
   DMA_RD_DATA                   => DMA_RD_DATA,

------------------------ TEST -------------------    
tst_fifo_wr_en => tst_fifo_wr_en,
------------------------ TEST -------------------    

-- User interface (the reader side)
   USER_RD_CLK                   => Clk,
   USER_RD_RST                   => USER_RD_RST,
   USER_RD_DREQ                  => USER_RD_DREQ,
   USER_RD                       => USER_READ,
   USER_RD_DRDY                  => USER_RD_DRDY,
   
   USER_RD_DATA                  => FIFORD_DATA_OUT,
   FIFORD_WR_COUNT               => FIFORD_WR_COUNT, 

-- User interface (the writer side)
	 DMA_WR                        => DMA_WR,
	 DMA_WR_DATA                   => DMA_WR_DATA,
	 FIFOWR_RD_COUNT               => DMA_FIFOWR_RD_COUNT,
    DMA_WR_DRDY                   => DMA_WR_DRDY,
    USER_WR_RST                   => tcpclnt_mpmc_reset,
	 USER_WR_DATA                  => tcpclnt_mpmc_wrData,
	 USER_WR_CLK                   => Clk,
	 USER_WR                       => tcpclnt_mpmc_wr,
    FIFOWR_FULL                   => tcpclnt_mpmc_fifo_full
   );

fifo_init <= Rst Or (Not DMA_RD_INIT);


MEM_CTRL_NPI : entity hardorb_fpga_v3_01_a.npi_eng
--MEM_CTRL_NPI : entity work.npi_eng
generic map(
   C_DEBUG_MODE         => C_DEBUG_MODE,

   C_TCP_OPERATION_MODE => C_TCP_OPERATION_MODE,

   C_RD_MEMBLK_ADDR     => C_RD_MEMBLK_ADDR,
   C_WR_MEMBLK_ADDR     => C_WR_MEMBLK_ADDR,
   C_TOTAL_BYTE_NUM     => C_TOTAL_BYTE_NUM,
	
   C_NPI_BURST_SIZE     => C_NPI_BURST_SIZE,
   C_NPI_ADDR_WIDTH     => C_NPI_ADDR_WIDTH,
   C_NPI_DATA_WIDTH     => C_NPI_DATA_WIDTH,
   C_NPI_BE_WIDTH       => C_NPI_BE_WIDTH,
   C_NPI_RDWDADDR_WIDTH => C_NPI_RDWDADDR_WIDTH)
port map (
   NPI_Clk              => NPI_Clk,
   Sys_Clk              => Clk,
   NPI_RST              => NPI_RST,

   NPI_Addr             => NPI_Addr,
   NPI_AddrReq          => NPI_AddrReq,
   NPI_AddrAck          => NPI_AddrAck,
   NPI_RNW              => NPI_RNW,
   NPI_Size             => NPI_Size,
   NPI_WrFIFO_Data      => NPI_WrFIFO_Data,
   NPI_WrFIFO_BE        => NPI_WrFIFO_BE,
   NPI_WrFIFO_Push      => NPI_WrFIFO_Push,
   NPI_RdFIFO_Data      => NPI_RdFIFO_Data,
   NPI_RdFIFO_Pop       => NPI_RdFIFO_Pop,
   NPI_RdFIFO_RdWdAddr  => NPI_RdFIFO_RdWdAddr,
   NPI_WrFIFO_Empty     => NPI_WrFIFO_Empty,
   NPI_WrFIFO_AlmostFull => NPI_WrFIFO_AlmostFull,
   NPI_WrFIFO_Flush     => NPI_WrFIFO_Flush,
   NPI_RdFIFO_Empty     => NPI_RdFIFO_Empty,
   NPI_RdFIFO_Flush     => NPI_RdFIFO_Flush,
   NPI_RdFIFO_Latency   => NPI_RdFIFO_Latency,
   NPI_RdModWr          => NPI_RdModWr,
   NPI_InitDone         => NPI_InitDone,

------------------------ TEST -------------------    
tst_burst_cnt_one => tst_burst_cnt_one,
tst_burst_cnt => tst_burst_cnt,
------------------------ TEST -------------------    

   DMA_RD_INIT          => DMA_RD_INIT,
   DMA_RD_DREQ          => DMA_RD_DREQ,
   DMA_RD_DACK          => DMA_RD_DACK,
   DMA_RD_DATA          => DMA_RD_DATA,
   DMA_RD_BURST_END     => DMA_RD_BURST_END,

   DMA_WR_RST           => tcpclnt_mpmc_reset,
	DMA_WR_DREQ          => tcpclnt_mpmc_dmareq,
	DMA_WR               => DMA_WR,
	DMA_WR_DATA          => DMA_WR_DATA,
	DMA_FIFOWR_RD_COUNT  => DMA_FIFOWR_RD_COUNT,
   DMA_WR_DRDY          => DMA_WR_DRDY
   );


ARP_REC : entity hardorb_fpga_v3_01_a.ARP 
--ARP_REC : entity work.ARP 
generic map(
   C_DEBUG_MODE  => C_DEBUG_MODE,
   DEVICE_IP     => DEVICE_IP,
   DEVICE_MAC    => DEVICE_MAC)
port map(
   clk           => Clk,
   rstn          => not Rst,
   newFrame      => arpiprec_newFrame,            -- new frame received from the layer below
   frameType     => arpiprec_frameType,           -- '0' for an ARP message
   newFrameByte  => rx_DPM_wr_data_new_byte_d1, -- signals a new byte in the stream
   frameData     => rx_DPM_wr_data_byte,        -- data is streamed in here
--       endFrame      => arprec_endFrame,						-- asserted at the end of a frame
   frameValid    => arprec_frameValid,					-- indicates validity while endFrame is asserted
   ARPSendAvail  => arprec_ARPSendAvail,				-- ARP sender asserts this when the reply is transmitted
   requestIP     => arprec_requestIP,	          -- ARP sender can request MACs for this address
   genARPRep     => arprec_genARPRep,						-- tell ARP sender to generate a reply
   genARPIP      => arprec_genARPIP,            -- destination IP for generated reply
   lookupMAC     => arprec_lookupMAC,	          -- if valid, MAC for requested IP
------------------------ TEST -------------------    
tst_arprecpresstate => tst_arprecpresstate,
tst_arprecnewFrame => tst_arprecnewFrame,
tst_arprecframeType => tst_arprecframeType,
------------------------ TEST -------------------    
   validEntry    => arprec_validEntry						-- indicates if requestIP is in table
    );


ARP_XMIT : entity hardorb_fpga_v3_01_a.ARPSnd 
--ARP_XMIT : entity work.ARPSnd 
generic map(
   C_DEBUG_MODE  => C_DEBUG_MODE,
   DEVICE_IP     => DEVICE_IP,
   DEVICE_MAC    => DEVICE_MAC)
port map(
   clk           => Clk,
   rstn          => not Rst,
   complete      => arpxmit_complete,    	-- complete signal from the RAM operation
   frameSent     => arpxmit_frameSent,		-- indicates the ethernet has sent a frame
   sendFrame     => arpxmit_sendFrame,		-- send an ethernet frame - from IP layer
   frameLen      => arpxmit_frameLen,	    -- input from IP giving frame length
   targetIP      => arpxmit_targetIP,	    -- destination IP from the internet layer
   ARPEntryValid => arpxmit_ARPEntryValid,-- input from ARP indicating that it contains the requested IP
   genARPReply   => arpxmit_genARPReply,	-- input from ARP requesting an ARP reply
   genARPIP      => arpxmit_genARPIP,	    -- input from ARP saying which IP to send a reply to
   lookupMAC     => arpxmit_lookupMAC,	  -- input from ARP giving a requested MAC

   lookupIP      => arpxmit_lookupIP,	    -- output to ARP requesting an IP to be looked up in the table
   sendingReply  => arpxmit_sendingReply,	-- output to ARP to tell it's sending the ARP reply
   targetMAC     => arpxmit_targetMAC,	  -- destination MAC for the physical layer
   genFrame      => arpxmit_genFrame,			-- tell the ethernet layer (PHY) to send a frame
   frameType     => arpxmit_frameType,		-- tell the PHY to send an ARP frame or normal IP datagram
   frameSize     => arpxmit_frameSize,    -- tell the PHY what size the frame size is
   idle          => open,							    -- idle signal
   sendingFrame  => arpxmit_sendingFrame, -- tell the IP layer that we're sending their data
   wrRAM         => arpxmit_wrRAM,				-- write RAM signal to the RAM
   wrData        => arpxmit_wrData,	      -- write data bus to the RAM
------------------------ TEST -------------------    
tst_arpxmitpresstate => tst_arpxmitpresstate,
------------------------ TEST -------------------    
   wrAddr        => arpxmit_wrAddr			  -- write address for RAM
    );

FILTER_INC : entity hardorb_fpga_v3_01_a.filter_inc_pack
	 generic map 
	 ( -- Packets are processed only if they come from this network
	   AUTHORIZED_NETWORK => x"C0A80100", -- 192.168.1.0/24
	   NETWORK_MASK => x"FFFFFF00", -- 255.255.255.0
		
		-- Packets are processed only if the destination IP of the packet is the IP of this device
		DEVICE_IP => DEVICE_IP,
		AUTHORIZED_SOURCE_IP => x"C0A80102",
		
		-- For TCP packets, Packets are processed only if the destination Port of the packet is this port number
		AUTHORIZED_DEST_PORT => DEVICE_TCP_PORT, -- port number 39396
		AUTHORIZED_SOURCE_PORT => x"DFCC", --port number 57292;
		
		-- Packets are processed only if the transport layer is TCP
		AUTHORIZED_PROTOCOL => x"06")
    Port map( 
		clk => Clk,
		clk_150 => NPI_Clk,
      rst => not Rst,
      protocol => filter_protocol_in,
      source_ip => filter_src_ip_in,
      dest_ip => filter_dst_ip_in,
      source_port => filter_src_port_in,
		dest_port => filter_dst_port_in,
--		virus_detect => filter_virus_detect_in,
		TCPdataLen =>	filter_TCPdataLen,
		TCPdata => filter_TCPdata,
		TCPdataValid => filter_TCPdataValid,
		nbTCPDataByteRec => filter_nbTCPDataByteRec,
		TCPdataCompletelyRcvd => filter_TCPdataCompletelyRcvd, --Adil
		newByteRecv => filter_newByteRecv,
		leds => GPIO_IO,
		PHY_rx_clk => PHY_rx_clk,
		newTCPMessage => filter_newTCPMessage,
		allow_process_ip => filter_ip,
		allow_process_tcp => filter_tcp,
		
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
		VFBC2_rd_almost_empty	=> VFBC2_rd_almost_empty
		--------------- Memory Controller Interface, VFBC mode (Adil) -----
	);

IP_REC : entity hardorb_fpga_v3_01_a.internet 
--IP_REC : entity work.internet 
generic map(
   C_DEBUG_MODE  => C_DEBUG_MODE,
   DEVICE_IP     => DEVICE_IP)
port  map
   (
   clk           => Clk,
   rstn          => not Rst,
--       complete      => iprec_complete,             -- control signal from ram arbitrator
   newFrame      => arpiprec_newFrame,             -- new frame received from the layer below
   frameType     => arpiprec_frameType,            -- frame type = '1' for IP
   newFrameByte  => rx_DPM_wr_data_new_byte_d1, -- signals a new byte in the stream
   frameData     => rx_DPM_wr_data_byte,        -- data is streamed in here
--       endFrame      => iprec_endframe_d1,          -- signals the end of a frame
--       frameValid    => iprec_framevalid,           -- determines validity of frame when endFrame is high
   newDatagram   => iprec_newDatagram,          -- an IP datagram has been fully received
--       bufferSelect  => open,                 -- indicates location of data in RAM, '0' = 10000, '1' = 20000
   datagramSize  => iprec_datagramSize,         -- size of the datagram received
   protocol      => iprec_protocol,             -- protocol type of datagram

------------------------ TEST -------------------    
tst_ipcnt => tst_ipcnt,
tst_ipinByte => tst_ipinByte,
tst_ipnewByte => tst_ipnewByte, 
tst_ippresstate => tst_ippresstate,
------------------------ TEST -------------------    

   sourceIP      => iprec_sourceIP,             -- lets upper protocol know the source IP
	destIP      => iprec_destIP             	  -- lets the filter know the destination IP --Adil
--       wrRAM         => iprec_wrRAM                -- signal to write to the RAM
--       wrData        => open,
--       wrAddr        => open,
--       timeLED0      => open,
--       timeLED1      => open
   );


IP_XMIT : entity hardorb_fpga_v3_01_a.InternetSnd 
--IP_XMIT : entity work.InternetSnd 
generic map(
   C_DEBUG_MODE  => C_DEBUG_MODE,
   DEVICE_IP     => DEVICE_IP)
port  map
(
   clk          => Clk,									-- clock
   rstn         => not Rst,				  		-- active low asynchronous reset
   frameSent    => ipxmit_frameSent,			-- indicates the ethernet has sent a frame
   sendDatagram => ipxmit_sendDatagram,	-- signal to send a datagram message
   datagramSize => ipxmit_datagramSize,	-- size of datagram to transmit
   destinationIP=> ipxmit_destinationIP,	-- IP to transmit message to
--        addressOffset=> (others => '0'),	    -- Indicates location in RAM of datagram
   protocol     => ipxmit_protocol,			-- protocol of the datagram to be sent
   complete     => ipxmit_complete,    	-- complete signal from the RAM operation
   rdData       => (others => '0'),      -- read data from RAM
        
--        rdRAM        => open,								  -- read signal for RAM
--        rdAddr       => open,			            -- read address for RAM
   wrRAM        => ipxmit_wrRAM,					-- write signal for RAM
   wrData       => ipxmit_wrData,		    -- write data for RAM
   wrAddr       => ipxmit_wrAddr,			  -- write address for RAM
   sendFrame    => ipxmit_sendFrame,			-- signal to get ethernet to send frame
   datagramSent => open,	                -- tells higher protocol when the datagram was sent
   frameSize    => ipxmit_frameSize,		  -- tells the ethernet layer how long the frame is
   ARPIP        => ipxmit_ARPIP          -- IP that the ARP layer must look up
);

ICMPPORTMAP: if C_ICMP_MODE = 1 generate

ICMP_REPLY : entity hardorb_fpga_v3_01_a.icmp 
--ICMP_REPLY : entity work.icmp 
port  map
(
   clk          => Clk,									-- clock
   rstn         => not Rst,							-- asynchronous active low reset
   newDatagram  => icmprply_newDatagram,	-- asserted when a new datagram arrive
   datagramSize => icmprply_datagramSize,-- size of the arrived datagram
   bufferSelect => '0',								  -- informs which IP buffer the data is in
   protocolIn   => icmprply_protocolIn,	-- protocol type of the datagram
   sourceIP     => icmprply_sourceIP,		-- IP address that sent the message
	filter_ip_addr => icmprply_filter,					-- respond only to authorized source IP addresses Adil
   complete     => icmprply_complete,		-- asserted when then RAM operation is complete
   rdData       => icmprply_rdData,  		-- read data bus from the RAM
        
--        rdRAM        => open,									-- asserted to tell the RAM to read
--        rdAddr       => open,				          -- read address bus to the RAM
   wrRAM        => icmprply_wrRAM,				-- asserted to tell the RAM to write
   wrData       => icmprply_wrData,      -- write data bus to the RAM
   wrAddr       => icmprply_wrAddr,      -- write address bus to the RAM
   sendDatagramSize => icmprply_sendDatagramSize,-- size of the ping to reply to
   sendDatagram => icmprply_sendDatagram,-- tells the IP layer to send a datagram
   destinationIP=> icmprply_destinationIP,-- target IP of the datagram
   addressOffset=> open,		              -- tells the IP layer which buffer the data is in
   protocolOut  => icmprply_protocolOut	-- tells the IP layer which protocol it is
   );
end generate;

TCPServer: if C_TCP_OPERATION_MODE = 1 or C_TCP_OPERATION_MODE = 3 generate

TCP_SERVER_HANDLER : entity hardorb_fpga_v3_01_a.TCPServer 
--TCP_SERVER_HANDLER : entity work.TCPServer 
generic map(
   C_DEBUG_MODE    => C_DEBUG_MODE,
   DEVICE_IP       => DEVICE_IP,
   DEVICE_TCP_PAYLOAD => DEVICE_TCP_PAYLOAD,
   DEVICE_TCP_PORT => DEVICE_TCP_PORT)
port  map
(
   clk                 => Clk,									-- clock
   rstn                => not Rst,							-- asynchronous active low reset

   newDatagram         => tcphndl_newDatagram,	-- asserted when a new datagram arrive
   datagramSize        => tcphndl_datagramSize,-- size of the arrived datagram
   protocolIn          => tcphndl_protocolIn,	-- protocol type of the datagram
   sourceIP            => tcphndl_sourceIP,		-- IP address that sent the message
--   complete            => tcphndl_complete,		-- asserted when then RAM operation is complete
   wr_complete         => tcphndl_wrRAM_cmplt,  -- asserted when then DPMEM write operation is complete
   rd_complete         => tcphndl_rdRAM_cmplt,  -- asserted when then DDRMEM write operation is complete
   recNewByte          => tcphndl_recNewByte,	-- asserted when then RX SPY section receives new byte
   rdData              => tcphndl_rdData,  		-- read data bus from the ip layer
   rdDataMem           => tcphndl_rdDataMem,	-- read data bus from the DDR MEM
   tx_done_MAC         => tx_done_MAC, -- Todo: is there any other alternative? it is depend on software to enable!!!
   rx_done_MAC         => rx_done,-- Todo: is there any other alternative? it is depend on software to enable!!!
   filter_ip_addr => tcphndl_filter_ip, -- Adil
	filter_port => tcphndl_filter_port,	-- Adil
--	virusDetect => tcphndl_virus_detect, -- Adil
	TCPdataLen => tcphndl_TCPdataLen, --Adil
	TCPdataValid => tcphndl_TCPdataValid, --Adil
	TCPdata => tcphndl_TCPdata, --Adil
	nbTCPDataByteRec => tcphndl_nbTCPDataByteRec, --Adil
	TCPdataCompletelyRcvd => tcphndl_TCPdataCompletelyRcvd, --Adil
	newTCPMessage => tcphndl_newTCPMessage,
	newByteRecv => tcphndl_newByteRecv, --Adil

   rdRAM               => tcphndl_rdRAM,			 -- asserted to tell the DDR RAM to read
   mpmc_dreq           => tcphndl_mpmc_dreq,
   mpmc_reset          => tcphndl_mpmc_reset,
   wrRAM               => tcphndl_wrRAM,	  	 -- asserted to tell the DPRAM to write
   wrData              => tcphndl_wrData,      -- write data bus to the TX MAC DPRAM
   wrAddr              => tcphndl_wrAddr,      -- write address bus to the RAM
   sendDatagramSize    => tcphndl_sendDatagramSize,-- size of the ping to reply to
   sendDatagram        => tcphndl_sendDatagram,-- tells the IP layer to send a datagram
   destinationIP       => tcphndl_destinationIP,-- target IP of the datagram
	src_port_rec => tcphndl_srcport,
	dst_port_rec => tcphndl_dstport,

------------------------ TEST -------------------    
tst_tcpcmpltRec => tst_tcpcmpltRec,
tst_tcpnewByteRec => tst_tcpnewByteRec,
tst_tcpinByteRec => tst_tcpinByteRec,
tst_tcpbusyXmit => tst_tcpbusyXmit,
tst_tcpsendTCP => tst_tcpsendTCP,
tst_tcppresstateRec => tst_tcppresstateRec,
tst_tcppresstateXmit => tst_tcppresstateXmit,
tst_tcppresstateSrv => tst_tcppresstateSrv,
tst_tcprx_done => tst_tcprx_done,
------------------------ TEST -------------------    
   sndOvrhd_trigSg     => triger_signal_srv,
        
   protocolOut         => tcphndl_protocolOut	-- tells the IP layer which protocol it is
   );
triger_signal <= triger_signal_srv;   

end generate;

TCPClient: if C_TCP_OPERATION_MODE = 2 or C_TCP_OPERATION_MODE = 3 generate

TCP_CLIENT_HANDLER : entity hardorb_fpga_v3_01_a.TCPClient
--_CLIENT_HANDLER : entity work.TCPClient
generic map(
   C_DEBUG_MODE    => C_DEBUG_MODE,
   DEST_IP         => DEST_IP,
   DEVICE_IP       => DEVICE_IP,
   DEVICE_TCP_PAYLOAD => DEVICE_TCP_PAYLOAD,
   SRC_TCPCLNT_PORT => SRC_TCPCLNT_PORT,
   DEST_TCPCLNT_PORT => DEST_TCPCLNT_PORT)
port  map
(
   clk                 => Clk,									-- clock
   rstn                => not Rst,							-- asynchronous active low reset
   
--   TCP_StrtClnt        => TCP_StrtClnt,
	
	TCP_StrtClnt        => tcp_client_start,
   newDatagram         => tcphndl_newDatagram,	-- asserted when a new datagram arrive
   datagramSize        => tcphndl_datagramSize,-- size of the arrived datagram
   protocolIn          => tcphndl_protocolIn,	-- protocol type of the datagram
   wr_complete         => tcphndl_wrRAM_cmplt,  -- asserted when then DPMEM write operation is complete
   recNewByte          => tcphndl_recNewByte,	-- asserted when then RX SPY section receives new byte
   rdData              => tcphndl_rdData,  		-- read data bus from the ip layer
   rdDataMem           => tcphndl_rdDataMem,	-- read data bus from the DDR MEM
   tx_done_MAC         => tx_done_MAC, -- Todo: is there any other alternative? it is depend on software to enable!!!
   rx_done_MAC         => rx_done,-- Todo: is there any other alternative? it is depend on software to enable!!!
        
   wrRAM               => tcphndl_wrRAM,	  	 -- asserted to tell the DPRAM to write
   wrData              => tcphndl_wrData,      -- write data bus to the TX MAC DPRAM
   wrAddr              => tcphndl_wrAddr,      -- write address bus to the RAM
   sendDatagramSize    => tcphndl_sendDatagramSize,-- size of the ping to reply to
   sendDatagram        => tcphndl_sendDatagram,-- tells the IP layer to send a datagram
   destinationIP       => tcphndl_destinationIP,-- target IP of the datagram

------------------------ TEST -------------------    
tst_tcpcmpltRec => tst_tcpcmpltRec,
tst_tcpnewByteRec => tst_tcpnewByteRec,
tst_tcpinByteRec => tst_tcpinByteRec,
tst_tcpbusyXmit => tst_tcpbusyXmit,
tst_tcpsendTCP => tst_tcpsendTCP,
tst_tcppresstateRec => tst_tcppresstateRec,
tst_tcppresstateXmit => tst_tcppresstateXmit,
tst_tcppresstateSrv => tst_tcppresstateSrv,
tst_tcprx_done => tst_tcprx_done,
------------------------ TEST -------------------    
        
   protocolOut         => tcphndl_protocolOut,	-- tells the IP layer which protocol it is
   
   rcvOvrHd_TrigSg     => tcp_RcvOvrHd_TrigSg,

   mpmc_reset          => tcpclnt_mpmc_reset,
   mpmc_dmareq         => tcpclnt_mpmc_dmareq,
   mpmc_wrData         => tcpclnt_mpmc_wrData,
   mpmc_wr             => tcpclnt_mpmc_wr,
   mpmc_fifo_full      => tcpclnt_mpmc_fifo_full
   );

triger_signal <= triger_signal_clnt;   
end generate;

ICMP_NETPROTOCOLPROC_NON: if C_ICMP_MODE = 0 generate
   ----------------------------------------------------------------------------
   -- Network protocol stack handler process
   ----------------------------------------------------------------------------
   PROTCL_STACK_HNDLR: process (Clk)
     begin
       if Clk'event and Clk = '1' then
         if Rst = '1' then
           triger_signal_clnt <= '0';
--           triger_signal <= '0';

           arp_en <= '0';

           rec_hard_orb_en <= '0';
           hrd_orb_wr_xbuf_en <= '0';
           
           tx_DPM_wr_ORB(0) <= '0';
           tx_DPM_adr_ORB <= (others => '1');
           tx_DPM_wr_data_ORB <= (others => '0');

           tx_DPM_wr_ARP(0) <= '0';
           tx_DPM_adr_ARP <= (others => '1');
           tx_DPM_wr_data_ARP <= (others => '0');

           rx_done_SW <= '0';
           OrbCmd_start_tx <= '0';
           OrbCmd_clr_rx_stats <= '0';
           rx_DPM_wr_data_byte <= (others => '0');
           rx_DPM_wr_data_byte_d0 <= (others => '0');
           rx_DPM_wr_data_byte_d1 <= (others => '0');
           rx_DPM_wr_data_new_byte_toggle <= '0';
           rx_DPM_wr_data_new_byte_d1 <= '0'; 
           
           ipxmit_complete <= '0';
           
			  tcphndl_wrRAM_cmplt <= '0';
--           tcphndl_rdRAM_cmplt <= '0';

           eth_xmit_state_cnt <= (others => '0');
           
           tx_done_SW <= '0';

           tcp_data_toggle <= '0';

           transmit_start_prev <= '0';
           arpiprec_frameType <= '1';
           arpiprec_newFrame <= '0';
           arprec_framevalid <= '0';
			  
--			  filter_protocol_in <= (others => '0');
--			  filter_src_ip_in <= (others => '0');
--			  filter_dst_ip_in <= (others => '0');
--			  filter_src_port_in <= (others => '0');
--			  filter_dst_port_in <= (others => '0');
--			  filter_ip <= '0';
--			  filter_tcp <= '0';
        
         else 
------------------------------------------------------------------           
-- PLB/ORB bus multiplexer section
------------------------------------------------------------------           
           rec_hard_orb_en <= '0';
--           hrd_orb_wr_xbuf_en <= '0';

         
           rx_done_SW <= '0';
           if ( rec_hard_orb_en = '0' ) then
              rx_done_SW <= rx_done;
           end if;
           
           OrbCmd_clr_rx_stats <= rx_done; -- Todo: OS or HArd_ORB???


------------------------------------------------------------------           
-- MAC layer RX SPY section
------------------------------------------------------------------           
           if ( rx_DPM_adr = x"000" ) then 
              rx_DPM_wr_data_new_byte_toggle <= '0';
           end if;

           if ( rx_ping_ce = '1' and rx_DPM_wr_rd_n = '1' ) then
              rx_DPM_wr_data_byte <= rx_DPM_wr_data & rx_DPM_wr_data_byte(0 to 3);
              rx_DPM_wr_data_byte_d0 <= rx_DPM_wr_data_byte;
              rx_DPM_wr_data_byte_d1 <= rx_DPM_wr_data_byte_d0;
              rx_DPM_wr_data_new_byte_toggle <= not rx_DPM_wr_data_new_byte_toggle;
           end if;

------------------------------------------------------------------           
-- DPRAM write en signal section
------------------------------------------------------------------           
           if ( eth_xmit_state_cnt /= x"0" or eth_xmit_state_cnt /= x"F" or arpxmit_wrRAM = '1' or ipxmit_wrRAM = '1' ) then
              tx_DPM_wr_ORB(0) <= '1';
              tx_DPM_wr_ARP(0) <= '1';
           else
              tx_DPM_wr_ORB(0) <= '0';
              tx_DPM_wr_ARP(0) <= '0';
           end if;

------------------------------------------------------------------           
-- Ethernet layer TX section
------------------------------------------------------------------           
           OrbCmd_start_tx <= '0';
           
           tx_done_SW <= '0';

           if ( tx_done_MAC = '1' ) then   
              hrd_orb_wr_xbuf_en <= '0';
              if ( hrd_orb_wr_xbuf_en = '0' ) then   
                 tx_done_SW <= '1';
              end if;
           end if;

			  transmit_start_prev <= transmit_start;
           case eth_xmit_state_cnt(3 downto 0) is
						when x"0" =>
              tx_DPM_adr_ORB <= "111" & x"11";
              tx_DPM_wr_data_ORB  <= x"00";
              tx_DPM_adr_ARP <= "111" & x"11";
              tx_DPM_wr_data_ARP  <= x"00";
              
              if ( arpxmit_genFrame = '1' ) then 
                 eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
                 tx_packet_len_SW <= ("00000" & arpxmit_frameSize);
              end if;
            -- Destination MAC address  -----------------------------
						when x"1" =>
              tx_DPM_adr_ORB <= "000" & x"00";
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (47 downto 40);
              tx_DPM_adr_ARP <= "000" & x"00";
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (47 downto 40);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"2" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (39 downto 32);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (39 downto 32);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"3" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (31 downto 24);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (31 downto 24);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"4" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (23 downto 16);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (23 downto 16);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"5" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (15 downto 8);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (15 downto 8);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"6" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (7 downto 0);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (7 downto 0);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
            -- Source MAC address  -----------------------------
						when x"7" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (47 downto 40);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (47 downto 40);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"8" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (39 downto 32);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (39 downto 32);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"9" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (31 downto 24);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (31 downto 24);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"A" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (23 downto 16);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (23 downto 16);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"B" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (15 downto 8);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (15 downto 8);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"C" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (7 downto 0);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (7 downto 0);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"D" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= x"08"; 
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= x"08"; 
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
            -- Type: IP (0x0800)  -----------------------------
						when x"E" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              if ( arpxmit_frameType = '0' ) then
                 tx_DPM_wr_data_ORB  <= x"06";-- ARP
                 tx_DPM_wr_data_ARP  <= x"06";-- ARP
              else
                 tx_DPM_wr_data_ORB  <= x"00";-- IP
                 tx_DPM_wr_data_ARP  <= x"00";-- IP
              end if;
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"F" =>
              if ( transmit_start = '0' and transmit_start_prev = '1' ) then
                eth_xmit_state_cnt <= x"0";
              elsif ( transmit_start = '0' ) then
                OrbCmd_start_tx <= '1'; -- Todo: it must be activated only when Hard_ORB should reply!
                hrd_orb_wr_xbuf_en <= '1';  -- Todo: it must be activated only when Hard_ORB should reply!
              else  
                eth_xmit_state_cnt <= x"F";
              end if;
	 					when others =>
              eth_xmit_state_cnt <= x"0";
					 end case;

------------------------------------------------------------------           
-- ARP layer RX section
------------------------------------------------------------------           
           arpiprec_frameType <= '1';
           arpiprec_newFrame <= '0';

           if ( rx_done = '1' ) then
             triger_signal_clnt <= '0';
--             triger_signal <= '0';
           end if;  
           
           if ( rx_DPM_adr = x"01C" and rx_DPM_wr_data_byte_d1 = x"08" and rx_DPM_wr_data_new_byte_d1 = '1' ) then -- 0x01A = 26
              triger_signal_clnt <= tcp_RcvOvrHd_TrigSg;
--              triger_signal <= tcp_RcvOvrHd_TrigSg;

              if rx_DPM_wr_data_byte = x"06"  then
                arpiprec_frameType <= '0'; -- ARP
                arpiprec_newFrame <= '1';
              elsif ( rx_DPM_wr_data_byte = x"00" ) then -- 0x01A = 26
                arpiprec_frameType <= '1'; -- IP
                arpiprec_newFrame <= '1';
              end if;
           end if;

           arprec_framevalid <= '0';

           if ( rx_done = '1' and rx_DPM_wr_rd_n = '0' ) then
              arprec_framevalid <= '1';
           end if;

------------------------------------------------------------------           
-- ARP layer TX section
------------------------------------------------------------------           
           arpxmit_frameSent <= '0';
           if ( tx_done_MAC = '1' ) then -- Todo: is it from hard ORB?
              arpxmit_frameSent <= '1';
              arp_en <= '0';
           end if;

           if ( arpxmit_wrRAM = '1' ) then
--            tx_DPM_adr_ORB <= arpxmit_wrAddr(10 downto 0); -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_adr_ARP <= "000" & arpxmit_wrAddr; -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_wr_data_ARP  <= arpxmit_wrData;
              arp_en <= '1';
           end if;

           arpxmit_complete <= arpxmit_wrRAM;

------------------------------------------------------------------           
-- IP layer RX section
------------------------------------------------------------------           

           rx_DPM_wr_data_new_byte_d1 <= rx_DPM_wr_data_new_byte;
			  

------------------------------------------------------------------           
-- IP layer TX section
------------------------------------------------------------------           
           ipxmit_frameSent <= ipxmit_sendFrame;

           if ( ipxmit_wrRAM = '1' ) then
--            tx_DPM_adr_ORB <= ipxmit_wrAddr(10 downto 0); -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_adr_ORB <= "000" & ipxmit_wrAddr; -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_wr_data_ORB  <= ipxmit_wrData;
           end if;

           ipxmit_complete <= ipxmit_wrRAM;

------------------------------------------------------------------           
-- TCP layer handler section
------------------------------------------------------------------           

--			  if (tcphndl_wrTCPData_en = "1") then
--				  mem_tcp_data_wr_en <= tcphndl_wrTCPData_en;
--              mem_tcp_data_wr_data <= tcphndl_wrTCPData;
--              mem_tcp_data_wr_addr  <= tcphndl_wrTCPData_addr;
--           end if;
			  
			  tcphndl_wrRAM_cmplt <= '0';
           if (tcphndl_wrRAM = '1') then
              tx_DPM_adr_ORB <= tcphndl_wrAddr;
              tx_DPM_wr_data_ORB  <= tcphndl_wrData;
              tcphndl_wrRAM_cmplt <= '1';
           end if;		  
           
--					 tcphndl_rdRAM_cmplt <= '0';
 
--           if ( tcphndl_rdRAM = '1' ) then
----              tx_DPM_adr_ORB <= tcphndl_rdAddr(10 downto 0); -- Todo: size of tcphndl_wrAddr is high!
--              tcphndl_rdDataMem  <= FIFORD_DATA_OUT;
--				  if (tcp_data_toggle = '0') then 
--                tcphndl_rdDataMem  <= x"AA";
--              else
--                tcphndl_rdDataMem  <= x"55";
--              end if;
--              tcp_data_toggle <= not tcp_data_toggle;
--              tcphndl_rdRAM_cmplt <= '1';
--           end if;
           
------------------------------------------------------------------           
           
         end if;
       end if;
     end process PROTCL_STACK_HNDLR;
end generate;


ICMP_NETPROTOCOLPROC: if C_ICMP_MODE = 1 generate
   ----------------------------------------------------------------------------
   -- Netowrk protocol stack handler process
   ----------------------------------------------------------------------------
   PROTCL_STACK_HNDLR: process (Clk)
     begin
       if Clk'event and Clk = '1' then
         if Rst = '1' then
           triger_signal_clnt <= '0';
--           triger_signal <= '0';
           
           arp_en <= '0';

           rec_hard_orb_en <= '0';
           hrd_orb_wr_xbuf_en <= '0';
           
           tx_DPM_wr_ORB(0) <= '0';
           tx_DPM_adr_ORB <= (others => '1');
           tx_DPM_wr_data_ORB <= (others => '0');

           tx_DPM_wr_ARP(0) <= '0';
           tx_DPM_adr_ARP <= (others => '1');
           tx_DPM_wr_data_ARP <= (others => '0');

           rx_done_SW <= '0';
           OrbCmd_start_tx <= '0';
           OrbCmd_clr_rx_stats <= '0';
           rx_DPM_wr_data_byte <= (others => '0');
           rx_DPM_wr_data_byte_d0 <= (others => '0');
           rx_DPM_wr_data_byte_d1 <= (others => '0');
           rx_DPM_wr_data_new_byte_toggle <= '0';
           rx_DPM_wr_data_new_byte_d1 <= '0'; 
           
           ipxmit_complete <= '0';
           
			  icmprply_wrRAM_cmplt <= '0';

			  tcphndl_wrRAM_cmplt <= '0';
--           tcphndl_rdRAM_cmplt <= '0';

           eth_xmit_state_cnt <= (others => '0');
           
           tx_done_SW <= '0';

           tcp_data_toggle <= '0';

           transmit_start_prev <= '0';
           arpiprec_frameType <= '1';
           arpiprec_newFrame <= '0';
           arprec_framevalid <= '0';
			  
--			  filter_protocol_in <= (others => '0');
--			  filter_src_ip_in <= (others => '0');
--			  filter_dst_ip_in <= (others => '0');
--			  filter_src_port_in <= (others => '0');
--			  filter_dst_port_in <= (others => '0');
--			  filter_ip <= '0';
--			  filter_tcp <= '0';

         else 
------------------------------------------------------------------           
-- PLB/ORB bus multiplexer section
------------------------------------------------------------------           
           rec_hard_orb_en <= '0';
--           hrd_orb_wr_xbuf_en <= '0';

         
           rx_done_SW <= '0';
           if ( rec_hard_orb_en = '0' ) then
              rx_done_SW <= rx_done;
           end if;
           
           OrbCmd_clr_rx_stats <= rx_done; -- Todo: OS or HArd_ORB???


------------------------------------------------------------------           
-- MAC layer RX SPY section
------------------------------------------------------------------           
           if ( rx_DPM_adr = x"000" ) then 
              rx_DPM_wr_data_new_byte_toggle <= '0';
           end if;

           if ( rx_ping_ce = '1' and rx_DPM_wr_rd_n = '1' ) then
              rx_DPM_wr_data_byte <= rx_DPM_wr_data & rx_DPM_wr_data_byte(0 to 3);
              rx_DPM_wr_data_byte_d0 <= rx_DPM_wr_data_byte;
              rx_DPM_wr_data_byte_d1 <= rx_DPM_wr_data_byte_d0;
              rx_DPM_wr_data_new_byte_toggle <= not rx_DPM_wr_data_new_byte_toggle;
           end if;

------------------------------------------------------------------           
-- DPRAM write en signal section
------------------------------------------------------------------           
           if ( eth_xmit_state_cnt /= x"0" or eth_xmit_state_cnt /= x"F" or arpxmit_wrRAM = '1' or ipxmit_wrRAM = '1' or icmprply_wrRAM = '1' ) then
              tx_DPM_wr_ORB(0) <= '1';
              tx_DPM_wr_ARP(0) <= '1';
           else
              tx_DPM_wr_ORB(0) <= '0';
              tx_DPM_wr_ARP(0) <= '0';
           end if;

------------------------------------------------------------------           
-- Ethernet layer TX section
------------------------------------------------------------------           
           OrbCmd_start_tx <= '0';
           
           tx_done_SW <= '0';

           if ( tx_done_MAC = '1' ) then   
              hrd_orb_wr_xbuf_en <= '0';
              if ( hrd_orb_wr_xbuf_en = '0' ) then   
                 tx_done_SW <= '1';
              end if;
           end if;

  				 transmit_start_prev <= transmit_start;
           case eth_xmit_state_cnt(3 downto 0) is
						when x"0" =>
              tx_DPM_adr_ORB <= "111" & x"11";
              tx_DPM_wr_data_ORB  <= x"00";
              tx_DPM_adr_ARP <= "111" & x"11";
              tx_DPM_wr_data_ARP  <= x"00";
              
              if ( arpxmit_genFrame = '1' ) then 
                 eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
                 tx_packet_len_SW <= ("00000" & arpxmit_frameSize);
              end if;
            -- Destination MAC address  -----------------------------
						when x"1" =>
              tx_DPM_adr_ORB <= "000" & x"00";
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (47 downto 40);
              tx_DPM_adr_ARP <= "000" & x"00";
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (47 downto 40);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"2" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (39 downto 32);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (39 downto 32);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"3" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (31 downto 24);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (31 downto 24);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"4" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (23 downto 16);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (23 downto 16);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"5" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (15 downto 8);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (15 downto 8);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"6" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= arpxmit_targetMAC (7 downto 0);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= arpxmit_targetMAC (7 downto 0);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
            -- Source MAC address  -----------------------------
						when x"7" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (47 downto 40);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (47 downto 40);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"8" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (39 downto 32);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (39 downto 32);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"9" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (31 downto 24);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (31 downto 24);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"A" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (23 downto 16);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (23 downto 16);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"B" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (15 downto 8);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (15 downto 8);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"C" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= DEVICE_MAC (7 downto 0);
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= DEVICE_MAC (7 downto 0);
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"D" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_wr_data_ORB  <= x"08"; 
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              tx_DPM_wr_data_ARP  <= x"08"; 
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
            -- Type: IP (0x0800)  -----------------------------
						when x"E" =>
              tx_DPM_adr_ORB <= tx_DPM_adr_ORB + 1;
              tx_DPM_adr_ARP <= tx_DPM_adr_ARP + 1;
              if ( arpxmit_frameType = '0' ) then
                 tx_DPM_wr_data_ORB  <= x"06";-- ARP
                 tx_DPM_wr_data_ARP  <= x"06";-- ARP
              else
                 tx_DPM_wr_data_ORB  <= x"00";-- IP
                 tx_DPM_wr_data_ARP  <= x"00";-- IP
              end if;
              eth_xmit_state_cnt <= eth_xmit_state_cnt + 1;
						when x"F" =>
              if ( transmit_start = '0' and transmit_start_prev = '1' ) then
                eth_xmit_state_cnt <= x"0";
              elsif ( transmit_start = '0' ) then
                OrbCmd_start_tx <= '1'; -- Todo: it must be activated only when Hard_ORB should reply!
                hrd_orb_wr_xbuf_en <= '1';  -- Todo: it must be activated only when Hard_ORB should reply!
              else  
                eth_xmit_state_cnt <= x"F";
              end if;
	 					when others =>
              eth_xmit_state_cnt <= x"0";
					 end case;

------------------------------------------------------------------           
-- ARP layer RX section
------------------------------------------------------------------           
           arpiprec_frameType <= '1';
           arpiprec_newFrame <= '0';

           if ( rx_done = '1' ) then
             triger_signal_clnt <= '0';
--             triger_signal <= '0';
           end if;  
           
           if ( rx_DPM_adr = x"01C" and rx_DPM_wr_data_byte_d1 = x"08" and rx_DPM_wr_data_new_byte_d1 = '1' ) then -- 0x01A = 26
              triger_signal_clnt <= tcp_RcvOvrHd_TrigSg;
--              triger_signal <= tcp_RcvOvrHd_TrigSg;
           
              if rx_DPM_wr_data_byte = x"06"  then
                arpiprec_frameType <= '0'; -- ARP
                arpiprec_newFrame <= '1';
              elsif ( rx_DPM_wr_data_byte = x"00" ) then -- 0x01A = 26
                arpiprec_frameType <= '1'; -- IP
                arpiprec_newFrame <= '1';
              end if;
           end if;

           arprec_framevalid <= '0';
--           arprec_endframe <= '0';
--           iprec_endframe_d1 <= iprec_endframe;

           if ( rx_done = '1' and rx_DPM_wr_rd_n = '0' ) then
              arprec_framevalid <= '1';
           end if;

--           if ( arpiprec_newFrame = '1' and rx_DPM_wr_rd_n = '0' ) then
--              arprec_endframe <= '1';
--              OrbCmd_clr_rx_stats <= '1'; -- Todo: OS or HArd_ORB???
--           end if;
------------------------------------------------------------------           
-- ARP layer TX section
------------------------------------------------------------------           
--           arpxmit_frameSent <= arpxmit_sendFrame;
           arpxmit_frameSent <= '0';
           if ( tx_done_MAC = '1' ) then -- Todo: is it from hard ORB?
              arpxmit_frameSent <= '1';
              arp_en <= '0';
           end if;

           if ( arpxmit_wrRAM = '1' ) then
--              tx_DPM_adr_ORB <= arpxmit_wrAddr(10 downto 0); -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_adr_ARP <= "000" & arpxmit_wrAddr; -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_wr_data_ARP  <= arpxmit_wrData;
              arp_en <= '1';
           end if;

           arpxmit_complete <= arpxmit_wrRAM;

------------------------------------------------------------------           
-- IP layer RX section
------------------------------------------------------------------           
--           OrbCmd_clr_rx_stats <= '0';
--           arpiprec_frameType <= '0';
--           arpiprec_newFrame <= '0';

--           if ( rx_DPM_adr = x"01C" and rx_DPM_wr_data_byte_d1 = x"08" and rx_DPM_wr_data_byte = x"00" and rx_DPM_wr_data_new_byte_d1 = '1' ) then -- 0x01A = 26
--              arpiprec_frameType <= '1'; -- IP
--              arpiprec_newFrame <= '1';
--           end if;
           
--           iprec_framevalid <= '0';
--           iprec_endframe <= '0';
--           iprec_endframe_d1 <= iprec_endframe;

--           if ( rx_done = '1' and rx_DPM_wr_rd_n = '0' ) then
--              iprec_framevalid <= '1';
--           end if;

--           if ( arpiprec_newFrame = '1' and rx_DPM_wr_rd_n = '0' ) then
--              iprec_endframe <= '1';
--              OrbCmd_clr_rx_stats <= '1'; -- Todo: OS or HArd_ORB???
--           end if;

           rx_DPM_wr_data_new_byte_d1 <= rx_DPM_wr_data_new_byte;
--           if ( rx_DPM_wr_data_new_byte = '1' ) then
--              rx_DPM_wr_data_byte_d1 <= rx_DPM_wr_data_byte;
--           end if;

--           iprec_complete <= iprec_wrRAM;

------------------------------------------------------------------           
-- IP layer TX section
------------------------------------------------------------------           
           ipxmit_frameSent <= ipxmit_sendFrame;

           if ( ipxmit_wrRAM = '1' ) then
--              tx_DPM_adr_ORB <= ipxmit_wrAddr(10 downto 0); -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_adr_ORB <= "000" & ipxmit_wrAddr; -- Todo: size of ipxmit_wrAddr is high!
              tx_DPM_wr_data_ORB  <= ipxmit_wrData;
           end if;

           ipxmit_complete <= ipxmit_wrRAM;

------------------------------------------------------------------           
-- ICMP layer Reply section
------------------------------------------------------------------           
					 icmprply_wrRAM_cmplt <= '0';
           if ( icmprply_wrRAM = '1' ) then
              tx_DPM_adr_ORB <= "000" & icmprply_wrAddr;
              tx_DPM_wr_data_ORB  <= icmprply_wrData;
              icmprply_wrRAM_cmplt <= '1';
           end if;
------------------------------------------------------------------           
-- TCP layer handler section
------------------------------------------------------------------           

--			  if (tcphndl_wrTCPData_en = "1") then
--				  mem_tcp_data_wr_en <= tcphndl_wrTCPData_en;
--              mem_tcp_data_wr_data <= tcphndl_wrTCPData;
--              mem_tcp_data_wr_addr  <= tcphndl_wrTCPData_addr;
--           end if;
			  
			  tcphndl_wrRAM_cmplt <= '0';
           if ( tcphndl_wrRAM = '1' ) then
              tx_DPM_adr_ORB <= tcphndl_wrAddr;
              tx_DPM_wr_data_ORB  <= tcphndl_wrData;
              tcphndl_wrRAM_cmplt <= '1';
           end if;
			  
           
--					 tcphndl_rdRAM_cmplt <= '0';

--           if ( tcphndl_rdRAM = '1' ) then
----              tx_DPM_adr_ORB <= tcphndl_rdAddr(10 downto 0); -- Todo: size of tcphndl_wrAddr is high!
--              tcphndl_rdDataMem  <= FIFORD_DATA_OUT;
--				  if (tcp_data_toggle = '0') then 
--                tcphndl_rdDataMem  <= x"AA";
--              else
--                tcphndl_rdDataMem  <= x"55";
--              end if;
--              tcp_data_toggle <= not tcp_data_toggle;
--              tcphndl_rdRAM_cmplt <= '1';
--           end if;
           
------------------------------------------------------------------           
           
         end if;
       end if;
     end process PROTCL_STACK_HNDLR;
end generate;

   ----------------------------------------------------------------------------
   -- TX DPRAM Multiplexer process
   ----------------------------------------------------------------------------
   DPRAM_TX_MUX: process (hrd_orb_wr_xbuf_en, tx_ping_rd_data_ORB, tx_ping_rd_data_MAC, arp_en, tx_ping_rd_data_ARP)
     begin
           if ( hrd_orb_wr_xbuf_en = '1' and arp_en = '0' ) then
              tx_ping_rd_data_SW <= tx_ping_rd_data_ORB;
           elsif ( hrd_orb_wr_xbuf_en = '1' and arp_en = '1' ) then
              tx_ping_rd_data_SW <= tx_ping_rd_data_ARP;
           else
              tx_ping_rd_data_SW <= tx_ping_rd_data_MAC;
           end if;
     
     end process DPRAM_TX_MUX;
   
     rx_DPM_wr_data_new_byte <= rx_DPM_wr_data_new_byte_toggle and rx_DPM_wr_rd_n and rx_ping_ce;
	  
--	  mem_tcp_data_rd_addr <= filter_rd_tcp_data_addr;
	  
	  --filter
	  filter_protocol_in <= iprec_protocol; --Adil
	  filter_src_ip_in <= iprec_sourceIP; --Adil
	  filter_dst_ip_in <= iprec_destIP; --Adil
	  filter_src_port_in <= tcphndl_srcport; --Adil
	  filter_dst_port_in <= tcphndl_dstport; --Adil
--	  filter_virus_detect_in <= tcphndl_virus_detect; --Adil
	  filter_TCPdataLen <= tcphndl_TCPdataLen; --Adil
	  filter_TCPdata <= tcphndl_TCPdata; --Adil
	  filter_TCPdataValid <= tcphndl_TCPdataValid; --Adil
	  filter_nbTCPDataByteRec <= tcphndl_nbTCPDataByteRec; --Adil
	  filter_TCPdataCompletelyRcvd <= tcphndl_TCPdataCompletelyRcvd; --Adil
	  filter_newTCPMessage <= tcphndl_newTCPMessage; --Adil
	  filter_newByteRecv <= tcphndl_newByteRecv; --Adil
	  	  
     
ICMP_CONECT: if C_ICMP_MODE = 1 generate
     -- ICMP
     icmprply_newDatagram <= iprec_newDatagram;
     icmprply_datagramSize <= iprec_datagramSize;
     icmprply_protocolIn <= iprec_protocol;
     icmprply_sourceIP <= iprec_sourceIP;
	  icmprply_filter <= filter_ip; --Adil

     icmprply_rdData <= rx_DPM_wr_data_byte;
     icmprply_complete  <=  rx_DPM_wr_data_new_byte_d1 or icmprply_wrRAM_cmplt;
end generate;

     -- TCP
     tcphndl_newDatagram <= iprec_newDatagram;
     tcphndl_datagramSize <= iprec_datagramSize;
     tcphndl_protocolIn <= iprec_protocol;
     tcphndl_sourceIP <= iprec_sourceIP;
	  tcphndl_filter_ip <= filter_ip; --Adil
	  tcphndl_filter_port <= filter_tcp; --Adil

     tcphndl_rdData <= rx_DPM_wr_data_byte;
--     tcphndl_complete <= rx_DPM_wr_data_new_byte_d1 or tcphndl_wrRAM_cmplt;
--     tcphndl_complete <= tcphndl_wrRAM_cmplt or tcphndl_rdRAM_cmplt;
     tcphndl_recNewByte <= rx_DPM_wr_data_new_byte_d1;

ICMPTCP_MULTIPEXR: if C_ICMP_MODE = 1 generate
   ----------------------------------------------------------------------------
   -- Transmit layer (ICMP & TCP) Multiplexer process
   ----------------------------------------------------------------------------
   TRANS_LAYER_MUX: process (iprec_protocol, icmprply_sendDatagramSize, icmprply_destinationIP, 
   icmprply_protocolOut, icmprply_sendDatagram, tcphndl_sendDatagramSize, tcphndl_destinationIP, 
   tcphndl_protocolOut, tcphndl_sendDatagram)
     begin
--           if ( iprec_protocol = x"01" ) then -- Todo: which protocol??? ICMP or TCP or UDP???
--              ipxmit_datagramSize <= icmprply_sendDatagramSize; 
--              ipxmit_destinationIP <= icmprply_destinationIP; 
--              ipxmit_protocol <= icmprply_protocolOut; 
--              ipxmit_sendDatagram <= icmprply_sendDatagram;
--           else
--              ipxmit_datagramSize <= tcphndl_sendDatagramSize; 
--              ipxmit_destinationIP <= tcphndl_destinationIP; 
--              ipxmit_protocol <= tcphndl_protocolOut; 
--              ipxmit_sendDatagram <= tcphndl_sendDatagram;
--           end if;

           if ( icmprply_sendDatagram = '1' ) then -- Todo: which protocol??? ICMP or TCP or UDP???
              ipxmit_datagramSize <= icmprply_sendDatagramSize; 
              ipxmit_destinationIP <= icmprply_destinationIP; 
              ipxmit_protocol <= icmprply_protocolOut; 
              ipxmit_sendDatagram <= '1';
           elsif ( tcphndl_sendDatagram = '1' ) then
              ipxmit_datagramSize <= tcphndl_sendDatagramSize; 
              ipxmit_destinationIP <= tcphndl_destinationIP; 
              ipxmit_protocol <= tcphndl_protocolOut; 
              ipxmit_sendDatagram <= '1';
           else
              ipxmit_datagramSize <= ipxmit_datagramSize; 
              ipxmit_destinationIP <= ipxmit_destinationIP; 
              ipxmit_protocol <= ipxmit_protocol; 
              ipxmit_sendDatagram <= '0';
           end if;
     
     end process TRANS_LAYER_MUX;
end generate;

TCP_MULTIPEXR: if C_ICMP_MODE = 0 generate
   ----------------------------------------------------------------------------
   -- Transmit layer (only TCP) without Multiplexer 
   ----------------------------------------------------------------------------
   ipxmit_datagramSize <= tcphndl_sendDatagramSize; 
   ipxmit_destinationIP <= tcphndl_destinationIP; 
   ipxmit_protocol <= tcphndl_protocolOut; 
   ipxmit_sendDatagram <= tcphndl_sendDatagram;
end generate;

   -- ARP
   arpxmit_genARPIP <= arprec_genARPIP;
   arpxmit_genARPReply <= arprec_genARPRep;
   arpxmit_sendFrame <= ipxmit_sendFrame;
   arpxmit_lookupMAC <= arprec_lookupMAC;
   arpxmit_ARPEntryValid <= arprec_validEntry;
   arprec_requestIP <= arpxmit_lookupIP;
   arpxmit_targetIP <= ipxmit_ARPIP; 
   arprec_ARPSendAvail <= arpxmit_sendingReply;
   arpxmit_frameLen <= ipxmit_frameSize (10 downto 0);

   ----------------------------------------------------------------------------
   -- DDR Memory data request handler process
   ----------------------------------------------------------------------------
   USER_RD_RST <= tcphndl_mpmc_reset;

   tcphndl_rdDataMem  <= FIFORD_DATA_OUT;

   MPMC_DREQ_HNDLR: process (Clk)
     begin
       if Clk'event and Clk = '1' then
         if Rst = '1' then
           mpmc_rd_dreq_state_cnt <= (others => '0');
           USER_RD_DREQ <= '0';
           DMA_RD_DACK_D1 <= '0';
			  
   			   USER_READ <= '1';
			     tcphndl_rdRAM_cmplt <= '0';
         else

           USER_READ <= '0';
			     tcphndl_rdRAM_cmplt <= '0';
			     if (tcphndl_rdRAM = '1' and USER_RD_DRDY = '1') then
--			  if ( tcphndl_rdRAM = '1' ) then
              tcphndl_rdRAM_cmplt <= '1';
			        USER_READ <= '1';
           end if;

           DMA_RD_DACK_D1 <= DMA_RD_DACK;
           USER_RD_DREQ <= '0';
           case mpmc_rd_dreq_state_cnt is
				    when "00" =>
--              if tst_user_dreq = '1' or tcphndl_mpmc_dreq = '1' then 
              if tcphndl_mpmc_dreq = '1' then 
                mpmc_rd_dreq_state_cnt <= "01";
              else
                mpmc_rd_dreq_state_cnt <= "00";
              end if;
				    when "01" =>
              if conv_integer(FIFORD_WR_COUNT) < ((C_FIFO_DEPTH-C_NPI_BURST_SIZE)/4) then
                if DMA_RD_BURST_END = '1' then
                  mpmc_rd_dreq_state_cnt <= "00";
                else
                  mpmc_rd_dreq_state_cnt <= "10";
                end if;
                USER_RD_DREQ <= '1';
              else
                mpmc_rd_dreq_state_cnt <= "01";
              end if;
						when "10" =>
              if (DMA_RD_DACK = '0' and DMA_RD_DACK_D1 = '1') then
                mpmc_rd_dreq_state_cnt <= "01";
              else
                mpmc_rd_dreq_state_cnt <= "10";
              end if;
	 			    when others =>
              mpmc_rd_dreq_state_cnt <= "00";
				   end case;

         end if;  
       end if;  
     end process MPMC_DREQ_HNDLR;

end Behavioral;

