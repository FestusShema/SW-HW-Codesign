-------------------------------------------------------------------------------
-- internetsnd.vhd
--
-- Author(s):     Ashley Partis and Jorgen Peddersen
-- Created:       Jan 2001
-- Last Modified: Feb 2001
-- Last Modified: Dec 2009 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)
-- 
-- Internet packet sending layer.  Sends TPDUs from the transport layers as IP
-- packets.  If the datagram is too large to fit into one frame (1480 bytes),
-- fragments are transmitted until the full datagram is transmitted.  All
-- fragments transmitted except for the last fragment are 1024 bytes long.  The
-- last fragment may be anything from 1 byte to 1480 bytes long depending on 
-- how much of the datagram is left.  Fragments are transmitted as soon as the
-- previous fragment is transmitted, and all fragments will be transmitted 
-- before the IP layer becomes idle again.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use work.global_constants.all;

entity InternetSnd is
    generic (
    C_DEBUG_MODE : integer := 0;	-- 0 = disable, 1 = enable
    DEVICE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a" -- 192.168.1.10
    );                
    port (
        clk: in STD_LOGIC;									-- clock
        rstn: in STD_LOGIC;									-- active low asynchronous reset
        frameSent: in STD_LOGIC;							-- indicates the ethernet has sent a frame
        sendDatagram: in STD_LOGIC;							-- signal to send a datagram message
        datagramSize: in STD_LOGIC_VECTOR (15 downto 0);	-- size of datagram to transmit
        destinationIP: in STD_LOGIC_VECTOR (31 downto 0);	-- IP to transmit message to
--        addressOffset: in STD_LOGIC_VECTOR (2 downto 0);	-- Indicates location in RAM of datagram
        protocol: in STD_LOGIC_VECTOR (7 downto 0);			-- protocol of the datagram to be sent
        complete: in STD_LOGIC;								-- complete signal from the RAM operation
        rdData: in STD_LOGIC_VECTOR (7 downto 0);			-- read data from RAM
--        rdRAM: out STD_LOGIC;								-- read signal for RAM
--        rdAddr: out STD_LOGIC_VECTOR (18 downto 0);			-- read address for RAM
        wrRAM: out STD_LOGIC;								-- write signal for RAM
        wrData: buffer STD_LOGIC_VECTOR (7 downto 0);		-- write data for RAM
--        wrAddr: out STD_LOGIC_VECTOR (18 downto 0);			-- write address for RAM
        wrAddr: out STD_LOGIC_VECTOR (7 downto 0);			-- write address for RAM
        sendFrame: out STD_LOGIC;							-- signal to get ethernet to send frame
        datagramSent: out STD_LOGIC;						-- tells higher protocol when the datagram was sent
        frameSize: out STD_LOGIC_VECTOR (10 downto 0);		-- tells the ethernet layer how long the frame is
        ARPIP: out STD_LOGIC_VECTOR (31 downto 0)			-- IP that the ARP layer must look up
    );
end InternetSnd;

architecture InternetSnd_arch of InternetSnd is

-- State types and signals
--type STATETYPE is (stIdle, stSetHeader, stWrHeader, stWrChksumHi, stWrChksumLo, stGetData, stMoreFragments, stWrData);
type STATETYPE is (stIdle, stSetHeader, stWrHeader, stWrChksumHi, stWrChksumLo, stGetData, stWrData);
signal presState: STATETYPE;
signal nextState: STATETYPE;

-- Remember value of wrData
signal nextWrData: STD_LOGIC_VECTOR (7 downto 0);

-- counter signals
--signal cnt: STD_LOGIC_VECTOR (10 downto 0);
signal cnt: STD_LOGIC_VECTOR (7 downto 0);
signal incCnt: STD_LOGIC;
signal rstCnt: STD_LOGIC;

-- identification counter to tell different messages apart
signal idenCnt: STD_LOGIC_VECTOR (25 downto 0);

-- length of datagram to transmit next
signal datagramLen: STD_LOGIC_VECTOR (15 downto 0);

-- latch data read from RAM into the write data register
signal latchRdData: STD_LOGIC;

-- checksum signals : see internet.vhd for comments
signal checkState : STD_LOGIC;
CONSTANT stMSB : STD_LOGIC := '0';
CONSTANT stLSB : STD_LOGIC := '1';

signal checksumLong : STD_LOGIC_VECTOR (16 downto 0);
signal checksumInt : STD_LOGIC_VECTOR (15 downto 0);

signal latchMSB : STD_LOGIC_VECTOR (7 downto 0);

signal lastNewByte : STD_LOGIC;

signal newHeader: STD_LOGIC;
signal newByte: STD_LOGIC;
signal inByte: STD_LOGIC_VECTOR (7 downto 0);

signal checksum: STD_LOGIC_VECTOR (15 downto 0);
signal valid: STD_LOGIC; 


-- destination IP register and signal
signal destinationIPLatch : STD_LOGIC_VECTOR (31 downto 0);
signal latchDestinationIP : STD_LOGIC;

-- addressOffset register and signal
--signal addressOffsetLatch : STD_LOGIC_VECTOR (2 downto 0);
signal latchAddressOffset : STD_LOGIC;

-- protocol register and signal
signal protocolLatch : STD_LOGIC_VECTOR(7 downto 0);
signal latchProtocol : STD_LOGIC;

-- datagram size register and signal
signal datagramSizeLatch : STD_LOGIC_VECTOR(15 downto 0);  
signal latchDatagramSize : STD_LOGIC;

-- current fragment offset and control signals
--signal fragmentOffset : STD_LOGIC_VECTOR(5 downto 0);
--signal incFragmentOffset : STD_LOGIC;
--signal rstFragmentOffset : STD_LOGIC;


signal sizeRemaining : STD_LOGIC_VECTOR(15 downto 0);	-- size of untransmitted data
--signal moreFragments : STD_LOGIC;						-- '0' = last fragment

signal idenLatch : STD_LOGIC_VECTOR (15 downto 0);		-- register to hold idenCnt value for all fragments
signal latchIden : STD_LOGIC;							-- latch idenLatch register

begin
	-- Transmit to destination IP
	ARPIP <= destinationIPLatch;
	
	-- Caclulate size remaining, whether this is the last fragment and the size of the next fragment to send
--	sizeRemaining <= datagramSizeLatch - (fragmentOffset & "0000000000");
	sizeRemaining <= datagramSizeLatch;
--	moreFragments <= '0' when sizeRemaining <= 1480 else '1';
	-- size is either sizeRemaining + 20 or 1024 + 20.  The header is always 20 bytes
--	datagramLen <= sizeRemaining + 20 when moreFragments = '0' else x"0414"; -- x"414" = 1024 + 20
	datagramLen <= sizeRemaining + 20; -- x"414" = 1024 + 20
	
	
	process (clk, rstn)
	begin
		if rstn = '0' then
			presState <= stIdle;
--      idenCnt <= "00" & x"009e5a"; -- akzare
      idenCnt <= (others => '0'); 
		elsif clk'event and clk = '1' then
			presState <= nextState;			-- change state
			idenCnt <= idenCnt + 1;			-- increment identification counter every cycle
			if latchRdData = '1' then		-- either latch wrData from RAM or get the next value
				wrData <= rdData;
			else
				wrData <= nextWrData;
			end if;
			if incCnt = '1' then			-- increment or clear counter
				cnt <= cnt + 1;
			elsif rstCnt = '1' then
				cnt <= (others => '0');
			end if;
			if latchDestinationIP = '1' then	-- latch destination IP
				destinationIPLatch <= destinationIP;
			end if;
--			if latchAddressOffset = '1' then	-- latch address offset
--				addressOffsetLatch <= addressOffset;
--			end if;
			if latchProtocol = '1' then			-- latch protocol
				protocolLatch <= protocol;
			end if;
			if latchDatagramSize = '1' then		-- latch size of datagram
				datagramSizeLatch <= datagramSize;
			end if;

--			if rstFragmentOffset = '1' then		-- reset fragment offset for first fragment
--				fragmentOffset <= (others => '0');
--			elsif incFragmentOffset = '1' then	-- increment it for each further fragment
--				fragmentOffset <= fragmentOffset + 1;
--			end if;
			if latchIden = '1' then				-- Get current value of upper bits of identification counter
				idenLatch <= idenCnt(25 downto 10);
			end if;
-- end fragmentation			

		end if; 
	end process;

-- IP datagram header format
--
--	0          4          8                      16      19             24                    31
--	--------------------------------------------------------------------------------------------
--	| Version  | *Header  |    Service Type      |        Total Length including header        |
--	|   (4)    |  Length  |     (ignored)        |                 (in bytes)                  |
--	--------------------------------------------------------------------------------------------
--	|           Identification                   | Flags |       Fragment Offset               |
--	|                                            |       |      (in 32 bit words)              |
--	--------------------------------------------------------------------------------------------
--	|    Time To Live     |       Protocol       |             Header Checksum                 |
--	|     (ignored)       |                      |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                   Source IP Address                                      |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                 Destination IP Address                                   |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                          Options (if any - ignored)               |       Padding        |
--	|                                                                   |      (if needed)     |
--	--------------------------------------------------------------------------------------------
--	|                                          Data                                            |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                          ....                                            |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--
-- * - in 32 bit words 

	process (presState, wrData, datagramLen, datagramSize, checksum,  cnt, sendDatagram,
			complete, idenLatch, destinationIPLatch, protocolLatch, 
			frameSent)
--			complete, idenLatch, destinationIPLatch, addressOffsetLatch, protocolLatch, 
--			frameSent, moreFragments, fragmentOffset)
	begin
		-- default signals and outputs
		rstCnt <= '0';
		incCnt <= '0';
		nextWrData <= wrData;
		newHeader <= '0';
		newByte <= '0';
		inByte <= (others => '0');
		wrRAM <= '0';
		wrAddr <= (others => '0');
--		rdRAM <= '0';
--		rdAddr <= (others => '0');
		sendFrame <= '0';
		frameSize <= (others => '0');
		latchRdData <= '0';
		datagramSent <= '0';
		latchAddressOffset <= '0';
		latchDestinationIP <= '0';
		latchProtocol <= '0';
		latchDatagramSize <= '0';
		latchIden <= '0';
--		incFragmentOffset <= '0';
--		rstFragmentOffset <= '0';
		
		case presState is
			when stIdle =>
				-- wait until told to transmit
				if sendDatagram = '0' then
					nextState <= stIdle;
				else
					-- latch all information about the datagram and set up first fragment
					nextState <= stSetHeader;
					rstCnt <= '1';
					newHeader <= '1';
--					rstFragmentOffset <= '1';
					latchDatagramSize <= '1';
					latchIden <= '1';
					latchAddressOffset <= '1';
					latchDestinationIP <= '1';
					latchProtocol <= '1';
				end if;
			
			when stSetHeader =>
				-- write header into RAM				
				if cnt = x"14" then
					-- header has been fully written so go to data stage
					nextState <= stWrChksumHi;
					nextWrData <= checksum (15 downto 8);
				else
					nextState <= stWrHeader;
					newByte <= '1';			-- send byte to checksum calculator
					-- choose wrData and inByte values
					-- inByte is the data for the checksum signals
					case cnt(4 downto 0) is
						-- version and header length
						when '0' & x"0" =>
							nextWrData <= x"45";
							inByte <= x"45";
						-- total length high byte
						when '0' & x"2" =>
							nextWrData <= datagramLen (15 downto 8);
							inByte <= datagramLen (15 downto 8);
						-- total length low byte
						when '0' & x"3" =>
							nextWrData <= datagramLen (7 downto 0);
							inByte <= datagramLen (7 downto 0);			
						-- identification high byte
						when '0' & x"4" =>
							nextWrData <= idenLatch(15 downto 8);
							inByte <= idenLatch(15 downto 8);
						-- identification low byte
						when '0' & x"5" =>
							nextWrData <= idenLatch (7 downto 0);
							inByte <= idenLatch (7 downto 0);
						-- flags and fragmentOffset high bits
						when '0' & x"6" =>
--							nextWrData <= "00" & moreFragments & fragmentOffset(5 downto 1);
--							inByte <= "00" & moreFragments & fragmentOffset(5 downto 1);
							nextWrData <= x"40"; -- akzare
							inByte <= x"40"; -- akzare
						-- fragmentOffset low byte
						when '0' & x"7" =>
--							nextWrData <= fragmentOffset(0) & "0000000";
--							inByte <= fragmentOffset(0) & "0000000";
							nextWrData <= x"00";
							inByte <= x"00";
						-- time to live
						when '0' & x"8" =>
							nextWrData <= x"40"; -- akzare : TTL 20->40
							inByte <= x"40"; -- akzare : 20->40
						-- protocol
						when '0' & x"9" =>
							nextWrData <= protocolLatch;
							inByte <= protocolLatch;					
						-- source IP for C, D, E, F
						when '0' & x"C" =>
							nextWrData <= DEVICE_IP(31 downto 24);
							inByte <= DEVICE_IP(31 downto 24);					
						when '0' & x"D" =>
							nextWrData <= DEVICE_IP(23 downto 16);
							inByte <= DEVICE_IP(23 downto 16);						
						when '0' & x"E" =>
							nextWrData <= DEVICE_IP(15 downto 8);
							inByte <= DEVICE_IP(15 downto 8);
						when '0' & x"F" =>
							nextWrData <= DEVICE_IP(7 downto 0);
							inByte <= DEVICE_IP(7 downto 0);				
						-- destination IP for 10, 11, 12, 13
						when '1' & x"0" =>
							nextWrData <= destinationIPLatch(31 downto 24);
							inByte <= destinationIPLatch(31 downto 24);
						when '1' & x"1" =>
							nextWrData <= destinationIPLatch(23 downto 16);
							inByte <= destinationIPLatch(23 downto 16);
						when '1' & x"2" =>
							nextWrData <= destinationIPLatch(15 downto 8);
							inByte <= destinationIPLatch(15 downto 8);					
						when '1' & x"3" =>
							nextWrData <= destinationIPLatch(7 downto 0);
							inByte <= destinationIPLatch(7 downto 0);						
						-- Service type and checksum which will be updated later
						when others =>
							nextWrData <= (others => '0');
							inByte <= (others => '0');
					end case;
				end if;
			
			when stWrHeader =>
				-- Write a byte to RAM
				if complete = '0' then
					-- Wait for RAM to acknowledge the write
					nextState <= stWrHeader;
					wrRAM <= '1';
--					wrAddr <= ("00000000" & Cnt) + ("000" & x"000E");
					wrAddr <= Cnt + x"0E";
				else
					-- When it does increment the counter and go to next header byte
					nextState <= stSetHeader;
					incCnt <= '1';
				end if;
			
			when stWrChksumHi =>
				-- Write high byte of the checksum to RAM
				if complete = '0' then
					-- Wait for RAM to acknowledge the write
					nextState <= stWrChksumHi;
					wrRAM <= '1';
--					wrAddr <= ("000" & x"000a") + ("000" & x"000E"); 
					wrAddr <= x"0A" + x"0E"; 
          
				else
					-- When it does write the lower byte
					nextState <= stWrChksumLo;
					nextWrData <= checksum (7 downto 0);
				end if;
			
			when stWrChksumLo =>
				-- Write low byte of the checksum to RAM
				if complete = '0' then
					nextState <= stWrChksumLo;
					wrRAM <= '1';
--					wrAddr <= ("000" & x"000B") + ("000" & x"000E");
					wrAddr <= x"0B" + x"0E";
				else
					-- When it does copy data from RAM to write location
					nextState <= stGetData;
				end if;

			when stGetData =>
				-- Read data from RAM if there is more left
--				if cnt = datagramLen then
				if cnt = x"014" then -- akzare
					-- If there is no more data left, wait until the frame completes sending
					if frameSent = '1' then
--						nextState <= stMoreFragments;
            nextState <= stIdle;
					else
						-- otherwise tell the frame to send until it does finish sending
						nextState <= stGetData;
						sendFrame <= '1';
						frameSize <= datagramLen (10 downto 0);
					end if;
				else
					-- if there is more data then perform a read from RAM
					if complete = '0' then
						-- Wait for RAM to acknowledge read
						nextState <= stGetData;
--						rdRAM <= '1';
--						rdAddr <= (addressOffsetLatch & (fragmentOffset + cnt(10)) & cnt(9 downto 0)) - 20;
					else
						-- Then get ready to write the data
						nextState <= stWrData;
						latchRdData <= '1';
					end if;
				end if;

			when stWrData =>
				-- Write one data byte
				if complete = '0' then
					-- Wait for RAM to acknowledge the write
					nextState <= stWrData;
					wrRAM <= '1';
--					wrAddr <= ("00000000" & Cnt) + ("000" & x"000E"); 
					wrAddr <= Cnt + x"0E"; 
				else
					-- When done, read another byte
					nextState <= stGetData;
					incCnt <= '1';
				end if;
				
--			when stMoreFragments =>
--				-- When the frame has finished transmitting
--				if moreFragments = '1' then
--					-- There are more fragments so set up data for the next fragment and generate it
--					nextState <= stSetHeader;
--					rstCnt <= '1';
--					newHeader <= '1';
--					incFragmentOffset <= '1';
--				else
--					-- There are no more fragments so wait for a new datagram to arrive
--					nextState <= stIdle;
--				end if;
			when others =>
		end case;
	end process;

	
	-- checksum calculator : see internet.vhd for comments
	checksumInt <= checksumLong(15 downto 0) + checksumLong(16);
	checksum <= NOT checksumInt;

	process (clk,rstn)
	begin
		if rstn = '0' then
			checkState <= stMSB;
			latchMSB <= (others => '0');
			checkSumLong <= (others => '0');
			valid <= '0';
			lastNewByte <= '0';
		elsif clk'event and clk = '1' then
			lastNewByte <= newByte;		
			case checkState is
				when stMSB =>
					if newHeader = '1' then
						checkState <= stMSB;
						checkSumLong <= (others => '0');
						valid <= '0';
					elsif newByte = '1' and lastNewByte = '0' then
						checkState <= stLSB;
						latchMSB <= inByte;
						valid <= '0';
					else
						checkState <= stMSB;
						valid <= '1';
					end if;
				when stLSB =>
					valid <= '0';		
					if newHeader = '1' then
						checkState <= stMSB;
						checkSumLong <= (others => '0');
					elsif newByte = '1' and lastnewByte = '0' then
						checkState <= stMSB;
						checkSumLong <= ('0' & checkSumInt) + ('0' & latchMSB & inByte);
					else
						checkState <= stLSB;
					end if;
				when others =>
					checkState <= stMSB;
					valid <= '0';
			end case;
		end if;
	end process;

end InternetSnd_arch;
