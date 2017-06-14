----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    15:01:19 03/28/2013 
-- Design Name: 
-- Module Name:    filter_inc_pack - Behavioral 
-- Project Name: 	 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.std_logic_unsigned.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity filter_inc_pack is
	 generic 
	 ( -- Packets are processed only if they come from this network
	   AUTHORIZED_NETWORK : STD_LOGIC_VECTOR (31 downto 0) := x"C0A80100";
	   NETWORK_MASK : STD_LOGIC_VECTOR (31 downto 0) := x"FFFFFF00";
		
		-- Packets are processed only if the destination IP and the source IP of the packet are the ones below
		DEVICE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"C0A8010A"; --192.168.1.10
		AUTHORIZED_SOURCE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"C0A80102"; --192.168.1.2
		
		-- For TCP packets, Packets are processed only if the destination port and the source port of the packet 
		-- are these port numbers
		AUTHORIZED_DEST_PORT : STD_LOGIC_VECTOR (15 downto 0) := x"99E4"; --port number 39396
		AUTHORIZED_SOURCE_PORT : STD_LOGIC_VECTOR (15 downto 0) := x"DFCC"; --port number 57292;
		
		-- Packets are processed only if the transport layer is TCP
		AUTHORIZED_PROTOCOL : STD_LOGIC_VECTOR (7 downto 0) := x"06"
		);
    Port ( clk : in  STD_LOGIC;
			  clk_150 : in STD_LOGIC;
           rst : in  STD_LOGIC;
			  protocol : in  STD_LOGIC_VECTOR (7 downto 0); -- protocol field in the IP header of the received packet
           source_ip : in  STD_LOGIC_VECTOR (31 downto 0); -- Source IP of the packet
           dest_ip : in  STD_LOGIC_VECTOR (31 downto 0); -- Destination IP of the packet
			  source_port : in STD_LOGIC_VECTOR (15 downto 0); -- Source Port (if protocol=TCP or UDP)
			  dest_port : in STD_LOGIC_VECTOR (15 downto 0); -- Destination Port (if protocol=TCP or UDP)
			  TCPdataValid : in STD_LOGIC; -- indicate whether the TCP data is valid or not
			  TCPdata : in STD_LOGIC_VECTOR (7 downto 0); -- TCP data
			  TCPdataLen : in STD_LOGIC_VECTOR (15 downto 0); -- length of the TCP payload in byte(payload without header)
			  nbTCPDataByteRec : in STD_LOGIC_VECTOR (15 downto 0); -- indicate how many data byte have been currently rcvd
			  TCPdataCompletelyRcvd : in STD_LOGIC; -- indicate if the TCP message has been completely received
			  PHY_rx_clk : in STD_LOGIC; -- rx clk (25MHz)
			  newTCPMessage : in STD_LOGIC; -- A new TCP message has been rcvd
			  newByteRecv	 : in STD_LOGIC; -- A new Byte has been received
			  leds : out STD_LOGIC_VECTOR (7 downto 0);
			  allow_process_ip : out STD_LOGIC; -- Allow or forbidden the ICMP reply process
			  allow_process_tcp : out STD_LOGIC; --Allow or forbidden the TCP reply process
			  
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
			  VFBC2_rd_almost_empty 	: in std_logic
			  --------------- Memory Controller Interface, VFBC mode (Adil) ----- 

		);           
end filter_inc_pack;

architecture Behavioral of filter_inc_pack is
  
  signal data_tcp: STD_LOGIC_VECTOR (7 downto 0);
  signal data : STD_LOGIC_VECTOR(7 downto 0);
  signal hit: STD_LOGIC_VECTOR (2 downto 0);
  signal hit_irc: STD_LOGIC_VECTOR (3 downto 0);
  signal IRCmsgDetected: STD_LOGIC_VECTOR (2 downto 0);
  signal nbPatternDetected: STD_LOGIC_VECTOR (31 downto 0);
  signal nbIRCmsgDetected: STD_LOGIC_VECTOR (31 downto 0);
  signal nbJOINmsgDetected : STD_LOGIC_VECTOR(31 downto 0);
  signal nbPINGmsgDetected : STD_LOGIC_VECTOR(31 downto 0);
  signal nbPONGmsgDetected : STD_LOGIC_VECTOR(31 downto 0);
  signal nbPRIVMSGmsgDetected : STD_LOGIC_VECTOR(31 downto 0);
  signal channel : STD_LOGIC_VECTOR(399 downto 0);
  signal nextChannel : STD_LOGIC_VECTOR(399 downto 0);
  
  signal suspiciousLoopSrcIP : STD_LOGIC_VECTOR(31 downto 0);--number of packets with a suspicious loopback source ip
  signal suspiciousBroadSrcIP : STD_LOGIC_VECTOR(31 downto 0); --number of packets with a suspicious broadcast source ip
  signal suspiciousProtocol : STD_LOGIC_VECTOR(31 downto 0); --number of packets with a suspicious protocol in IP header
  signal suspectedLandAttack : STD_LOGIC_VECTOR(31 downto 0); --number of packets with the same source and destination ip
   
  signal wd_wr : STD_LOGIC := '0';
  signal wd_data : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
  signal wd_end_burst : STD_LOGIC := '0';
  signal cmd_wr : STD_LOGIC := '0';
  signal cmd_data : STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
  
--  signal control0: STD_LOGIC_VECTOR(35 downto 0);
--  signal data_chipscope : std_logic_vector(74 downto 0);
--  
--  component icon
--  port (
--    CONTROL0: inout STD_LOGIC_VECTOR(35 downto 0));
--  end component;
--  
--  component ila
--  port (
--    CONTROL: inout STD_LOGIC_VECTOR(35 downto 0);
--    CLK: in STD_LOGIC;
--    DATA: in STD_LOGIC_VECTOR(74 downto 0);
--    TRIG0: in STD_LOGIC_VECTOR(0 downto 0));
--  end component;

begin

--	data_chipscope <= wd_data & cmd_data & wd_end_burst & TCPdataCompletelyRcvd & VFBC2_wd_full & VFBC2_wd_almost_full & VFBC2_cmd_full & VFBC2_cmd_almost_full & wd_wr & cmd_wr & newTCPMessage & IRCmsgDetected & clk;
--	
--	icon_comp : icon
--	port map(CONTROL0=> control0);
--	
--  ila_comp : ila
--  port map (
--    CONTROL => control0,
--    CLK => clk_150,
--    DATA => data_chipscope,
--    TRIG0(0) => newTCPMessage);

	data_tcp <= data;
	
	VFBC2_cmd_clk <= clk;
	VFBC2_cmd_reset <= '0';
	VFBC2_cmd_write <= not VFBC2_cmd_full and cmd_wr;
	VFBC2_cmd_data <= cmd_data;
	VFBC2_cmd_end <= '0';
	
	VFBC2_wd_clk <= clk;
	VFBC2_wd_reset <= '0';
	VFBC2_wd_write <= wd_wr;
	VFBC2_wd_data <= wd_data;
	VFBC2_wd_end_burst <= wd_end_burst;
	VFBC2_wd_flush <= '0';
	VFBC2_wd_data_be <= "0000";
		
	-- The component below is in charge of detecting malware patterns in TCP Payloads
	PATT_MATCH_MALWARE: entity hardorb_fpga_v3_01_a.pattern_match
		Port map 
		(  clk => clk,
			rx_clk => PHY_rx_clk,
			car => data_tcp,
			nbPatternDetected => nbPatternDetected,
			hit => hit 
		);
	-- The component above is in charge of detecting malware patterns in TCP Payloads
	
	-- The component below is in charge of detecting IRC (Internet Relay Chat) packets
	PATT_MATCH_IRC: entity hardorb_fpga_v3_01_a.pattern_match_irc
		Port map 
		(  clk_150 => clk_150,
			clk => clk,
			rx_clk => PHY_rx_clk,
			car => data_tcp,
			newByteRecv => newByteRecv,
			newTCPMessage => newTCPMessage,
			IRCmsgDetected => IRCmsgDetected,
			nbIRCmsgDetected => nbIRCmsgDetected,
			nbJOINmsgDetected => nbJOINmsgDetected,
			nbPINGmsgDetected => nbPINGmsgDetected,
			nbPONGmsgDetected => nbPONGmsgDetected,
			nbPRIVMSGmsgDetected => nbPRIVMSGmsgDetected,
			channel => channel,
			nextChannel => nextChannel,
			hit => hit_irc 
		);
	-- The component above is in charge of detecting IRC (Internet Relay Chat) packets
	
	process (clk, rst)
		variable source_network : STD_LOGIC_VECTOR(31 downto 0) := x"00000000";
		variable TCP_data : STD_LOGIC_VECTOR(511 downto 0);
		variable nbTCPdataByteToRec : natural := 0; --This is the number of TCP data byte to receive
		variable nbTCPdataByteRecd : natural := 0; --This is the number of TCP data byte currently received
		variable nbTimePatternDetected : natural := 0; --This is the number of TCP data byte currently receive
		constant virusSignature : STD_LOGIC_VECTOR(511 downto 0) := x"e800005d1e0606b84035cd218cc0073d00f07418b42ccd2180fa077d0fb93f008ac1e67032c0e671e2f6eb4b33ff8edf813e04005e01742d8cc048832e130401";
		
		
		-- The signals below are used to count the number of received packets with suspicious values
		variable suspicious_loop_src_ip : natural := 0; --number of packets with a suspicious loopback source ip
		variable suspicious_broad_src_ip : natural := 0; --number of packets with a suspicious broadcast source ip
		variable suspicious_protocol : natural := 0; --number of packets with a suspicious protocol in IP header
		variable suspected_land_attack : natural := 0; --number of packets with the same source and destination ip
		-- The signals above are used to count the number of received packets with suspicious values
		
		begin
			if rst = '0' then
				allow_process_ip <= '0';
				allow_process_tcp <= '0';
--				leds <= (others => '0');
				nbTimePatternDetected:=0;
			elsif clk'event and clk = '1' then
					if (protocol = x"01") then -- if the protocol encapsulated by IP is ICMP
						source_network := source_ip and NETWORK_MASK;
						if (source_network = AUTHORIZED_NETWORK) then -- if the source IP of the packet belongs to the authorized network
--							if (source_ip = AUTHORIZED_SOURCE_IP) and (dest_ip = DEVICE_IP) then
								allow_process_ip <= '1';
								leds <= (others => '0');
--							else
--								allow_process_ip <= '0';
--								leds <= (others => '0');
--						   end if;
						else
							allow_process_ip <= '0';
							if (source_ip = x"7F000001") then -- 127.0.0.1
								-- Indicate that a packet with the source address 127.0.0.1 has been received
								if(newTCPMessage = '1') then
									suspicious_loop_src_ip := suspicious_loop_src_ip + 1;
									suspiciousLoopSrcIP <= std_logic_vector(to_unsigned(suspicious_loop_src_ip,32));
									leds <= std_logic_vector(to_unsigned(suspicious_loop_src_ip,8));
								end if;
							elsif (source_ip = x"FFFFFFFF") then -- 255.255.255.255
								-- Indicate that a packet with the source address 255.255.255.255 has been received
								if(newTCPMessage = '1') then
									suspicious_broad_src_ip := suspicious_broad_src_ip + 1;
									suspiciousBroadSrcIP <= std_logic_vector(to_unsigned(suspicious_broad_src_ip,32));
									leds <= std_logic_vector(to_unsigned(suspicious_broad_src_ip,8));
								end if;
							end if;
						end if;
					 elsif (protocol = x"06") then -- if the protocol encapsulated by IP is TCP
							source_network := source_ip and NETWORK_MASK;
							if (source_network = AUTHORIZED_NETWORK) then -- if the source IP of the packet belongs to the authorized network
								if (source_ip = AUTHORIZED_SOURCE_IP) and (dest_ip = DEVICE_IP) then
									allow_process_ip <= '1';
									leds <= (others => '0');
									if (source_port = AUTHORIZED_SOURCE_PORT) and (dest_port = AUTHORIZED_DEST_PORT) then
--=============================================================================================================
-- The part of code below can be used to check whether the TCP data are well received or not
--										This is the number of TCP data byte to receive
--										nbTCPdataByteToRec := to_integer(unsigned(TCPdataLen));.
--										if (TCPdataValid = '1') then 
--										      --This is the number of TCP data byte currently received
--										      nbTCPdataByteRecd := to_integer(unsigned(nbTCPDataByteRec));
--												TCP_data ((8*(nbTCPdataByteToRec-nbTCPdataByteRecd)+7) downto (8*(nbTCPdataByteToRec-nbTCPdataByteRecd))) := TCPdata;
--												leds <= nbTCPDataByteRec(7 downto 0);
--										end if;
--											
--										if (TCP_data /= virusSignature) then
--											allow_process_tcp <= '1';
--											leds <= (others => '0');
--										else
--											allow_process_tcp <= '0';
--											leds <= (others => '1');
--										end if;
-- The part of code above can be used to check whether the TCP data are well received or not
--=============================================================================================================
										allow_process_tcp <= '1';
										if (TCPdataValid = '1') then
											data <= TCPdata;
--											leds <= nbPRIVMSGmsgDetected (7 downto 0);
										end if;
										leds <= nextChannel (7 downto 0);
--=============================================================================================================
-- The part of code below can be used to check whether a specific pattern is well detected or not										
--										if(hit /= "000")then
--											leds (2 downto 0) <= hit;
--										end if;
-- The part of code above can be used to check whether a specific pattern is well detected or not
--=============================================================================================================
										
									else -- source port or/and dest port are different from the ones allowed
										allow_process_tcp <= '0';
									end if;
								else -- source IP or/and dest IP are different from the ones allowed
									allow_process_ip <= '0';
									if (source_ip = dest_ip) then --Suspect a land attack
										if(newTCPMessage = '1') then
											-- Indicate that a suspected land attack have been detected
											suspected_land_attack := suspected_land_attack + 1;
											suspectedLandAttack <= std_logic_vector(to_unsigned(suspected_land_attack,32));
											leds <= std_logic_vector(to_unsigned(suspected_land_attack,8));
										end if;
									end if;
								end if;
							else -- source IP does not belong to the allowed network
								allow_process_ip <= '0';
								if (source_ip = x"7F000001") then -- 127.0.0.1
									-- Indicate that a packet with the source address 127.0.0.1 has been received
									if(newTCPMessage = '1') then
										suspicious_loop_src_ip := suspicious_loop_src_ip + 1;
										suspiciousLoopSrcIP <= std_logic_vector(to_unsigned(suspicious_loop_src_ip,32));
										leds <= std_logic_vector(to_unsigned(suspicious_loop_src_ip,8));
									end if;
								elsif (source_ip = x"FFFFFFFF") then -- 255.255.255.255
									-- Indicate that a packet with the source address 255.255.255.255 has been received
									if(newTCPMessage = '1') then
										suspicious_broad_src_ip := suspicious_broad_src_ip + 1;
										suspiciousBroadSrcIP <= std_logic_vector(to_unsigned(suspicious_broad_src_ip,32));
										leds <= std_logic_vector(to_unsigned(suspicious_broad_src_ip,8));
									end if;
								end if;
							end if;				
					elsif(protocol > x"86") then -- protocol is neither ICMP nor TCP and has a value greater than 134
						if(newTCPMessage = '1') then
							-- Indicate that a packet with a value greater than 134 in protocol field has been received
							suspicious_protocol := suspicious_protocol + 1;
							suspiciousProtocol <= std_logic_vector(to_unsigned(suspicious_protocol,32));
							leds <= std_logic_vector(to_unsigned(suspicious_protocol,8));
						end if;
					end if;
			end if;
	end process;
	
	
	-- This process handles the command interface of the VFBC
	VFBC_CMD_DATA: process (clk, rst)
		variable nbCommandPacket : natural range 0 to 4 := 0; --This is the number of command packet to send to handle the memory
		begin
			if clk'event and clk = '1' then
				-- if a new message is received then the data must be updated in memory
				if(newTCPMessage = '1') then
					cmd_wr <= '1';
					nbCommandPacket := 0;
				end if;
				-- The case below handles the transmission of the command packet data of the VFBC
				case (nbCommandPacket) is
					when 0 =>
						if(VFBC2_cmd_full = '0') then
							nbCommandPacket := nbCommandPacket + 1;
						end if;
						cmd_data <= x"000000A8"; --X length, 168 bytes per line for statistic purposes (168 = 0xA8)
					when 1 =>
						if(VFBC2_cmd_full = '0') then
							nbCommandPacket := nbCommandPacket + 1;
						end if;
						cmd_data <= x"80000000"; --write transaction, starting at address 0x00000000
					when 2 =>
						if(VFBC2_cmd_full = '0') then
							nbCommandPacket := nbCommandPacket + 1;
						end if;
						cmd_data <= x"00000000"; --number of line for transfer minus one (only one line)
					when 3 =>
						if(VFBC2_cmd_full = '0') then
							nbCommandPacket := nbCommandPacket + 1;
						end if;
						cmd_data <= x"000000A8"; --stride
					when 4 =>
						nbCommandPacket := nbCommandPacket + 1;
						cmd_wr <= '0';
					when others => null;
				end case;	
			end if;
	end process VFBC_CMD_DATA;
	
	-- This process handles the write interface of the VFBC
	VFBC_WR_DATA: process (clk, rst)
		variable cnt : natural range 0 to 42 := 0;
		begin
			if rst = '0' then
				cnt := 0;
			elsif(clk'event and clk = '1') then
				
				if TCPdataCompletelyRcvd = '1' then
					wd_wr <= '1';
					cnt := 0;
				end if;
				
				-- The case below handles the transmission of the packet data of the VFBC
				case (cnt) is
					when 0 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= "0000000" & TCPdataCompletelyRcvd & x"000000";
					when 1 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= "00000" & IRCmsgDetected & x"000000";
					when 2 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= suspiciousProtocol(7 downto 0) & suspiciousProtocol(15 downto 8) & suspiciousProtocol(23 downto 16) & suspiciousProtocol(31 downto 24);
					when 3 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= suspiciousLoopSrcIP(7 downto 0) & suspiciousLoopSrcIP(15 downto 8) & suspiciousLoopSrcIP(23 downto 16) & suspiciousLoopSrcIP(31 downto 24);
					when 4 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= suspiciousBroadSrcIP(7 downto 0) & suspiciousBroadSrcIP(15 downto 8) & suspiciousBroadSrcIP(23 downto 16) & suspiciousBroadSrcIP(31 downto 24);
					when 5 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= suspectedLandAttack(7 downto 0) & suspectedLandAttack(15 downto 8) & suspectedLandAttack(23 downto 16) & suspectedLandAttack(31 downto 24);
					when 6 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbPatternDetected(7 downto 0) & nbPatternDetected(15 downto 8) & nbPatternDetected(23 downto 16) & nbPatternDetected(31 downto 24);
					when 7 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbIRCmsgDetected(7 downto 0) & nbIRCmsgDetected(15 downto 8) & nbIRCmsgDetected(23 downto 16) & nbIRCmsgDetected(31 downto 24);
					when 8 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbJOINmsgDetected(7 downto 0) & nbJOINmsgDetected(15 downto 8) & nbJOINmsgDetected(23 downto 16) & nbJOINmsgDetected(31 downto 24);
					when 9 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbPINGmsgDetected(7 downto 0) & nbPINGmsgDetected(15 downto 8) & nbPINGmsgDetected(23 downto 16) & nbPINGmsgDetected(31 downto 24);
					when 10 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbPONGmsgDetected(7 downto 0) & nbPONGmsgDetected(15 downto 8) & nbPONGmsgDetected(23 downto 16) & nbPONGmsgDetected(31 downto 24);
					when 11 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nbPRIVMSGmsgDetected(7 downto 0) & nbPRIVMSGmsgDetected(15 downto 8) & nbPRIVMSGmsgDetected(23 downto 16) & nbPRIVMSGmsgDetected(31 downto 24);
					when 12 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= source_ip(7 downto 0) & source_ip(15 downto 8) & source_ip(23 downto 16) & source_ip(31 downto 24);
					when 13 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= dest_ip(7 downto 0) & dest_ip(15 downto 8) & dest_ip(23 downto 16) & dest_ip(31 downto 24);
					when 14 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= source_port(7 downto 0) & source_port(15 downto 8)  & x"0000";
					when 15 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= dest_port(7 downto 0) & dest_port(15 downto 8) & x"0000";
					when 16 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(31 downto 0);
					when 17 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(63 downto 32);
					when 18 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(95 downto 64);
					when 19 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(127 downto 96);
					when 20 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(159 downto 128);
					when 21 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(191 downto 160);
					when 22 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(223 downto 192);
					when 23 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(255 downto 224);
					when 24 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(287 downto 256);
					when 25 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(319 downto 288);
					when 26 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(351 downto 320);
					when 27 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(383 downto 352);
					when 28 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= channel(399 downto 384) & x"0000";
					when 29 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(31 downto 0);
--						if(wd_wr = '1') then
--							wd_end_burst <= '1';
--						end if;
					when 30 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(63 downto 32);
					when 31 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(95 downto 64);
					when 32 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(127 downto 96);
					when 33 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(159 downto 128);
					when 34 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(191 downto 160);
					when 35 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(223 downto 192);
					when 36 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(255 downto 224);
					when 37 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(287 downto 256);
					when 38 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(319 downto 288);
					when 39 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(351 downto 320);
					when 40 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(383 downto 352);
					when 41 =>
						if(VFBC2_wd_full = '0') then
							cnt := cnt + 1;
						end if;
						wd_data <= nextChannel(399 downto 384) & x"0000";
						if(wd_wr = '1') then
							wd_end_burst <= '1';
						end if;
					when 42 =>
						cnt := cnt + 1;
						wd_wr <= '0';
						wd_end_burst <= '0';
					when others => null;
				end case;
			end if;
	end process VFBC_WR_DATA;
						
end Behavioral;



