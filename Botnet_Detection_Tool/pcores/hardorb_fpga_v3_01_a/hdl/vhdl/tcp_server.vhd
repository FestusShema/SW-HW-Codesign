-------------------------------------------------------------------------------
-- TCPServer.vhd
--
-- Author(s):     Ali Akbar Zarezadeh (akzare)
-- (University of Potsdam, Computer Science Department)
-- HardORB FPGA project
-- Created:       Dec 2009
-- Last Modified: Feb 2010
-- 
-- Transmission Control Protocol layer which responds only to TCP requests 
-- with an individual specified Dst port number with a required reply (TCP state diagram).  
-- Any other TCP messages are discarded / ignored.  
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity TCPServer is
  generic (
    C_DEBUG_MODE        : integer := 0;	-- 0 = disable, 1 = enable
    DEVICE_IP           : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a";
    DEVICE_TCP_PAYLOAD  : STD_LOGIC_VECTOR (15 downto 0) := x"0400"; -- 1024-byte payload
    DEVICE_TCP_PORT     : STD_LOGIC_VECTOR (15 downto 0) := x"E28C"
    );                
    port (
    clk                 : in STD_LOGIC;										-- clock
    rstn                : in STD_LOGIC;										-- asynchronous active low reset

    newDatagram         : in STD_LOGIC;								-- asserted when a new datagram arrive
    datagramSize        : in STD_LOGIC_VECTOR (15 downto 0);		-- size of the arrived datagram
    protocolIn          : in STD_LOGIC_VECTOR (7 downto 0);			-- protocol type of the datagram
    sourceIP            : in STD_LOGIC_VECTOR (31 downto 0);			-- IP address that sent the message
    wr_complete         : in STD_LOGIC;									-- asserted when then DPMEM write operation is complete
    rd_complete         : in STD_LOGIC;									-- asserted when then DDRMEM write operation is complete
    recNewByte          : in STD_LOGIC;									-- asserted when then RX new byte SPY section operation is complete
    rdData              : in STD_LOGIC_VECTOR (7 downto 0);				-- read data bus from the RAM
    rdDataMem           : in STD_LOGIC_VECTOR (7 downto 0);	-- read data bus from the DDR MEM
    tx_done_MAC         : in STD_LOGIC;
    rx_done_MAC         : in STD_LOGIC;
	 filter_ip_addr: in STD_LOGIC;				-- Adil : signal indicating if the packet is allowed to be processed
	 filter_port: in STD_LOGIC;					-- Adil : signal indicating if the packet is allowed to be processed
    rdRAM               : out STD_LOGIC;									-- asserted to tell the RAM to read
    mpmc_dreq           : out STD_LOGIC;
    mpmc_reset          : out STD_LOGIC;
    wrRAM               : out STD_LOGIC;									-- asserted to tell the RAM to write
    wrData              : buffer STD_LOGIC_VECTOR (7 downto 0);			-- write data bus to the RAM
--        wrAddr: out STD_LOGIC_VECTOR (18 downto 0);				-- write address bus to the RAM
    wrAddr              : out STD_LOGIC_VECTOR (10 downto 0);				-- write address bus to the RAM
    sendDatagramSize    : out STD_LOGIC_VECTOR (15 downto 0);	-- size of the ping to reply to
    sendDatagram        : out STD_LOGIC;							-- tells the IP layer to send a datagram
    destinationIP       : buffer STD_LOGIC_VECTOR (31 downto 0);		-- target IP of the datagram
	 src_port_rec			: out STD_LOGIC_VECTOR (15 downto 0);	-- source port of the incoming packets --Adil
	 dst_port_rec			: out STD_LOGIC_VECTOR (15 downto 0);  -- destination port of the incoming packets --Adil
------------------------ TEST -------------------    
tst_tcpcmpltRec: out STD_LOGIC;
tst_tcpnewByteRec: out STD_LOGIC;
tst_tcpinByteRec: out STD_LOGIC_VECTOR (7 downto 0);
tst_tcpbusyXmit: out STD_LOGIC;
tst_tcpsendTCP: out STD_LOGIC;
tst_tcppresstateRec: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcppresstateXmit: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcppresstateSrv: out STD_LOGIC_VECTOR (3 downto 0);
tst_tcprx_done: out STD_LOGIC;
------------------------ TEST -------------------    
    sndOvrhd_trigSg     : out STD_LOGIC;
	 TCPdataLen				: out STD_LOGIC_VECTOR (15 downto 0); --Adil: indicate to the filter the TCP payload length
	 TCPdata 				: out STD_LOGIC_VECTOR (7 downto 0); --Adil: TCP data
	 TCPdataValid			: out STD_LOGIC; --Adil: indicate if the TCP data is valid
	 TCPdataCompletelyRcvd	: out STD_LOGIC; --Adil: indicate if the TCP data has been completely received
	 nbTCPDataByteRec		: out STD_LOGIC_VECTOR (15 downto 0); --Adil: indicate the number of data currently rcvd
	 newTCPMessage			: out STD_LOGIC; --Adil: indicate to the filter that a new Datagram arrived from the IP layer
	 newByteRecv			: out STD_LOGIC; --Adil: indicate to the filter that a new Byte have been received
    protocolOut         : out STD_LOGIC_VECTOR (7 downto 0)			-- tells the IP layer which protocol it is
    );
end TCPServer;

architecture tcp_arch of TCPServer is

-- Server Timeout Counters
constant TIMERWIDTHSrv : INTEGER := 30;							-- can be used to vary timeout length
signal timout0Srv: STD_LOGIC_VECTOR (TIMERWIDTHSrv - 1  downto 0);	-- timeout counter
signal rstTimoutSrv: STD_LOGIC;		-- start timeout counter
constant FULTIMSrv: STD_LOGIC_VECTOR (TIMERWIDTHSrv - 1 downto 0) := (others => '1'); -- last value of timeout counter

-- Receiver Timeout Counters
constant TIMERWIDTHRec : INTEGER := 9;							-- can be used to vary timeout length
signal timout0Rec: STD_LOGIC_VECTOR (TIMERWIDTHRec - 1  downto 0);	-- timeout counter
signal rstTimoutRec: STD_LOGIC;		-- start timeout counter
constant FULTIMRec: STD_LOGIC_VECTOR (TIMERWIDTHRec - 1 downto 0) := (others => '1'); -- last value of timeout counter

-- TCP receive state definitions
--type STATETYPE_REC is (stIdleRec, stGetTCPByteRec, stSetupWriteTCPByteRec, stWriteTCPByteRec,
--		stWriteChkSum1, stWriteChkSum2, stWaitForCheckSum, stWaitForCheckSumCalc);
type STATETYPE_REC is (stIdleRec, stGetTCPByteRec, stSetupWriteTCPByteRec, stWriteTCPByteRec, stWaitFinRec,
    stSetPseudoHeadRec, stWrPseudoHeadRec,
		stWriteChkSum1Rec, stWriteChkSum2Rec, stWaitForCheckSumRec, stWaitForCheckSumCalcRec);
signal prsStateRec: STATETYPE_REC;
signal nxtStateRec: STATETYPE_REC;

-- buffer to hold the size of the TCP message received 
signal TCPSizeRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtTCPSizeRec: STD_LOGIC_VECTOR (15 downto 0);

-- counter to handle the message
signal incCntRec: STD_LOGIC;
signal rstCntRec: STD_LOGIC;
signal cntRec: STD_LOGIC_VECTOR (15 downto 0);
signal incCntOptRec: STD_LOGIC;
signal rstCntOptRec: STD_LOGIC;
signal CntOptRec: STD_LOGIC_VECTOR (7 downto 0);

-- signal and buffer to latch and hold the data from RAM
signal rdLatch: STD_LOGIC_VECTOR (7 downto 0);
signal latchRdData: STD_LOGIC;

-- signal and buffer to latch and hold the data from DDR RAM
signal rdLatchMem: STD_LOGIC_VECTOR (7 downto 0);
signal latchRdDataXmit: STD_LOGIC;

-- signal to remember the previous wrData value
signal nextWrData: STD_LOGIC_VECTOR (7 downto 0);

-- signal to latch the inputs from the previous layer
signal latchDestinationIP: STD_LOGIC;

-- checksum Rec signals - read internet.vhd for checksum Rec commenting
signal chkStateRec : STD_LOGIC;
CONSTANT stMSB : STD_LOGIC := '0';
CONSTANT stLSB : STD_LOGIC := '1';
signal chksmLongRec : STD_LOGIC_VECTOR (16 downto 0);
signal chksmIntRec : STD_LOGIC_VECTOR (15 downto 0);
signal latchMSBRec : STD_LOGIC_VECTOR (7 downto 0);
signal newHeaderRec: STD_LOGIC;
signal newByteRec: STD_LOGIC;
signal inByteRec: STD_LOGIC_VECTOR (7 downto 0);
signal chksmCalRec: STD_LOGIC_VECTOR (15 downto 0);
signal validRec: STD_LOGIC;

signal incCntPsdoHdRec: STD_LOGIC;
signal rstCntPsdoHdRec: STD_LOGIC;
signal cntPsdoHdRec: STD_LOGIC_VECTOR (3 downto 0);

-- latch the source and destination ports, for use later in TCP state diagram
signal srcPrtRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtSrcPrtRec: STD_LOGIC_VECTOR (15 downto 0);
signal dstPrtRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtDstPrtRec: STD_LOGIC_VECTOR (15 downto 0);
signal seqNumRec: STD_LOGIC_VECTOR (31 downto 0);
signal nxtSeqNumRec: STD_LOGIC_VECTOR (31 downto 0);
signal ackNumRec: STD_LOGIC_VECTOR (31 downto 0);
signal nxtAckNumRec: STD_LOGIC_VECTOR (31 downto 0);
signal headLenRec: STD_LOGIC_VECTOR (7 downto 0);
signal nxtHeadLenRec: STD_LOGIC_VECTOR (7 downto 0);
signal headLenSaveRec: STD_LOGIC_VECTOR (3 downto 0);
signal nxtHeadLenSaveRec: STD_LOGIC_VECTOR (3 downto 0);
signal flagsRec: STD_LOGIC_VECTOR (7 downto 0);
signal nxtFlagsRec: STD_LOGIC_VECTOR (7 downto 0);
signal winSizeRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtWinSizeRec: STD_LOGIC_VECTOR (15 downto 0);
signal chkSumRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtChkSumRec: STD_LOGIC_VECTOR (15 downto 0);
signal incoming_data : std_logic_vector (7 downto 0);
signal nxtincoming_data : std_logic_vector (7 downto 0);
signal nbTCPdataByteRecd : std_logic_vector(15 downto 0);


signal optLenRec: STD_LOGIC_VECTOR (7 downto 0);
signal nxtOptLenRec: STD_LOGIC_VECTOR (7 downto 0);
type OPTIONTYPE_REC is (optNon, optNOP, optMaxSegSize, optSACKPermitted, optTimeStamp, optWinScle);
signal optTypRec: OPTIONTYPE_REC;
signal nxtOptTypRec: OPTIONTYPE_REC;

signal maxSegSizeRec: STD_LOGIC_VECTOR (15 downto 0);
signal nxtMaxSegSizeRec: STD_LOGIC_VECTOR (15 downto 0);
signal tsValRec: STD_LOGIC_VECTOR (31 downto 0);
signal nxtTsValRec: STD_LOGIC_VECTOR (31 downto 0);
signal tsEcrRec: STD_LOGIC_VECTOR (31 downto 0);
signal nxtTsEcrRec: STD_LOGIC_VECTOR (31 downto 0);
signal sAckPermitRec: STD_LOGIC;
signal nxtSAckPermitRec: STD_LOGIC;
signal winScaleRec: STD_LOGIC_VECTOR (7 downto 0);
signal nxtWinScaleRec: STD_LOGIC_VECTOR (7 downto 0);

signal nxtCmpltRec: STD_LOGIC;
signal cmpltRec: STD_LOGIC;
 
-- TCP Server state definitions
type STATETYPE_SRV is (stIdleSrv, stWait4SYNSrv, stRplySYNACKSrv, stWait4SYNACKACKSrv, stWait4GIOPReqSrv, 
    stRplyGIOPReqACKSrv, stWaitXmitFinSrv, stXmitGIOPRplySrv, stWait4XmitGIOPRplyACKSrv, stWait4FINACKSrv, 
    stRplyFINACKSrv, stWait4ACKSrv);
signal prsStateSrv: STATETYPE_SRV;
signal nxtStateSrv: STATETYPE_SRV;
signal retStateSrv: STATETYPE_SRV;

signal sendTCP: STD_LOGIC;
signal nxtSendTCP: STD_LOGIC;

signal mpmcRst: STD_LOGIC; 
signal nxtMpmcRst: STD_LOGIC;

signal sndOvrhdTrigSg: STD_LOGIC; 
signal nxtSndOvrhdTrigSg: STD_LOGIC; 

signal goWaitSrv: STD_LOGIC;
signal int_mpmc_dreq: STD_LOGIC;

-- TCP transmit state definitions
type STATETYPE_XMIT is (stIdleXmit, stSetHeaderXmit, stWrHeaderXmit, stGetDataXmit, stWrDataXmit, 
    stSetPseudoHeadXmit, stWrPseudoHeadXmit, stWriteChkSum1Xmit, stWriteChkSum2Xmit, stWaitForCheckSumXmit, 
    stWaitForCheckSumCalcXmit, stWriteFinishXmit);
signal prsStateXmit: STATETYPE_XMIT;
signal nxtStateXmit: STATETYPE_XMIT;

-- checksum Xmit signals - read internet.vhd for checksum Xmit commenting
signal chkStateXmit : STD_LOGIC;
--CONSTANT stMSB : STD_LOGIC := '0';
--CONSTANT stLSB : STD_LOGIC := '1';
signal chksmLongXmit : STD_LOGIC_VECTOR (16 downto 0);
signal chksmIntXmit : STD_LOGIC_VECTOR (15 downto 0);
signal latchMSBXmit : STD_LOGIC_VECTOR (7 downto 0);
signal newHeaderXmit: STD_LOGIC;
signal newByteXmit: STD_LOGIC;
signal inByteXmit: STD_LOGIC_VECTOR (7 downto 0);
signal chksmXmit: STD_LOGIC_VECTOR (15 downto 0);
signal validXmit: STD_LOGIC;

-- buffer to hold the size of the TCP message transmit 
signal TCPSizeXmit: STD_LOGIC_VECTOR (15 downto 0);
signal nxtTCPSizeXmit: STD_LOGIC_VECTOR (15 downto 0);

signal busyXmit: STD_LOGIC;
signal nxtBusyXmit: STD_LOGIC;

signal incCntXmit: STD_LOGIC;
signal rstCntXmit: STD_LOGIC;
signal cntXmit: STD_LOGIC_VECTOR (15 downto 0);

signal incCntPsdoHdXmit: STD_LOGIC;
signal rstCntPsdoHdXmit: STD_LOGIC;
signal cntPsdoHdXmit: STD_LOGIC_VECTOR (3 downto 0);

signal seqNumXmit: STD_LOGIC_VECTOR (31 downto 0);
signal nxtSeqNumXmit: STD_LOGIC_VECTOR (31 downto 0);
signal ackNumXmit: STD_LOGIC_VECTOR (31 downto 0);  
signal nxtAckNumXmit: STD_LOGIC_VECTOR (31 downto 0);
signal headLenXmit: STD_LOGIC_VECTOR (7 downto 0);
signal nxtHeadLenXmit: STD_LOGIC_VECTOR (7 downto 0);
signal flagsXmit: STD_LOGIC_VECTOR (7 downto 0);
signal nxtFlagsXmit: STD_LOGIC_VECTOR (7 downto 0);
signal winSizeXmit: STD_LOGIC_VECTOR (15 downto 0);
signal nxtWinSizeXmit: STD_LOGIC_VECTOR (15 downto 0);

signal tsValXmit: STD_LOGIC_VECTOR (31 downto 0);
signal nxtTsValXmit: STD_LOGIC_VECTOR (31 downto 0);
signal tsEcrXmit: STD_LOGIC_VECTOR (31 downto 0);
signal nxtTsEcrXmit: STD_LOGIC_VECTOR (31 downto 0);

signal incCntRplyXmit: STD_LOGIC;
signal rstCntRplyXmit: STD_LOGIC;
signal cntXmitRply: STD_LOGIC_VECTOR (3 downto 0);

signal tcpDLenPrvXmit: STD_LOGIC_VECTOR (15 downto 0);
signal nxtTcpDLenPrvXmit: STD_LOGIC_VECTOR (15 downto 0);

-- GIOP 1.2 definitions
constant MAGIC_NUM_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"47494F50"; -- GIOP Magic Number
constant VER_GIOP : STD_LOGIC_VECTOR (15 downto 0) := x"0102"; -- version 1.2
constant FLAG_LIT_END_GIOP : STD_LOGIC_VECTOR (7 downto 0) := x"01"; -- Little-endian
constant MSG_TYP_REQ_GIOP : STD_LOGIC_VECTOR (7 downto 0) := x"00"; -- GIOP Request
constant MSG_TYP_REP_GIOP : STD_LOGIC_VECTOR (7 downto 0) := x"01"; -- GIOP Reply
constant MSG_SIZE_REQ_SHORT_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"54000000"; -- Test: op=get_short Request
constant MSG_SIZE_REQ_SHORTSEQ_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"58000000"; -- Test: op=get_shortseq Request
constant REQ_ID_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"01000000"; -- Request ID
constant RESPONSE_FLAGS_GIOP : STD_LOGIC_VECTOR (7 downto 0) := x"03"; -- Response Flags (SYNC_WITH_TARGET)
constant RES_FLAGS_GIOP : STD_LOGIC_VECTOR (23 downto 0) := x"000000"; -- Reserve Flags
constant TARGET_ADDR_DISC_GIOP : STD_LOGIC_VECTOR (15 downto 0) := x"0000"; -- Target Address Discrimin
constant OBJ_KEX_LEN_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"1B000000"; -- Key Address (Obj KEY Len) 27
constant OBJ_KEX_GIOP : STD_LOGIC_VECTOR (215 downto 0) := x"14010f0052535448a0134b56d60900000000000100000001000000"; -- Key Address (Obj KEY)
constant OPR_LEN_REQ_SHORT_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"0a000000"; -- Operation Len 10
constant OPR_LEN_REQ_SHORTSEQ_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"0d000000"; -- Operation Len 13
constant REQ_OPR_REQ_SHORT_GIOP : STD_LOGIC_VECTOR (79 downto 0) := x"6765745f73686f727400"; -- Operation Len 10
constant REQ_OPR_REQ_SHORTSEQ_GIOP : STD_LOGIC_VECTOR (103 downto 0) := x"6765745f73686f727473657100"; -- Operation Len 13
constant SEQ_LEN_REQ_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"01000000"; -- Sequence Len request
constant SRV_CONTX_ID_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"01000000"; -- Service Context ID
constant ISO_8859_1_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"01000100"; -- char_data
constant ISO_UTF_16_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"09010100"; -- wchar_data

constant MSG_SIZE_REP_SHORTSEQ_GIOP_DUMMY : STD_LOGIC_VECTOR (15 downto 0) := (DEVICE_TCP_PAYLOAD + 16);
constant MSG_SIZE_REP_SHORTSEQ_GIOP : STD_LOGIC_VECTOR (31 downto 0) := (MSG_SIZE_REP_SHORTSEQ_GIOP_DUMMY (7 downto 0) & MSG_SIZE_REP_SHORTSEQ_GIOP_DUMMY (15 downto 8) & x"0000");
--constant MSG_SIZE_REP_SHORTSEQ_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"F8030000"; -- Test: op=get_shortseq Reply (1016)
constant REP_STATUS_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"00000000"; -- No exception
constant SEQ_LEN_REP_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"00000000"; -- Sequence Len request
constant REP_STUB_DATA_LEN_GIOP_DUMMY : STD_LOGIC_VECTOR (15 downto 0) := ("0" & DEVICE_TCP_PAYLOAD(15 downto 1));
constant REP_STUB_DATA_LEN_GIOP : STD_LOGIC_VECTOR (31 downto 0) := (REP_STUB_DATA_LEN_GIOP_DUMMY (7 downto 0) & REP_STUB_DATA_LEN_GIOP_DUMMY (15 downto 8) & x"0000");
--constant REP_STUB_DATA_LEN_GIOP : STD_LOGIC_VECTOR (31 downto 0) := x"F4010000"; -- Stub data length (500 short data)

signal isGIOP : STD_LOGIC; 
signal nxtIsGIOP : STD_LOGIC;

begin
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_tcpcmpltRec <= cmpltRec;
tst_tcpnewByteRec <= newByteRec;
tst_tcpinByteRec <= inByteRec;
tst_tcpbusyXmit <= busyXmit;
tst_tcpsendTCP <= sendTCP;

tst_tcppresstateRec <= conv_std_logic_vector(STATETYPE_REC'pos(prsStateRec), 4);
tst_tcppresstateXmit <= conv_std_logic_vector(STATETYPE_XMIT'pos(prsStateXmit), 4);
tst_tcppresstateSrv <= conv_std_logic_vector(STATETYPE_SRV'pos(prsStateSrv), 4);
tst_tcprx_done <= rx_done_MAC;
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_tcpcmpltRec <= '0';
tst_tcpnewByteRec <= '0';
tst_tcpinByteRec <= (others => '0');
tst_tcpbusyXmit <= '0';
tst_tcpsendTCP <= '0';

tst_tcppresstateRec <= (others => '0');
tst_tcppresstateXmit <= (others => '0');
tst_tcppresstateSrv <= (others => '0');
tst_tcprx_done <= '0';
end generate;
------------------------ TEST -------------------    
	-- always set the IP protocol field to tcp (06)
	protocolOut <= x"06";
  
  mpmc_reset <= mpmcRst;

  sndOvrhd_trigSg <= sndOvrhdTrigSg;
  
  newTCPMessage <= newDatagram; --Adil: indicate to the filter that a new datagram has been received
  
  newByteRecv <= recNewByte; --Adil: indicate to the filter that a new byte has been received
	
	-- main clocked process
	TCP_MAIN_CLK_PROC: process (rstn, clk)
	begin
		-- set up the asynchronous active low reset
		if rstn = '0' then
			timout0Srv <= FULTIMSrv;

			timout0Rec <= FULTIMRec;

      -- TCP Receive -------------------------------------------------------
			prsStateRec <= stIdleRec;
			cmpltRec <= '0';
      
      -- TCP transmit -------------------------------------------------------
			prsStateXmit <= stIdleXmit;
			busyXmit <= '0';
  
      -- TCP main handler ----------------------------------------------------
			prsStateSrv <= stIdleSrv;
			retStateSrv <= stIdleSrv;
			sendTCP <= '0';

      -- GIOP handler -------------------------------------------------------
			isGIOP <= '1';

		-- catch the rising clock edge
		elsif clk'event and clk = '1' then
			-- handle timeout counters, rstTimoutSrv will only reset the current buffer
			if rstTimoutSrv = '1' then
				timout0Srv <= (others => '0');
			else
				-- increment timeout counters but don't let them overflow
				if timout0Srv /= FULTIMSrv then
					timout0Srv <= timout0Srv + 1;
				else
					timout0Srv <= FULTIMSrv;
				end if;
			end if;

      -- TCP Receive -------------------------------------------------------
			prsStateRec <= nxtStateRec;
			-- remember the source port, destination port, and length
			srcPrtRec <= nxtSrcPrtRec; --Adil
			dstPrtRec <= nxtDstPrtRec; --Adil
			incoming_data <= nxtincoming_data; --Adil
			TCPdataLen <= nxtTCPSizeRec - (x"00" & ("00" & nxtHeadLenSaveRec & "00")); --Adil
			nbTCPDataByteRec <= nbTCPdataByteRecd; --Adil Tell the filter the number of TCP data byte received
			seqNumRec <= nxtSeqNumRec;
			ackNumRec <= nxtAckNumRec;
			headLenRec <= nxtHeadLenRec;
			headLenSaveRec <= nxtHeadLenSaveRec;
			flagsRec <= nxtFlagsRec;
			winSizeRec <= nxtWinSizeRec;

			optLenRec <= nxtOptLenRec;
			optTypRec <= nxtOptTypRec;

			maxSegSizeRec <= nxtMaxSegSizeRec;
			tsValRec <= nxtTsValRec;
			tsEcrRec <= nxtTsEcrRec;
			sAckPermitRec <= nxtSAckPermitRec;
			winScaleRec <= nxtWinScaleRec;
			chkSumRec <= nxtChkSumRec;
      
			cmpltRec <= nxtCmpltRec;
      
			-- set the TCP size and write data buses to their next values
			TCPSizeRec <= nxtTCPSizeRec;
			-- increment and reset the counter asynchronously to avoid race conditions
			if incCntRec = '1' then
				cntRec <= cntRec + 1;
			elsif rstCntRec = '1' then
				cntRec <= (others => '0');
			end if;
      
			-- increment and reset the TCP header options counter asynchronously to avoid race conditions
			if rstCntOptRec = '1' then
				CntOptRec <= (others => '0');
			elsif incCntOptRec = '1' then
				CntOptRec <= CntOptRec + 1;
			end if;

			-- latch the RAM data after reading from the RAM
			if latchRdData = '1' then
				rdLatch <= rdData;
			else
				rdLatch <= rdLatch;
			end if;
      
			if inccntPsdoHdRec = '1' then
				cntPsdoHdRec <= cntPsdoHdRec + 1;
			elsif rstcntPsdoHdRec = '1' then
				cntPsdoHdRec <= (others => '0');
			end if;

			-- latch the inputs and set the IP source buffer accordingly
			if latchDestinationIP = '1' then
				destinationIP <= sourceIP;
			end if;
			
      -- TCP transmit -------------------------------------------------------
			prsStateXmit <= nxtStateXmit;
			wrData <= nextWrData;
			busyXmit <= nxtBusyXmit;
      
			tcpDLenPrvXmit <= nxtTcpDLenPrvXmit;

			-- latch the RAM data after reading from the RAM
			if latchRdDataXmit = '1' then
				rdLatchMem <= rdDataMem;
			else
				rdLatchMem <= rdLatchMem;
			end if;
      
			-- increment and reset the counter asynchronously to avoid race conditions
			if incCntXmit = '1' then
				cntXmit <= cntXmit + 1;
			elsif rstCntXmit = '1' then
				cntXmit <= (others => '0');
			end if;

			if inccntPsdoHdXmit = '1' then
				cntPsdoHdXmit <= cntPsdoHdXmit + 1;
			elsif rstcntPsdoHdXmit = '1' then
				cntPsdoHdXmit <= (others => '0');
			end if;

      -- TCP main handler -------------------------------------------------------
			prsStateSrv <= nxtStateSrv;
			sendTCP <= nxtSendTCP;
   		mpmcRst <= nxtMpmcRst;

			sndOvrhdTrigSg <= nxtSndOvrhdTrigSg;
      
			-- increment and reset the counter asynchronously to avoid race conditions
			if incCntRplyXmit = '1' then
				cntXmitRply <= cntXmitRply + 1;
			elsif rstCntRplyXmit = '1' then
				cntXmitRply <= (others => '0');
			end if;

			seqNumXmit <= nxtSeqNumXmit;
			ackNumXmit <= nxtAckNumXmit;

			TCPSizeXmit <= nxtTCPSizeXmit;
			headLenXmit <= nxtHeadLenXmit;
			flagsXmit <= nxtFlagsXmit;
			winSizeXmit <= nxtWinSizeXmit;
  
			tsValXmit <= nxtTsValXmit;
			tsEcrXmit <= nxtTsEcrXmit;
      
			if goWaitSrv = '1' then		
				prsStateSrv <= stWaitXmitFinSrv;
				retStateSrv <= nxtStateSrv;
			else
				prsStateSrv <= nxtStateSrv;
			end if;
      
			if int_mpmc_dreq = '1' then
			  mpmc_dreq <= '1';
			else
			  mpmc_dreq <= '0';
			end if;
      
			-- handle timeout counters, rstTimoutRec will only reset the current buffer
			if rstTimoutRec = '1' then
					timout0Rec <= (others => '0');
			else
				-- increment timeout counters but don't let them overflow
				if timout0Rec /= FULTIMRec then
					timout0Rec <= timout0Rec + 1;
				else
					timout0Rec <= FULTIMRec;
				end if;
			end if;
      
      -- GIOP handler -------------------------------------------------------
      isGIOP <= nxtIsGIOP;

		end if;
	
	end process TCP_MAIN_CLK_PROC;

-- TCP data protocol unit header format
--
-- Standard TCP request and reply TCP header
--
--	0                      8                      16                                          31
--	--------------------------------------------------------------------------------------------
--	|                 Source port                |                Destination port             |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                       Sequence number                                    |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                    Acknowledgment number                                 |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|  Data offset  |  Reserved  |C|E|U|A|P|R|S|F|                  Window Size                |
--	|               |            |W|C|R|C|S|S|Y|I|                                             |
--	|               |            |R|E|G|K|H|T|N|N|                                             |
--	--------------------------------------------------------------------------------------------
--	|                   Checksum                 |                 Urgent pointer              |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                               Options (if Data Offset > 5)                               |
--	|                                          ....                                            |
--	--------------------------------------------------------------------------------------------
--

-- TCP checksum for IPv4
--
-- TCP pseudo-header (IPv4)
--
--	0                      8                      16                                          31
--	--------------------------------------------------------------------------------------------
--	|                                       Source address                                     |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                    Destination address                                   |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|        Zeros         |       Protocol      |                  TCP length                 |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                 Source port                |                Destination port             |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                       Sequence number                                    |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                    Acknowledgment number                                 |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|  Data offset  |  Reserved  |   flagsRec    |                  Window Size                |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                   Checksum                 |                 Urgent pointer              |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                    Options (optional)                                    |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                           Data                                           |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------------------
	-- TCP main FSM process
	TCP_Server_HNDLR: process (prsStateSrv, cmpltRec, sendTCP, filter_port, busyXmit, nxtBusyXmit, TCPSizeXmit, seqNumXmit, timout0Srv, 
  ackNumXmit, headLenXmit, flagsXmit, winSizeXmit, tsValXmit, tsEcrXmit, isGIOP, mpmcRst, sndOvrhdTrigSg)

	begin
		rstTimoutSrv <= '0';
		goWaitSrv <= '0';
		int_mpmc_dreq <= '0';

		nxtSndOvrhdTrigSg <= sndOvrhdTrigSg;

		incCntRplyXmit <= '0';
		rstCntRplyXmit <= '0';

		nxtMpmcRst <= mpmcRst;
		nxtSendTCP <= '0';
--		nxtSendTCP <= sendTCP;
		nxtTCPSizeXmit <= TCPSizeXmit;
		nxtSeqNumXmit <= seqNumXmit;
		nxtAckNumXmit <= ackNumXmit;
		nxtHeadLenXmit <= headLenXmit;
		nxtFlagsXmit <= flagsXmit;
		nxtWinSizeXmit <= winSizeXmit;
		nxtTsValXmit <= tsValXmit;
		nxtTsEcrXmit <= tsEcrXmit;
    
		case prsStateSrv is
			when stIdleSrv =>
				-- wait until told to receive new packet
				if cmpltRec = '0' or filter_port /= '1' then
					nxtStateSrv <= stIdleSrv;
					nxtSndOvrhdTrigSg <= '0';
				else
					nxtStateSrv <= stWait4SYNSrv;
				end if;
				nxtMpmcRst <= '1';
			when stWait4SYNSrv =>
				if FlagsRec /= x"02" then
					nxtStateSrv <= stIdleSrv;
				else
					nxtStateSrv <= stRplySYNACKSrv;
					rstCntRplyXmit <= '1';
				end if;
				nxtMpmcRst <= '1';
			when stRplySYNACKSrv =>
				if busyXmit = '0' then
					nxtSendTCP <= '1';

					nxtSeqNumXmit <= x"C4B3440F"; -- SEQs=start
					nxtAckNumXmit <= seqNumRec + (x"00" & TCPSizeRec) - (x"000" & ("00" & headLenSaveRec & "00")) + 1; -- ACKs – SEQc=1
					nxtHeadLenXmit <= x"28"; -- 40 bytes
					nxtFlagsXmit <= x"12"; -- SYN ACK
					nxtWinSizeXmit <= x"16A0"; -- Win(multiply by 1)=5792
					nxtTsValXmit <= x"03BB5B77"; -- start
					nxtTsEcrXmit <= tsValRec;
					nxtTCPSizeXmit <= x"0028"; -- 40 bytes

					nxtStateSrv <= stWait4SYNACKACKSrv;
					goWaitSrv <= '1';
				else
					nxtStateSrv <= stRplySYNACKSrv;
				end if;
				nxtMpmcRst <= '1';
			when stWait4SYNACKACKSrv =>
				if cntXmitRply = x"2" then
					nxtStateSrv <= stIdleSrv;
				elsif timout0Srv = FULTIMSrv then
--				elsif timout0Srv = ("00" & x"0010000") then
					nxtStateSrv <= stRplySYNACKSrv;
					incCntRplyXmit <= '1';
				elsif cmpltRec = '0' then
					nxtStateSrv <= stWait4SYNACKACKSrv;
				else
					if (FlagsRec = x"10") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit) + 1)) then
						nxtStateSrv <= stWait4GIOPReqSrv;
						rstTimoutSrv <= '1';	-- start/restart timer
					else
						nxtStateSrv <= stRplySYNACKSrv;
					end if;
				end if;
				nxtMpmcRst <= '1';
			when stWait4GIOPReqSrv =>
				if timout0Srv = FULTIMSrv then
--				if timout0Srv = ("00" & x"0010000") then
					nxtStateSrv <= stIdleSrv;
				elsif cmpltRec = '0' then
--				if cmpltRec = '0' then
					nxtStateSrv <= stWait4GIOPReqSrv;
				else
					if (FlagsRec = x"18") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit) + 1)) and (isGIOP = '1') then
--					if (FlagsRec = x"18") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit) + 1)) then
						nxtStateSrv <= stRplyGIOPReqACKSrv;
					else
						nxtStateSrv <= stWait4GIOPReqSrv;
					end if;
				end if;
				nxtMpmcRst <= '1';
			when stRplyGIOPReqACKSrv =>
				if busyXmit = '0' then
					nxtSendTCP <= '1';

					nxtSeqNumXmit <= seqNumXmit + (x"00" & tcpDLenPrvXmit) + 1; -- SEQs=SEQs_prev+TCP_Data_Length_prev+1
					nxtAckNumXmit <= seqNumRec + (x"00" & TCPSizeRec) - (x"000" & ("00" & headLenSaveRec & "00")); -- ACKs–SEQc=100
					nxtHeadLenXmit <= x"20"; -- 32 bytes
					nxtFlagsXmit <= x"10"; -- ACK
					nxtWinSizeXmit <= x"002E"; -- Win(multiply by 128)=5888
					nxtTsValXmit <= x"03BB5B77"; -- Tsval=Tsval_prev+0
					nxtTsEcrXmit <= tsValRec; -- Tsecr=Tsval(s)
					nxtTCPSizeXmit <= x"0020"; -- 32 bytes

					nxtStateSrv <= stXmitGIOPRplySrv;
					rstCntRplyXmit <= '1';
					goWaitSrv <= '1';
				else
					nxtStateSrv <= stRplyGIOPReqACKSrv;
				end if;
				nxtMpmcRst <= '1';
			when stXmitGIOPRplySrv =>
				if busyXmit = '0' then
					nxtSndOvrhdTrigSg <= '1';

					nxtSendTCP <= '1';

					nxtSeqNumXmit <= seqNumXmit + (x"00" & tcpDLenPrvXmit); -- SEQs=SEQs_prev+TCP_Data_Length_prev+0 
					nxtAckNumXmit <= seqNumRec + (x"00" & TCPSizeRec) - (x"000" & ("00" & headLenSaveRec & "00")); -- ACKs–SEQc=100 
					nxtHeadLenXmit <= x"20"; -- 32 bytes
					nxtFlagsXmit <= x"18"; -- PSH ACK
					nxtWinSizeXmit <= x"002E"; -- Win(multiply by 128)=5888
					nxtTsValXmit <= x"03BB5B77"; -- Tsval=Tsval_prev+0
					nxtTsEcrXmit <= tsValRec; -- Tsecr=Tsval(s)
--          	nxtTCPSizeXmit <= x"0212";--x"0424"; -- 1060 bytes
					nxtTCPSizeXmit <= (DEVICE_TCP_PAYLOAD + 60); --x"0424"; -- 1060 bytes (1000+60)

					nxtStateSrv <= stWait4XmitGIOPRplyACKSrv;
					goWaitSrv <= '1';
				else
					nxtStateSrv <= stXmitGIOPRplySrv;
				end if;
				int_mpmc_dreq <= '1';
				nxtMpmcRst <= '0';
			when stWait4XmitGIOPRplyACKSrv =>
				if cntXmitRply = x"2" then
					nxtStateSrv <= stIdleSrv;
				elsif timout0Srv = FULTIMSrv then
--				elsif timout0Srv = ("00" & x"0010000") then
					nxtStateSrv <= stXmitGIOPRplySrv;
					incCntRplyXmit <= '1';
				elsif cmpltRec = '0' then 
					nxtStateSrv <= stWait4XmitGIOPRplyACKSrv;
				else
					if (FlagsRec = x"10") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit))) then -- ACK
--					if (FlagsRec = x"10") then -- ACK
						nxtStateSrv <= stWait4FINACKSrv;
						rstTimoutSrv <= '1';	-- start/restart timer
					else
						nxtStateSrv <= stXmitGIOPRplySrv;
					end if;          
				end if;
				nxtMpmcRst <= '1';
			when stWait4FINACKSrv =>
				if timout0Srv = FULTIMSrv then
--				if timout0Srv = ("00" & x"0010000") then
					nxtStateSrv <= stIdleSrv;
				elsif (cmpltRec = '0') then 
--				if (cmpltRec = '0') then 
					nxtStateSrv <= stWait4FINACKSrv;
				else
					if (FlagsRec = x"11") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit))) then -- FIN ACK
--					if (FlagsRec = x"11") then -- FIN ACK
						nxtStateSrv <= stRplyFINACKSrv;
						rstCntRplyXmit <= '1';
					else
						nxtStateSrv <= stWait4FINACKSrv;
					end if;          
				end if;
				nxtMpmcRst <= '1';
			when stRplyFINACKSrv =>
				if busyXmit = '0' then
					nxtSendTCP <= '1';

					nxtSeqNumXmit <= seqNumXmit + (x"00" & tcpDLenPrvXmit); -- SEQs=SEQs_prev+
					nxtAckNumXmit <= seqNumRec + (x"00" & TCPSizeRec) - (x"000" & ("00" & headLenSaveRec & "00")) + 1; -- ACKs–SEQc=1
					nxtHeadLenXmit <= x"20"; -- 32 bytes
					nxtFlagsXmit <= x"11"; -- FIN ACK
					nxtWinSizeXmit <= x"002E"; -- Win(multiply by 128)=5888
					nxtTsValXmit <= x"03BB5B8C"; -- Tsval=Tsval_prev+21
					nxtTsEcrXmit <= tsValRec; -- Tsecr=Tsval(s)
					nxtTCPSizeXmit <= x"0020"; -- 32 bytes

					nxtStateSrv <= stWait4ACKSrv;
					goWaitSrv <= '1';
				else
					nxtStateSrv <= stRplyFINACKSrv;
				end if;
				nxtMpmcRst <= '1';
			when stWait4ACKSrv =>
				if cntXmitRply = x"2" then
					nxtStateSrv <= stIdleSrv;
				elsif timout0Srv = FULTIMSrv then
--				elsif timout0Srv = ("00" & x"0010000") then
					nxtStateSrv <= stRplyFINACKSrv;
					incCntRplyXmit <= '1';
				elsif (cmpltRec = '0') then 
					nxtStateSrv <= stWait4ACKSrv;
				else
					if (FlagsRec = x"10") and (ackNumRec = (seqNumXmit + (x"00" & tcpDLenPrvXmit) + 1)) then -- ACK
--					if (FlagsRec = x"10") then -- ACK
					  nxtStateSrv <= stIdleSrv;
					else
						nxtStateSrv <= stRplyFINACKSrv;
						rstCntRplyXmit <= '1';
					end if;
				end if;
				nxtMpmcRst <= '1';
			when stWaitXmitFinSrv =>
				rstTimoutSrv <= '1';	-- start/restart timer
				if busyXmit = '1' and nxtBusyXmit = '0' then
					nxtStateSrv <= retStateSrv;
					nxtSndOvrhdTrigSg <= '0';
				else
					nxtStateSrv <= stWaitXmitFinSrv;
				end if;
        
			when others => null;
		end case;
	end process TCP_Server_HNDLR;

-------------------------------------------------------------------------------------------------
	-- TCP main transmit FSM process
	TCP_XMIT_HNDLR: process (prsStateXmit, sendTCP, wrData, busyXmit, wr_complete, rd_complete, tcpDLenPrvXmit, 
  TCPSizeXmit, seqNumXmit, ackNumXmit, headLenXmit, flagsXmit, winSizeXmit, tsValXmit, tsEcrXmit, tx_done_MAC, chksmXmit)
    variable tcpDLenLeftXmit : std_logic_vector(15 downto 0);
	begin
		incCntXmit <= '0';
		rstCntXmit <= '0';
    
		nxtBusyXmit <= busyXmit;
		nxtTcpDLenPrvXmit <= tcpDLenPrvXmit;
    
		incCntPsdoHdXmit <= '0';
		rstCntPsdoHdXmit <= '0';

		wrRAM <= '0';
		-- remember the values of wrData and TCPSizeXmit by default
		nextWrData <= wrData;
		wrAddr <= (others => '0');
--		rdAddr <= (others => '0');
		sendDatagram <= '0';
		sendDatagramSize <= (others => '0');
		rdRAM <= '0';
--		latchRdData <= '0'; -- Todo: another alternative for Xmit
		newHeaderXmit <= '0';
		newByteXmit <= '0';
		inByteXmit <= (others => '0');

		case prsStateXmit is
			when stIdleXmit =>
				rstCntPsdoHdXmit <= '1';
				-- wait until told to transmit
				if sendTCP = '0' then
					nxtStateXmit <= stIdleXmit;
					rstCntXmit <= '1';
					nxtBusyXmit <= '0';
					newHeaderXmit <= '1';
				else
					-- latch all information about the TCP datagram
					nxtStateXmit <= stSetHeaderXmit;
					nxtBusyXmit <= '1';
				end if;
      
			when stSetHeaderXmit =>
				-- write header into RAM				
				if cntXmit = headLenXmit then
					-- header has been fully written so go to data stage
					nxtStateXmit <= stGetDataXmit;
				else
					nxtStateXmit <= stWrHeaderXmit;
  				-- give the checksum the data
					newByteXmit <= '1';			-- send byte to checksum calculator
					-- choose wrData and inByteXmit values
					-- inByteXmit is the data for the checksum signals
					case cntXmit is
						-- write Source port number MSB
						when x"0000" =>
							nextWrData <= DstPrtRec (15 downto 8);
							inByteXmit <= DstPrtRec (15 downto 8);
						-- write Source port number LSB
						when x"0001" =>
							nextWrData <= DstPrtRec (7 downto 0);
							inByteXmit <= DstPrtRec (7 downto 0);
						-- write Destination port number MSB
						when x"0002" =>
							nextWrData <= SrcPrtRec (15 downto 8);
							inByteXmit <= SrcPrtRec (15 downto 8);
						-- write Destination port number LSB
						when x"0003" =>
							nextWrData <= SrcPrtRec (7 downto 0);
							inByteXmit <= SrcPrtRec (7 downto 0);
						-- write Sequence number 3
						when x"0004" =>
							nextWrData <= seqNumXmit (31 downto 24);
							inByteXmit <= seqNumXmit (31 downto 24);
						-- write Sequence number 2
						when x"0005" =>
							nextWrData <= seqNumXmit (23 downto 16);
							inByteXmit <= seqNumXmit (23 downto 16);
						-- write Sequence number 1
						when x"0006" =>
							nextWrData <= seqNumXmit (15 downto 8);
							inByteXmit <= seqNumXmit (15 downto 8);
						-- write Sequence number 0
						when x"0007" =>
							nextWrData <= seqNumXmit (7 downto 0);
							inByteXmit <= seqNumXmit (7 downto 0);
						-- write Acknowledge number 3
						when x"0008" =>
							nextWrData <= ackNumXmit (31 downto 24);
							inByteXmit <= ackNumXmit (31 downto 24);
						-- write Acknowledge number 2
						when x"0009" =>
							nextWrData <= ackNumXmit (23 downto 16);
							inByteXmit <= ackNumXmit (23 downto 16);
						-- write Acknowledge number 1
						when x"000A" =>
							nextWrData <= ackNumXmit (15 downto 8);
							inByteXmit <= ackNumXmit (15 downto 8);
						-- write Acknowledge number 0
						when x"000B" =>
							nextWrData <= ackNumXmit (7 downto 0);
							inByteXmit <= ackNumXmit (7 downto 0);
						-- write the header length
						when x"000C" =>
							nextWrData <= headLenXmit (5 downto 2) & "0000";
							inByteXmit <= headLenXmit (5 downto 2) & "0000";
					  -- write the flags
						when x"000D" =>
							nextWrData <= flagsXmit;
							inByteXmit <= flagsXmit;
					  -- write the Window Size (1)
						when x"000E" =>
							nextWrData <= winSizeXmit (15 downto 8);
							inByteXmit <= winSizeXmit (15 downto 8);
					  -- write the Window Size (0)
						when x"000F" =>
							nextWrData <= winSizeXmit (7 downto 0);
							inByteXmit <= winSizeXmit (7 downto 0);
					  -- write the Checksum
						when x"0010" | x"0011" =>
							nextWrData <= x"00";
							inByteXmit <= x"00";
					  -- write the Urgent pointer
						when x"0012" | x"0013" =>
							nextWrData <= x"00";
							inByteXmit <= x"00";
					  -- write the Options
						when x"0014" =>
							if headLenXmit = x"28" then
                -- write the Max Segment Size 3
                nextWrData <= x"02";
							  inByteXmit <= x"02";
              else
                -- write the NOP
                nextWrData <= x"01";
							  inByteXmit <= x"01";
              end if;
						when x"0015" =>
							if headLenXmit = x"28" then
                -- write the Max Segment Size 2
                nextWrData <= x"04";
							  inByteXmit <= x"04";
              else
                -- write the NOP
                nextWrData <= x"01";
							  inByteXmit <= x"01";
              end if;
						when x"0016" =>
							if headLenXmit = x"28" then
                -- write the Max Segment Size 1
                nextWrData <= x"05";
							  inByteXmit <= x"05";
              else
                -- write the Timestamps kind
                nextWrData <= x"08";
							  inByteXmit <= x"08";
              end if;
						when x"0017" =>
							if headLenXmit = x"28" then
                -- write the Max Segment Size 0
                nextWrData <= x"B4";
							  inByteXmit <= x"B4";
              else
                -- write the Timestamps length
                nextWrData <= x"0A";
							  inByteXmit <= x"0A";
              end if;
						when x"0018" =>
							if headLenXmit = x"28" then
                -- write the SACK permitted kind
                nextWrData <= x"04";
							  inByteXmit <= x"04";
              else
                -- write the Timestamps TSval 3
                nextWrData <= tsValXmit (31 downto 24);
							  inByteXmit <= tsValXmit (31 downto 24);
              end if;
						when x"0019" =>
							if headLenXmit = x"28" then
                -- write the SACK permitted length
                nextWrData <= x"02";
							  inByteXmit <= x"02";
              else
                -- write the Timestamps TSval 2
                nextWrData <= tsValXmit (23 downto 16);
							  inByteXmit <= tsValXmit (23 downto 16);
              end if;
						when x"001A" =>
							if headLenXmit = x"28" then
                -- write the Timestamps kind
                nextWrData <= x"08";
							  inByteXmit <= x"08";
              else
                -- write the Timestamps TSval 1
                nextWrData <= tsValXmit (15 downto 8);
							  inByteXmit <= tsValXmit (15 downto 8);
              end if;
						when x"001B" =>
							if headLenXmit = x"28" then
                -- write the Timestamps length
                nextWrData <= x"0A";
							  inByteXmit <= x"0A";
              else
                -- write the Timestamps TSval 0
                nextWrData <= tsValXmit (7 downto 0);
							  inByteXmit <= tsValXmit (7 downto 0);
              end if;
						when x"001C" =>
							if headLenXmit = x"28" then
                -- write the Timestamps TSval 3
                nextWrData <= tsValXmit (31 downto 24);
							  inByteXmit <= tsValXmit (31 downto 24);
              else
                -- write the Timestamps TSecr 3
                nextWrData <= tsEcrXmit (31 downto 24);
							  inByteXmit <= tsEcrXmit (31 downto 24);
              end if;
						when x"001D" =>
							if headLenXmit = x"28" then
                -- write the Timestamps TSval 2
                nextWrData <= tsValXmit (23 downto 16);
							  inByteXmit <= tsValXmit (23 downto 16);
              else
                -- write the Timestamps TSecr 2
                nextWrData <= tsEcrXmit (23 downto 16);
							  inByteXmit <= tsEcrXmit (23 downto 16);
              end if;
						when x"001E" =>
							if headLenXmit = x"28" then
                -- write the Timestamps TSval 1
                nextWrData <= tsValXmit (15 downto 8);
							  inByteXmit <= tsValXmit (15 downto 8);
              else
                -- write the Timestamps TSecr 1
                nextWrData <= tsEcrXmit (15 downto 8);
							  inByteXmit <= tsEcrXmit (15 downto 8);
              end if;
						when x"001F" =>
							if headLenXmit = x"28" then
                -- write the Timestamps TSval 0
                nextWrData <= tsValXmit (7 downto 0);
							  inByteXmit <= tsValXmit (7 downto 0);
              else
                -- write the Timestamps TSecr 0
                nextWrData <= tsEcrXmit (7 downto 0);
							  inByteXmit <= tsEcrXmit (7 downto 0);
              end if;
						when x"0020" =>
              -- write the Timestamps TSecr 3
              nextWrData <= tsEcrXmit (31 downto 24);
  					  inByteXmit <= tsEcrXmit (31 downto 24);
						when x"0021" =>
              -- write the Timestamps TSecr 2
              nextWrData <= tsEcrXmit (23 downto 16);
  					  inByteXmit <= tsEcrXmit (23 downto 16);
						when x"0022" =>
              -- write the Timestamps TSecr 1
              nextWrData <= tsEcrXmit (15 downto 8);
  					  inByteXmit <= tsEcrXmit (15 downto 8);
						when x"0023" =>
              -- write the Timestamps TSecr 0
              nextWrData <= tsEcrXmit (7 downto 0);
  					  inByteXmit <= tsEcrXmit (7 downto 0);
						when x"0024" =>
              -- write the NOP
              nextWrData <= x"01";
  					  inByteXmit <= x"01";
						when x"0025" =>
              -- write the Window Scale kind
              nextWrData <= x"03";
  					  inByteXmit <= x"03";
						when x"0026" =>
              -- write the Window Scale length
              nextWrData <= x"03";
  					  inByteXmit <= x"03";
						when x"0027" =>
              -- write the Window Scale shift count
              nextWrData <= x"07";
  					  inByteXmit <= x"07";
						when others =>
							nextWrData <= (others => '0');
							inByteXmit <= (others => '0');
					end case;
				end if;

			when stWrHeaderXmit =>
				-- Write a byte to RAM
				if wr_complete = '0' then -- write 2 DPMEM
					-- Wait for RAM to acknowledge the write
					nxtStateXmit <= stWrHeaderXmit;
					wrRAM <= '1';
--					wrAddr <= ("000" & cntXmit) + ("000" & x"0022"); -- 0x22 is start address of TCP
					wrAddr <= cntXmit(10 downto 0) + ("000" & x"22"); -- 0x22 is start address of TCP
				else
					-- When it does increment the counter and go to next header byte
					nxtStateXmit <= stSetHeaderXmit;
					incCntXmit <= '1';
				end if;

			when stGetDataXmit =>
				tcpDLenLeftXmit := cntXmit - (x"00" & headLenXmit);
        -- Read data from RAM if there is more left
				if cntXmit = TCPSizeXmit then
					-- If there is no more data left
					nxtStateXmit <= stSetPseudoHeadXmit;
				else
          -- Handle GIOP 1.2 Reply with No Exception
					case tcpDLenLeftXmit is
						-- write the GIOP Magic Number 0
						when x"0000" =>
							nextWrData <= MAGIC_NUM_GIOP (31 downto 24);
							inByteXmit <= MAGIC_NUM_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Magic Number 1
						when x"0001" =>
							nextWrData <= MAGIC_NUM_GIOP (23 downto 16);
							inByteXmit <= MAGIC_NUM_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Magic Number 2
						when x"0002" =>
							nextWrData <= MAGIC_NUM_GIOP (15 downto 8);
							inByteXmit <= MAGIC_NUM_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Magic Number 3
						when x"0003" =>
							nextWrData <= MAGIC_NUM_GIOP (7 downto 0);
							inByteXmit <= MAGIC_NUM_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Version Number MSB
						when x"0004" =>
							nextWrData <= VER_GIOP (15 downto 8);
							inByteXmit <= VER_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Version Number LSB
						when x"0005" =>
							nextWrData <= VER_GIOP (7 downto 0);
							inByteXmit <= VER_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Flags (little-endian)
						when x"0006" =>
							nextWrData <= FLAG_LIT_END_GIOP;
							inByteXmit <= FLAG_LIT_END_GIOP;
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Message Type (Reply)
						when x"0007" =>
							nextWrData <= MSG_TYP_REP_GIOP;
							inByteXmit <= MSG_TYP_REP_GIOP;
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Message Size 0 (Test: req_shortseq())
						when x"0008" =>
							nextWrData <= MSG_SIZE_REP_SHORTSEQ_GIOP (31 downto 24);-- Todo: it should be calculated
							inByteXmit <= MSG_SIZE_REP_SHORTSEQ_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Message Size 1 (Test: req_shortseq())
						when x"0009" =>
							nextWrData <= MSG_SIZE_REP_SHORTSEQ_GIOP (23 downto 16);
							inByteXmit <= MSG_SIZE_REP_SHORTSEQ_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Message Size 2 (Test: req_shortseq())
						when x"000A" =>
							nextWrData <= MSG_SIZE_REP_SHORTSEQ_GIOP (15 downto 8);
							inByteXmit <= MSG_SIZE_REP_SHORTSEQ_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Message Size 3 (Test: req_shortseq())
						when x"000B" =>
							nextWrData <= MSG_SIZE_REP_SHORTSEQ_GIOP (7 downto 0);
							inByteXmit <= MSG_SIZE_REP_SHORTSEQ_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Request ID 0
						when x"000C" =>
							nextWrData <= REQ_ID_GIOP (31 downto 24);
							inByteXmit <= REQ_ID_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Request ID 1
						when x"000D" =>
							nextWrData <= REQ_ID_GIOP (23 downto 16);
							inByteXmit <= REQ_ID_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Request ID 2
						when x"000E" =>
							nextWrData <= REQ_ID_GIOP (15 downto 8);
							inByteXmit <= REQ_ID_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Request ID 3
						when x"000F" =>
							nextWrData <= REQ_ID_GIOP (7 downto 0);
							inByteXmit <= REQ_ID_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Reply status 0
						when x"0010" =>
							nextWrData <= REP_STATUS_GIOP (31 downto 24);
							inByteXmit <= REP_STATUS_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Reply status 1
						when x"0011" =>
							nextWrData <= REP_STATUS_GIOP (23 downto 16);
							inByteXmit <= REP_STATUS_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Reply status 2
						when x"0012" =>
							nextWrData <= REP_STATUS_GIOP (15 downto 8);
							inByteXmit <= REP_STATUS_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Reply status 3
						when x"0013" =>
							nextWrData <= REP_STATUS_GIOP (7 downto 0);
							inByteXmit <= REP_STATUS_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Sequence Length 0
						when x"0014" =>
							nextWrData <= SEQ_LEN_REP_GIOP (31 downto 24);
							inByteXmit <= SEQ_LEN_REP_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Sequence Length 1
						when x"0015" =>
							nextWrData <= SEQ_LEN_REP_GIOP (23 downto 16);
							inByteXmit <= SEQ_LEN_REP_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Sequence Length 2
						when x"0016" =>
							nextWrData <= SEQ_LEN_REP_GIOP (15 downto 8);
							inByteXmit <= SEQ_LEN_REP_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Sequence Length 3
						when x"0017" =>
							nextWrData <= SEQ_LEN_REP_GIOP (7 downto 0);
							inByteXmit <= SEQ_LEN_REP_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Stub Data Length 0
						when x"0018" =>
							nextWrData <= REP_STUB_DATA_LEN_GIOP (31 downto 24); -- Todo: it should be calculated
							inByteXmit <= REP_STUB_DATA_LEN_GIOP (31 downto 24);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Stub Data Length 1
						when x"0019" =>
							nextWrData <= REP_STUB_DATA_LEN_GIOP (23 downto 16);
							inByteXmit <= REP_STUB_DATA_LEN_GIOP (23 downto 16);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Stub Data Length 2
						when x"001A" =>
							nextWrData <= REP_STUB_DATA_LEN_GIOP (15 downto 8);
							inByteXmit <= REP_STUB_DATA_LEN_GIOP (15 downto 8);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						-- write the GIOP Stub Data Length 3
						when x"001B" =>
							nextWrData <= REP_STUB_DATA_LEN_GIOP (7 downto 0);
							inByteXmit <= REP_STUB_DATA_LEN_GIOP (7 downto 0);
              newByteXmit <= '1';			-- send byte to checksum calculator
              nxtStateXmit <= stWrDataXmit;
						when others =>
							-- if there is more data then perform a read from RAM
							if rd_complete = '0' then -- read from DDRMEM
                -- Wait for RAM to acknowledge read
                nxtStateXmit <= stGetDataXmit;
                rdRAM <= '1';
--                rdAddr <= "000" & cntXmit;
							else
                -- Then get ready to write the data
                nxtStateXmit <= stWrDataXmit;
                latchRdDataXmit <= '1'; -- Todo: is it necessary???
                -- give the checksum the data
                newByteXmit <= '1';			-- send byte to checksum calculator
                inByteXmit <= rdDataMem;
                nextWrData <= rdDataMem; -- Todo: or rdLatchMem???
							end if;
					end case;

				end if;

			when stWrDataXmit =>
				-- Write one data byte
				if wr_complete = '0' then -- write 2 DPMEM
					-- Wait for RAM to acknowledge the write
					nxtStateXmit <= stWrDataXmit;
					wrRAM <= '1';
--					wrAddr <= ("000" & CntXmit) + ("000" & x"0022"); -- TCP address starts from 0x22
					wrAddr <= CntXmit(10 downto 0) + ("000" & x"22"); -- TCP address starts from 0x22
				else
					-- When done, read another byte
					nxtStateXmit <= stGetDataXmit;
					incCntXmit <= '1';
				end if;

			when stWrPseudoHeadXmit =>
  			nxtStateXmit <= stSetPseudoHeadXmit;
				incCntPsdoHdXmit <= '1';

			when stSetPseudoHeadXmit =>
				if cntPsdoHdXmit = x"C" then
					-- If there is no more data left, wait until the frame completes sending
					nxtStateXmit <= stWaitForCheckSumCalcXmit;
					-- if uneven number of bytes, pad the checksum with a byte of 0s
					if TCPSizeXmit(0) = '1' then
						newByteXmit <= '1';
						inByteXmit <= (others => '0');
					end if;
				else
					nxtStateXmit <= stWrPseudoHeadXmit;
  				-- give the checksum the data
					newByteXmit <= '1';			-- send byte to checksum calculator
					-- choose wrData and inByteXmit values
					-- inByteXmit is the data for the checksum signals
					case cntPsdoHdXmit is
						-- write Source ip address number 3
						when "0000" =>
							inByteXmit <= DEVICE_IP (31 downto 24);
						-- write Source ip address number 2
						when "0001" =>
							inByteXmit <= DEVICE_IP (23 downto 16);
						-- write Source ip address number 1
						when "0010" =>
							inByteXmit <= DEVICE_IP (15 downto 8);
						-- write Source ip address number 0
						when "0011" =>
							inByteXmit <= DEVICE_IP (7 downto 0);
						-- write Destination ip address number 3
						when "0100" =>
							inByteXmit <= destinationIP (31 downto 24);
						-- write Destination ip address number 2
						when "0101" =>
							inByteXmit <= destinationIP (23 downto 16);
						-- write Destination ip address number 1
						when "0110" =>
							inByteXmit <= destinationIP (15 downto 8);
						-- write Destination ip address number 0
						when "0111" =>
							inByteXmit <= destinationIP (7 downto 0);
						-- write Zeros
						when "1000" =>
							inByteXmit <= x"00";
						-- write Protocol
						when "1001" =>
							inByteXmit <= x"06";
						-- write TCP Length MSB
						when "1010" =>
							inByteXmit <= TCPSizeXmit (15 downto 8);
						-- write TCP Length LSB
						when "1011" =>
							inByteXmit <= TCPSizeXmit (7 downto 0);
						when others =>
							inByteXmit <= (others => '0');
					end case;
        end if;

			-- if there was an uneven number of bytes, then the checksum method will require an 
			-- extra clock cycle to work it out
			when stWaitForCheckSumCalcXmit =>
				nxtStateXmit <= stWaitForCheckSumXmit;
			
			-- setup the write data bus to write the TCP checksum
			when stWaitForCheckSumXmit =>
				nxtStateXmit <= stWriteChkSum1Xmit;
				nextWrData <= chksmXmit (15 downto 8);
			
			when stWriteChkSum1Xmit =>
				-- write the TCP checksum MSB
				if wr_complete = '0' then -- write 2 DPMEM
					nxtStateXmit <= stWriteChkSum1Xmit;
					wrRAM <= '1';
--					wrAddr <= ("000" & x"0032"); -- TCP Checksum address start at 0x32
					wrAddr <= ("000" & x"32"); -- TCP Checksum address start at 0x32
				else
					nxtStateXmit <= stWriteChkSum2Xmit;
					-- setup the lower byte of the TCP checksum to write
					nextWrData <= chksmXmit (7 downto 0);
				end if;	

			when stWriteChkSum2Xmit =>
				-- write the TCP checksum LSB
				if wr_complete = '0' then -- write 2 DPMEM
					nxtStateXmit <= stWriteChkSum2Xmit;
					wrRAM <= '1';
--					wrAddr <= ("000" & x"0033");
					wrAddr <= ("000" & x"33");
				else
					nxtStateXmit <= stWriteFinishXmit;
					sendDatagram <= '1';
					sendDatagramSize <= TCPSizeXmit;
				end if;	
			when stWriteFinishXmit =>
				if tx_done_MAC = '1' then
					nxtStateXmit <= stIdleXmit;
          nxtTcpDLenPrvXmit <= TCPSizeXmit - (x"00" & headLenXmit);
				else
					nxtStateXmit <= stWriteFinishXmit;
				end if;	
      
			when others =>
        null;
		end case;
	end process TCP_XMIT_HNDLR;
-------------------------------------------------------------------------------------------------
	-- TCP main receive FSM process
	TCP_REC_HNDLR: process (prsStateRec, dstPrtRec, srcPrtRec, seqNumRec, ackNumRec, headLenRec, flagsRec, winSizeRec, newDatagram, 
  optLenRec, optTypRec, maxSegSizeRec, tsValRec, tsEcrRec, sAckPermitRec, winScaleRec, cmpltRec, rx_done_MAC, timout0Rec,
  datagramSize, rdLatch, TCPSizeRec, cntRec, CntOptRec, recNewByte, chksumRec, protocolIn, chkSumRec, isGIOP, headLenSaveRec, incoming_data)
    variable tcpDLenLeftRec : std_logic_vector(15 downto 0);
	 variable tcp_data_len : std_logic_vector(15 downto 0) := x"0000";
--	 constant virusSignature : std_logic_vector(127 downto 0) := x"ec020e1ff3a4b82125061fbab300cd21";
--	 constant virusSignature_second : std_logic_vector(127 downto 0) := x"b840008ed8a11300b106d3e02d00088e";
--	 constant virusSignature_third : std_logic_vector(127 downto 0) := x"fe3a558bec50817e0400c0730c2ea147";
	begin
		-- signal defaults
		incCntPsdoHdRec <= '0';
		rstCntPsdoHdRec <= '0';

		rstTimoutRec <= '0';

		incCntOptRec <= '0';
		rstCntOptRec <= '0';
		incCntRec <= '0';
		rstCntRec <= '0';
--		wrRAM <= '0';
		-- remember the values of wrData and TCPSizeRec by default
--		nextWrData <= wrData;
		nxtTCPSizeRec <= TCPSizeRec;
--		wrAddr <= (others => '0');
		latchRdData <= '0';
--		sendDatagram <= '0';
--		sendDatagramSize <= (others => '0');
		newHeaderRec <= '0';
		newByteRec <= '0';
		inByteRec <= (others => '0');
		latchDestinationIP <= '0';

		-- remember these signals
		nxtDstPrtRec <= dstPrtRec;
		nxtSrcPrtRec <= srcPrtRec;
		nxtincoming_data <= incoming_data;
		src_port_rec <= srcPrtRec;
		dst_port_rec <= dstPrtRec;
		tcp_data_len := TCPSizeRec - (x"00" & ("00" & headLenSaveRec & "00"));
		TCPdata <= incoming_data;
		nxtSeqNumRec <= seqNumRec;
		nxtAckNumRec <= ackNumRec;
		nxtHeadLenRec <= headLenRec;
		nxtHeadLenSaveRec <= headLenSaveRec;
		nxtFlagsRec <= flagsRec;
		nxtWinSizeRec <= winSizeRec;
		nxtChkSumRec <= chkSumRec;

		nxtOptLenRec <= optLenRec;
		nxtOptTypRec <= optTypRec;

		nxtMaxSegSizeRec <= maxSegSizeRec;
		nxtTsValRec <= tsValRec;
		nxtTsEcrRec <= tsEcrRec;
		nxtSAckPermitRec <= sAckPermitRec;
		nxtWinScaleRec <= winScaleRec;

		nxtCmpltRec <= cmpltRec;

		nxtIsGIOP <= isGIOP;
	 
		case prsStateRec is
			when stIdleRec =>
				rstCntPsdoHdRec <= '1';
				rstTimoutRec <= '1';
				nxtCmpltRec <= '0';
				rstCntRec <= '1';
				rstCntOptRec <= '1';
				TCPdataCompletelyRcvd <= '0';
				
				-- wait for a new datagram to arrive with the correct protocol for TCP
				if newDatagram = '0' or protocolIn /= 6 or filter_ip_addr /= '1' then
					nxtStateRec <= stIdleRec;
					newHeaderRec <= '1';
				else
					nxtStateRec <= stGetTCPByteRec;
					-- latch or remember the inputs about the datagram from the previous layer
					latchDestinationIP <= '1';
					nxtTCPSizeRec <= datagramSize;
					nxtIsGIOP <= '1';
				end if;
				
			when stGetTCPByteRec =>
				-- if finished write the checksum and continue
				if cntRec = TCPSizeRec then
	  				nxtStateRec <= stSetPseudoHeadRec;
					TCPdataCompletelyRcvd <= '1';
					rstTimoutRec <= '1';
				else
					-- read the current TCP byte from RAM (using IPSourceBuffer
					-- for the correct address) according to count
					TCPdataCompletelyRcvd <= '0';
					if timout0Rec = FULTIMRec then
						nxtStateRec <= stIdleRec;
					elsif recNewByte = '0' then
						nxtStateRec <= stGetTCPByteRec;
					else
						nxtStateRec <= stSetupWriteTCPByteRec;
						latchRdData <= '1';
					end if;
				end if;

			when stSetupWriteTCPByteRec =>
				nxtStateRec <= stWriteTCPByteRec;
				-- give the checksum the data
				newByteRec <= '1';
				-- set the TCP data to send according the value of count
				case cntRec is
					-- latch the source port MSB
					when "0000000000000000" =>
						nxtSrcPrtRec (15 downto 8) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the source port LSB
					when "0000000000000001" =>
						nxtSrcPrtRec (7 downto 0) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the destination port MSB
					when "0000000000000010" =>
						nxtDstPrtRec (15 downto 8) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the destination port LSB
					when "0000000000000011" =>
						nxtDstPrtRec (7 downto 0) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the sequence number (3)
					when "0000000000000100" =>
						-- check the destination port
--						if dstPrtRec /= x"BC14" then -- x"E28C" DEVICE_TCP_PORT then
						if dstPrtRec /= DEVICE_TCP_PORT then 
							nxtStateRec <= stIdleRec;
						end if;
						nxtSeqNumRec (31 downto 24) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the sequence number (2)
					when "0000000000000101" =>
						nxtSeqNumRec (23 downto 16) <= rdLatch;
						inByteRec <= rdLatch;
					
					-- latch the sequence number (1)
					when "0000000000000110" =>
						nxtSeqNumRec (15 downto 8) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the sequence number (0)
					when "0000000000000111" =>
						nxtSeqNumRec (7 downto 0) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the acknowledge number (3)
					when "0000000000001000" =>
						nxtAckNumRec (31 downto 24) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the acknowledge number (2)
					when "0000000000001001" =>
						nxtAckNumRec (23 downto 16) <= rdLatch;
						inByteRec <= rdLatch;
					
					-- latch the acknowledge number (1)
					when "0000000000001010" =>
						nxtAckNumRec (15 downto 8) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the acknowledge number (0)
					when "0000000000001011" =>
						nxtAckNumRec (7 downto 0) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the header length
					when "0000000000001100" =>
						nxtHeadLenRec <= "00" & rdLatch(7 downto 4) & "00";
						nxtHeadLenSaveRec <= rdLatch(7 downto 4);
						inByteRec <= rdLatch;

					-- latch the flagsRec
					when "0000000000001101" =>
						nxtFlagsRec <= rdLatch;
						nxtHeadLenRec <= headLenRec - x"14";
						inByteRec <= rdLatch;

					-- latch the Window Size (1)
					when "0000000000001110" =>
						nxtWinSizeRec (15 downto 8) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the Window Size (0)
					when "0000000000001111" =>
						nxtWinSizeRec (7 downto 0) <= rdLatch;
						inByteRec <= rdLatch;

					-- latch the Checksum MSB
					when "0000000000010000" =>
						nxtChkSumRec (15 downto 8) <= rdLatch;
						inByteRec <= x"00";

					-- latch the Checksum LSB
					when "0000000000010001" =>
						nxtChkSumRec (7 downto 0) <= rdLatch;
						inByteRec <= x"00";

					-- latch the Urgent pointer
					when "0000000000010010" | "0000000000010011" =>
						nxtOptLenRec <= x"FF";
						rstCntOptRec <= '1';
						inByteRec <= x"00";

					-- all other cases - TCP header options and data
					-- must be the same as what we received
					when others =>
						if headLenRec /= x"00" then
							nxtHeadLenRec <= headLenRec - x"01";
							inByteRec <= x"00";
							incCntOptRec <= '1';
							if CntOptRec = optLenRec then
								rstCntOptRec <= '1';
								nxtOptTypRec <= optNon;
							elsif CntOptRec = x"00" then  
								case rdLatch is
									-- Get the Maximum Segment Size option
									when x"02" =>
										nxtOptLenRec <= x"03";
										nxtOptTypRec <= optMaxSegSize;
										inByteRec <= rdLatch;
									-- Get the SACK Permitted option
									when x"04" =>
										nxtOptLenRec <= x"01";
										nxtOptTypRec <= optSACKPermitted;
										inByteRec <= rdLatch;
									-- Get the Timestamps option
									when x"08" =>
										nxtOptLenRec <= x"09";
										nxtOptTypRec <= optTimeStamp;
										inByteRec <= rdLatch;
									-- Get the NOP option
									when x"01" =>
										nxtOptLenRec <= x"FF";
										nxtOptTypRec <= optNOP;
										rstCntOptRec <= '1';
										inByteRec <= rdLatch;
									-- Get the Window Scale option
									when x"03" =>
										nxtOptLenRec <= x"02";
										nxtOptTypRec <= optWinScle;
										inByteRec <= rdLatch;
									when others =>
										nxtOptLenRec <= x"FF";
										nxtOptTypRec <= optNon;
										inByteRec <= rdLatch;
									end case;
							end if;
              
							case optTypRec is
								-- Get the Maximum Segment Size option
								when optMaxSegSize =>
									inByteRec <= rdLatch;
									case CntOptRec is
										when x"02" =>
											nxtMaxSegSizeRec (15 downto 8) <= rdLatch;
											inByteRec <= rdLatch;
										when x"03" =>
											nxtMaxSegSizeRec (7 downto 0) <= rdLatch;
										when others =>
											null;
									end case;
								-- Get the SACK Permitted option
								when optSACKPermitted =>
									inByteRec <= rdLatch;
									case CntOptRec is
										when x"01" =>
											nxtSAckPermitRec <= '1';
										when others =>
											null;
										end case;
								-- Get the Timestamps option
								when optTimeStamp =>
									inByteRec <= rdLatch;
									case CntOptRec is
										when x"02" =>
											nxtTsValRec (31 downto 24) <= rdLatch;
										when x"03" =>
											nxtTsValRec (23 downto 16) <= rdLatch;
										when x"04" =>
											nxtTsValRec (15 downto 8) <= rdLatch;
										when x"05" =>
											nxtTsValRec (7 downto 0) <= rdLatch;
										when x"06" =>
											nxtTsEcrRec (31 downto 24) <= rdLatch;
										when x"07" =>
											nxtTsEcrRec (23 downto 16) <= rdLatch;
										when x"08" =>
											nxtTsEcrRec (15 downto 8) <= rdLatch;
										when x"09" =>
											nxtTsEcrRec (7 downto 0) <= rdLatch;
										when others =>
											null;
									end case;
								-- Get the Window Scale option
								when optWinScle =>
									inByteRec <= rdLatch;
									case CntOptRec is
										when x"02" =>
											nxtWinScaleRec <= rdLatch; -- Todo: <= 2^rdLatch
										when others =>
											null;
										end case;
								when others =>
									inByteRec <= rdLatch;
							end case;
              
						else  -- TCP Data
							tcpDLenLeftRec := cntRec - (x"00" & ("00" & headLenSaveRec & "00"));
							inByteRec <= rdLatch;
							-- If there are some data left to receive
							if (tcpDLenLeftRec < tcp_data_len) then
									TCPdataValid <= '1';	
									nxtincoming_data <= rdLatch;
									--number of TCP data byte received, the first byte received is number one
									nbTCPdataByteRecd <= tcpDLenLeftRec + 1; 
							else
								TCPdataValid <= '0';
--								case tcpDLenLeftRec is
--									-- check the first byte of the virus signature
--									when x"0000" =>
--										nxtincoming_data (127 downto 120) <= rdLatch;
--									when x"0001" =>
--										nxtincoming_data (119 downto 112) <= rdLatch;
--									when x"0002" =>
--										nxtincoming_data (111 downto 104) <= rdLatch;
--									when x"0003" =>
--										nxtincoming_data (103 downto 96) <= rdLatch;
--									when x"0004" =>
--										nxtincoming_data (95 downto 88) <= rdLatch;
--									when x"0005" =>
--										nxtincoming_data (87 downto 80) <= rdLatch;
--									when x"0006" =>
--										nxtincoming_data (79 downto 72) <= rdLatch;
--									when x"0007" =>
--										nxtincoming_data (71 downto 64) <= rdLatch;
--									when x"0008" =>
--										nxtincoming_data (63 downto 56) <= rdLatch;
--									when x"0009" =>
--										nxtincoming_data (55 downto 48) <= rdLatch;
--									when x"000A" =>
--										nxtincoming_data (47 downto 40) <= rdLatch;
--									when x"000B" =>
--										nxtincoming_data (39 downto 32) <= rdLatch;
--									when x"000C" =>
--										nxtincoming_data (31 downto 24) <= rdLatch;
--									when x"000D" =>
--										nxtincoming_data (23 downto 16) <= rdLatch;
--									when x"000E" =>
--										nxtincoming_data (15 downto 8) <= rdLatch;
--									when x"000F" =>
--										nxtincoming_data (7 downto 0) <= rdLatch;
--										TCPdataValid <= '1';
--									when others => null;
--							end case;
						end if;
--							TCPdata <= nxtincoming_data;
--							if ((nxtincoming_data = virusSignature) or (nxtincoming_data = virusSignature_second) or (nxtincoming_data = virusSignature_third)) then
--								virusDetect <= '1';
--							else
--								virusDetect <= '0';
--							end if;
--							-- extract GIOP 1.2 data  
--							case tcpDLenLeftRec is
--								-- check the GIOP Magic Number 0
--								when x"0000" =>
--									if (MAGIC_NUM_GIOP (31 downto 24) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Magic Number 1
--								when x"0001" =>
--									if (MAGIC_NUM_GIOP (23 downto 16) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Magic Number 2
--								when x"0002" =>
--									if (MAGIC_NUM_GIOP (15 downto 8) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Magic Number 3
--								when x"0003" =>
--									if (MAGIC_NUM_GIOP (7 downto 0) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Version Number MSB
--								when x"0004" =>
--									if (VER_GIOP (15 downto 8) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Version Number LSB
--								when x"0005" =>
--									if (VER_GIOP (7 downto 0) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Flags (little-endian)
--								when x"0006" =>
--									if (FLAG_LIT_END_GIOP /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Message Type (Request)
--								when x"0007" =>
--									if (MSG_TYP_REQ_GIOP /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Message Size 0 (Test: req_shortseq())
--								when x"0008" =>
--									if (MSG_SIZE_REQ_SHORTSEQ_GIOP (31 downto 24) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Message Size 1 (Test: req_shortseq())
--								when x"0009" =>
--									if (MSG_SIZE_REQ_SHORTSEQ_GIOP (23 downto 16) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Message Size 2 (Test: req_shortseq())
--								when x"000A" =>
--									if (MSG_SIZE_REQ_SHORTSEQ_GIOP (15 downto 8) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								-- check the GIOP Message Size 3 (Test: req_shortseq())
--								when x"000B" =>
--									if (MSG_SIZE_REQ_SHORTSEQ_GIOP (7 downto 0) /= rdLatch) then
--										nxtIsGIOP <= '0';
--									end if;
--								when others =>
--									null;
--							end case;
						end if;
				end case;

			when stWrPseudoHeadRec =>
  			nxtStateRec <= stSetPseudoHeadRec;
				incCntPsdoHdRec <= '1';

			when stSetPseudoHeadRec =>
				if cntPsdoHdRec = x"C" then
					nxtStateRec <= stWaitForCheckSumCalcRec;
					-- if uneven number of bytes, pad the checksum with a byte of 0s
					if TCPSizeRec(0) = '1' then
						newByteRec <= '1';
						inByteRec <= (others => '0');
					end if;
				else
					nxtStateRec <= stWrPseudoHeadRec;
  				-- give the checksum the data
					newByteRec <= '1';			-- send byte to checksum calculator
					-- choose wrData and inByteXmit values
					-- inByteXmit is the data for the checksum signals
					case cntPsdoHdRec is
						-- write Source ip address number 3
						when "0000" =>
							inByteRec <= DEVICE_IP (31 downto 24);
						-- write Source ip address number 2
						when "0001" =>
							inByteRec <= DEVICE_IP (23 downto 16);
						-- write Source ip address number 1
						when "0010" =>
							inByteRec <= DEVICE_IP (15 downto 8);
						-- write Source ip address number 0
						when "0011" =>
							inByteRec <= DEVICE_IP (7 downto 0);
						-- write Destination ip address number 3
						when "0100" =>
							inByteRec <= destinationIP (31 downto 24);
						-- write Destination ip address number 2
						when "0101" =>
							inByteRec <= destinationIP (23 downto 16);
						-- write Destination ip address number 1
						when "0110" =>
							inByteRec <= destinationIP (15 downto 8);
						-- write Destination ip address number 0
						when "0111" =>
							inByteRec <= destinationIP (7 downto 0);
						-- write Zeros
						when "1000" =>
							inByteRec <= x"00";
						-- write Protocol
						when "1001" =>
							inByteRec <= x"06";
						-- write TCP Length MSB
						when "1010" =>
							inByteRec <= TCPSizeRec (15 downto 8);
						-- write TCP Length LSB
						when "1011" =>
							inByteRec <= TCPSizeRec (7 downto 0);
						when others =>
							inByteRec <= (others => '0');
					end case;
        end if;

			when stWriteTCPByteRec =>
				-- write the new TCP data
--				if complete = '0' then
--					nxtStateRec <= stWriteTCPByteRec;
--					wrRAM <= '1';
--					wrAddr <= ("000" & cntRec) + ("000" & x"0022"); -- akzare
--				else
					-- go back and get the next byte of data
					nxtStateRec <= stGetTCPByteRec;
					rstTimoutRec <= '1';
					incCntRec <= '1';
--				end if;
			
			-- if there was an uneven number of bytes, then the checksum method will require an 
			-- extra clock cycle to work it out
			when stWaitForCheckSumCalcRec =>
				nxtStateRec <= stWaitForCheckSumRec;
			
			-- setup the write data bus to write the TCP checksum
			when stWaitForCheckSumRec =>
				nxtStateRec <= stWriteChkSum1Rec;
--				nextWrData <= chksmCalRec (15 downto 8);
--			
			when stWriteChkSum1Rec =>
--				-- write the TCP checksum MSB
--				if complete = '0' then
--					nxtStateRec <= stWriteChkSum1Rec;
--					wrRAM <= '1';
----					wrAddr <= "1000000000000000010";
--					wrAddr <= ("000" & x"0024"); -- akzare
--				else
					nxtStateRec <= stWriteChkSum2Rec;
--					-- setup the lower byte of the TCP checksum to write
--					nextWrData <= chksmCalRec (7 downto 0);
--				end if;	
--
			when stWriteChkSum2Rec =>
--				-- write the TCP checksum LSB
--				if complete = '0' then
--					nxtStateRec <= stWriteChkSum2Rec;
--					wrRAM <= '1';
----					wrAddr <= "1000000000000000011";
--					wrAddr <= ("000" & x"0025"); -- akzare
--				else
					nxtStateRec <= stWaitFinRec;
					rstTimoutRec <= '1';
--					sendDatagram <= '1';
--					sendDatagramSize <= TCPSizeRec;
--				end if;	

			when stWaitFinRec =>
				if timout0Rec = FULTIMRec then
					nxtStateRec <= stIdleRec;
--				elsif rx_done_MAC = '1' then
				elsif rx_done_MAC = '0' then --Adil : rx_done_mac have to be set up in software but how ??
   				nxtStateRec <= stIdleRec;
					if (chksmCalRec = chkSumRec) then
						nxtCmpltRec <= '1';
					end if;
				else
   				nxtStateRec <= stWaitFinRec;
				end if;
			
			when others =>
        null;
		end case;
	end process TCP_REC_HNDLR;

  -- Xmit Checksum calculation -----------------------------------------
	chksmIntXmit <= 	chksmLongXmit(15 downto 0) + chksmLongXmit(16);
	chksmXmit <= NOT chksmIntXmit;

	TCP_XMIT_CKSUM_HNDLR: process (clk,rstn)
	begin
		if rstn = '0' then
			chkStateXmit <= stMSB;
			latchMSBXmit <= (others => '0');
			chksmLongXmit <= (others => '0');
			validXmit <= '0';
		elsif clk'event and clk = '1' then	
			case chkStateXmit is
				when stMSB =>
					if newHeaderXmit = '1' then
						chkStateXmit <= stMSB;
						chksmLongXmit <= (others => '0');
						validXmit <= '0';
					elsif newByteXmit = '1' then
						chkStateXmit <= stLSB;
						latchMSBXmit <= inByteXmit;
						validXmit <= '0';
					else
						chkStateXmit <= stMSB;
						validXmit <= '1';
					end if;
				when stLSB =>
					validXmit <= '0';		
					if newHeaderXmit = '1' then
						chkStateXmit <= stMSB;
						chksmLongXmit <= (others => '0');
					elsif newByteXmit = '1' then
						chkStateXmit <= stMSB;
						chksmLongXmit <= ('0' & chksmIntXmit) + ('0' & latchMSBXmit & inByteXmit);
					else
						chkStateXmit <= stLSB;
					end if;
				when others =>
					chkStateXmit <= stMSB;
					validXmit <= '0';
			end case;
		end if;
	end process TCP_XMIT_CKSUM_HNDLR;	

  -- Rec Checksum calculation -----------------------------------------
	chksmIntRec <= 	chksmLongRec(15 downto 0) + chksmLongRec(16);
	chksmCalRec <= NOT chksmIntRec;

	TCP_REC_CKSUM_HNDLR: process (clk,rstn)
	begin
		if rstn = '0' then
			chkStateRec <= stMSB;
			latchMSBRec <= (others => '0');
			chksmLongRec <= (others => '0');
			validRec <= '0';
		elsif clk'event and clk = '1' then	
			case chkStateRec is
				when stMSB =>
					if newHeaderRec = '1' then
						chkStateRec <= stMSB;
						chksmLongRec <= (others => '0');
						validRec <= '0';
					elsif newByteRec = '1' then
						chkStateRec <= stLSB;
						latchMSBRec <= inByteRec;
						validRec <= '0';
					else
						chkStateRec <= stMSB;
						validRec <= '1';
					end if;
				when stLSB =>
					validRec <= '0';		
					if newHeaderRec = '1' then
						chkStateRec <= stMSB;
						chksmLongRec <= (others => '0');
					elsif newByteRec = '1' then
						chkStateRec <= stMSB;
						chksmLongRec <= ('0' & chksmIntRec) + ('0' & latchMSBRec & inByteRec);
					else
						chkStateRec <= stLSB;
					end if;
				when others =>
					chkStateRec <= stMSB;
					validRec <= '0';
			end case;
		end if;
	end process TCP_REC_CKSUM_HNDLR;	

end tcp_arch;
