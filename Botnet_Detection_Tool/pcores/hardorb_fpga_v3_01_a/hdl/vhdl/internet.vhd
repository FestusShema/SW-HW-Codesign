-------------------------------------------------------------------------------
-- internet.vhd
--
-- Author(s):     Ashley Partis and Jorgen Peddersen
-- Created:       Jan 2001
-- Last Modified: Feb 2001
-- Last Modified: Dec 2009 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)
-- 
-- IP layer for network stack project.  This accepts byte-streams of data from 
-- the ethernet layer and decodes the IP information to send data to the upper
-- protocols.  Reassembly is implemented and two incoming packets can be
-- reassembled at once.  Reassembly only works if incoming packets come in 
-- order.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
--use work.global_constants.all;

entity internet is
    generic (
    C_DEBUG_MODE : integer := 0;	-- 0 = disable, 1 = enable
    DEVICE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a" -- 192.168.1.10
    );                
    port (
		clk: in STD_LOGIC;								-- clock
		rstn: in STD_LOGIC;								-- asynchronouse active low reset
--		complete: in STD_LOGIC;							-- control signal from ram arbitrator
		newFrame: in STD_LOGIC;							-- new frame received from the layer below
		frameType: in STD_LOGIC;						-- frame type = '1' for IP
		newFrameByte: in STD_LOGIC;						-- signals a new byte in the stream
		frameData: in STD_LOGIC_VECTOR (7 downto 0);	-- data is streamed in here
--		endFrame: in STD_LOGIC;							-- signals the end of a frame
--		frameValid: in STD_LOGIC;						-- determines validity of frame when endFrame is high
		newDatagram: out STD_LOGIC;						-- an IP datagram has been fully received
--		bufferSelect: out STD_LOGIC;					-- indicates location of data in RAM, '0' = 10000, '1' = 20000
		datagramSize: out STD_LOGIC_VECTOR (15 downto 0);	-- size of the datagram received
		protocol: out STD_LOGIC_VECTOR (7 downto 0);		-- protocol type of datagram

------------------------ TEST -------------------    
tst_ipcnt: out STD_LOGIC_VECTOR (5 downto 0);
tst_ipinByte: out STD_LOGIC_VECTOR (7 downto 0);
tst_ipnewByte: out STD_LOGIC;
tst_ippresstate: out STD_LOGIC_VECTOR (3 downto 0);
------------------------ TEST -------------------    
    
		sourceIP: out STD_LOGIC_VECTOR (31 downto 0);		-- lets upper protocol know the source IP
		destIP : out STD_LOGIC_VECTOR (31 downto 0)			-- lets the filter know the destination IP --Adil
--		wrRAM: out STD_LOGIC								-- signal to write to the RAM
--		wrData: out STD_LOGIC_VECTOR (7 downto 0);			-- data to write to the RAM
--		wrAddr: out STD_LOGIC_VECTOR (18 downto 0)			-- address lines to the RAM for writing
--		timeLED0: out STD_LOGIC;							-- indicates if buffer 0 is busy
--		timeLED1: out STD_LOGIC								-- indicates if buffer 1 is busy
    );
end internet;

architecture internet_arch of internet is

-- signal declarations
-- FSM states
--type STATETYPE is (stIdle, stGetHeaderLen, stGetHeaderByte, stStoreHeaderByte, 
--					stGetDataByte, stSetupWriteDataByte, stCompleteFragment, stDoWrite, stgetNewByte);
type STATETYPE is (stIdle, stGetHeaderLen, stGetHeaderByte, stStoreHeaderByte, 
					stCompleteFragment, stgetNewByte);
signal presState: STATETYPE;
signal nextState: STATETYPE;
signal returnState: STATETYPE;	-- Used to return from RAM 'subroutines' 

signal headerLen: STD_LOGIC_VECTOR (5 downto 0);				-- IP datagram header length
signal nextHeaderLen: STD_LOGIC_VECTOR (5 downto 0);			-- signal for the next header lengh
signal datagramLen: STD_LOGIC_VECTOR (10 downto 0);				-- IP datagram total length in bytes
signal nextDatagramLen: STD_LOGIC_VECTOR (10 downto 0);			-- signal for the next datagram length
signal dataLen: STD_LOGIC_VECTOR (10 downto 0);					-- IP datagram data length in bytes
signal nextDataLen: STD_LOGIC_VECTOR (10 downto 0);				-- signal for the next data length

signal incCnt: STD_LOGIC;										-- increments byte address counter
signal rstCnt: STD_LOGIC;										-- resets byte address counter
signal cnt: STD_LOGIC_VECTOR (5 downto 0);						-- byte address counter for the frame received

--signal incWrCnt: STD_LOGIC;										-- increments the write address counter
--signal rstWrCnt: STD_LOGIC;										-- resets the write address counter
--signal wrCnt: STD_LOGIC_VECTOR (15 downto 0);					-- write address counter for storing that data

--signal doWrite: STD_LOGIC;										-- tell RAM controller to write data
signal getNewByte: STD_LOGIC;									-- wait for new data on the stream

signal latchFrameData: STD_LOGIC;								-- latch in the data from the stream
signal frameDataLatch: STD_LOGIC_VECTOR (7 downto 0);			-- register to hold latched data

signal targetIP: STD_LOGIC_VECTOR (31 downto 0);				-- stores target IP (destination)
signal shiftInTargetIP: STD_LOGIC;								-- signal to shift in target IP

signal shiftInSourceIP: STD_LOGIC;								-- stores source IP
signal latchProtocol: STD_LOGIC;								-- signal to shift in source IP

-- checksum signals
signal checkState : STD_LOGIC;
CONSTANT stMSB : STD_LOGIC := '0';
CONSTANT stLSB : STD_LOGIC := '1';

signal checksumLong : STD_LOGIC_VECTOR (16 downto 0);			-- stores 2's complement sum
signal checksumInt : STD_LOGIC_VECTOR (15 downto 0);			-- stores 1's complement sum

signal latchMSB : STD_LOGIC_VECTOR (7 downto 0);				-- latch in first byte


signal newHeader: STD_LOGIC;									-- resets checksum
signal newByte: STD_LOGIC;										-- indicate new byte
signal lastNewByte : STD_LOGIC;									-- detect changes in newByte

signal inByte: STD_LOGIC_VECTOR (7 downto 0);					-- byte to calculate

signal checksum: STD_LOGIC_VECTOR (15 downto 0);				-- current checksum

-- bufferSelect is used both to indicate which area in RAM to write to
-- and to indicate which buffer control signals are to operate on
--signal nextBufferSelect: STD_LOGIC;								-- allows memory of bufferSelect
--signal bufferSelectSig : STD_LOGIC;								-- allows memory of bufferSelect

signal identification: STD_LOGIC_VECTOR (15 downto 0);  		-- identification field
signal shiftInIdentification: STD_LOGIC;						-- signal to shift in identification

signal fragmentOffset: STD_LOGIC_VECTOR (12 downto 0);			-- fragment offset field
signal shiftInFragmentOffset: STD_LOGIC;						-- signal to shift in offset
signal moreFragments : STD_LOGIC;								-- more fragments flag
signal latchMoreFragments : STD_LOGIC;							-- signal to determine MF flag

-- The ident signals are of the form "source IP : protocol : identification" and
-- are used in reassembly.
--signal targetIdent: STD_LOGIC_VECTOR (55 downto 0);				-- incoming frame's ident
--signal ident0: STD_LOGIC_VECTOR (55 downto 0);					-- current ident for buffer 0
--signal ident1: STD_LOGIC_VECTOR (55 downto 0);					-- current ident for buffer 1
--signal latchIdent: STD_LOGIC;									-- latch targetIdent into specified buffer ident
--signal resetIdent: STD_LOGIC;									-- clear ident of specified buffer to indicate a vacant buffer

--signal position0: STD_LOGIC_VECTOR (15 downto 0);				-- stores expected offset of next fragment
--signal position1: STD_LOGIC_VECTOR (15 downto 0);				-- stores expected offset of next fragment
--signal updatePosition: STD_LOGIC;								-- add dataLen to current position
--signal resetPosition: STD_LOGIC;								-- set position to be dataLen

constant TIMERWIDTH : INTEGER := 7;							-- can be used to vary timeout length

signal timeout0: STD_LOGIC_VECTOR (TIMERWIDTH - 1  downto 0);	-- timeout counter
--signal timeout1: STD_LOGIC_VECTOR (TIMERWIDTH - 1  downto 0);	-- timeout counter
signal resetTimeout: STD_LOGIC;		-- start timeout counter

constant FULLTIME: STD_LOGIC_VECTOR (TIMERWIDTH - 1 downto 0) := (others => '1'); -- last value of timeout counter

signal sourceIPSig : STD_LOGIC_VECTOR (31 downto 0);			-- internal signal for output
signal protocolSig : STD_LOGIC_VECTOR (7 downto 0);				-- internal signal for output	

begin
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_ipcnt <= cnt;
tst_ipinByte <= inByte;
tst_ipnewByte <= newByte;
tst_ippresstate <= conv_std_logic_vector(STATETYPE'pos(presState), 4);
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_ipcnt <= (others => '0');
tst_ipinByte <= (others => '0');
tst_ipnewByte <= '0';
tst_ippresstate <= (others => '0');
end generate;
------------------------ TEST -------------------    

	-- These signals are used instead of buffer ports
	sourceIP <= sourceIPSig;
	protocol <= protocolSig;
	destIP <= TargetIP;		-- Adil
--	bufferSelect <= bufferSelectSig;
	
	-- Indicate when buffers are busy
--	timeLED0 <= '0' when timeout0 = FULLTIME or ident0 = 0 else '1';
--	timeLED1 <= '0' when timeout1 = FULLTIME or ident1 = 0 else '1';
	
	-- Some definitions to make further code simpler
--	targetIdent <= sourceIPSig & protocolSig & identification;
	dataLen <= datagramLen - ("00000" & headerLen);
	
	-- main clocked process
	process (rstn, clk)
	begin
		if rstn = '0' then  -- only need to reset required signals
			presState <= stIdle;
			returnState <= stIdle;
--			ident0 <= (others => '0');
--			ident1 <= (others => '0');
			timeout0 <= FULLTIME;
--			timeout1 <= FULLTIME;

		elsif clk'event and clk = '1' then

			-- Go to next state wither directly or via a RAM state.
			-- If a RAM write or a new byte from the data stream are requested,
			-- the state machine stores nextState in returnState and goes to the
			-- required state.  After completion, the state machine will go to 
			-- returnState. This is like a 'subroutine' in the state machine.
--			if doWrite = '1' then		
--				presState <= stDoWrite;
--				returnState <= nextState;
--			elsif getNewByte = '1' then
			if getNewByte = '1' then
				presState <= stGetNewByte;
				returnState <= nextState;
			else
				presState <= nextState;
			end if;
			
			-- increment and reset the counter synchronously to avoid race conditions
			if incCnt = '1' then
				cnt <= cnt + 1;
			elsif rstCnt = '1' then
				cnt <= (others => '0');
			end if;
			
--			-- increment and reset the write address counter synchronously
--			if incWrCnt = '1' then
--				wrCnt <= wrCnt + 1;
--			elsif rstWrCnt = '1' then
--				wrCnt <= (others => '0');
--			end if;
			
			-- latch data read from RAM
			if latchFrameData = '1' then
				frameDataLatch <= frameData;
			end if;
			
			-- these signals must remember their values once set
			headerLen <= nextHeaderLen;
			datagramLen <= nextDatagramLen;

			-- shift registers and latches to hold important data
			if shiftInSourceIP = '1' then
				sourceIPSig <= sourceIPSig(23 downto 0) & frameDataLatch;
			end if;

			if shiftInTargetIP = '1' then
				TargetIP <= TargetIP(23 downto 0) & frameDataLatch;
			end if;

			if latchProtocol = '1' then
				protocolSig <= frameDataLatch;
			end if;			

			if shiftInFragmentOffset = '1' then
				fragmentOffset <= fragmentOffset (4 downto 0) & frameDataLatch;
			end if;

			if latchMoreFragments = '1' then
				moreFragments <= frameDataLatch(5);
			end if;

			if shiftInIdentification = '1' then
				identification <= identification (7 downto 0) & frameDataLatch;
			end if;
			
			-- bufferSelect will remember its previous value
--			bufferSelectSig <= nextBufferSelect;
			
			-- handle timeout counters, resetTimeout will only reset the current buffer
			if resetTimeout = '1' then
--				if bufferSelectSig = '0' then
					timeout0 <= (others => '0');
--				else
--					timeout1 <= (others => '0');
--				end if;
			else
				-- increment timeout counters but don't let them overflow
				if timeout0 /= FULLTIME then
					timeout0 <= timeout0 + 1;
				else
					timeout0 <= FULLTIME;
				end if;
--				if timeout1 /= FULLTIME then
--					timeout1 <= timeout1 + 1;
--				else
--					timeout1 <= FULLTIME;
--				end if;
			end if;
			
			-- the following signals will operate only on the current buffer which
			-- is chosen with bufferSelect.
--			if bufferSelectSig = '0' then
--				-- manage the ident register of the buffer
--				if latchIdent = '1' then
--					ident0 <= targetIdent;	
--				elsif resetIdent = '1' then
--					ident0 <= (others => '0');
--				end if;
--
--				-- manage the position register of the buffer
--				if resetPosition = '1' then
--					position0 <= "00000" & dataLen;
--				elsif updatePosition = '1' then
--					position0 <= position0 + dataLen;
--				end if;
--
--			else				
--				-- manage the ident register of the buffer
--				if latchIdent = '1' then
--					ident1 <= targetIdent;
--				elsif resetIdent = '1' then
--					ident1 <= (others => '0');
--				end if;
--				
--				-- manage the position register of the buffer		
--				if resetPosition = '1' then
--					position1 <= "00000" & dataLen;
--				elsif updatePosition = '1' then
--					position1 <= position1 + dataLen;
--				end if;	
--			end if;
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

--	process (presState, returnState, cnt, frameDataLatch, datagramLen, headerLen, dataLen, newFrame, wrCnt,
--			complete, frameType, checksum, targetIP, bufferSelectSig, targetIdent,
--			position0, position1, ident0, ident1, fragmentOffset, moreFragments, timeout0, timeout1,
--			endFrame, newFrameByte, frameValid)

	process (presState, returnState, cnt, frameDataLatch, datagramLen, headerLen, dataLen, newFrame,
			frameType, checksum, targetIP, timeout0,
			fragmentOffset, moreFragments, 
			newFrameByte)
	begin
		-- signal defaults
--		wrRAM <= '0';
--		wrData <= (others => '0');
--		wrAddr <= (others => '0');
		datagramSize <= (others => '0');
		incCnt <= '0';
		rstCnt <= '0';
--		incWrCnt <= '0';
--		rstWrCnt <= '0';
		newDataGram <= '0';
		-- the following two signals remember their previous value if not reassigned
		nextHeaderLen <= headerLen;
		nextDatagramLen <= datagramLen;
--		doWrite <= '0';
		getNewByte <= '0';
		latchFrameData <= '0';
		shiftInSourceIP <= '0';
		shiftInTargetIP <= '0';
		latchProtocol <= '0';
		newHeader <= '0';
		newByte <= '0';
		inByte <= (others => '0');
		latchMoreFragments <= '0';
		shiftInFragmentOffset <= '0';

		shiftInIdentification <= '0';		
--		nextBufferSelect <= bufferSelectSig;
--		latchIdent <= '0';
--		resetIdent <= '0';
--		updatePosition <= '0';
--		resetPosition <= '0';
		resetTimeout <= '0';
	
		case presState is
			when stIdle =>
				resetTimeout <= '1';
        -- wait for the arrival of a new frame that has a frameType of 1
				if newFrame = '0' or frameType = '0' then
					nextState <= stIdle;
				else
					-- reset the counters for the next datagram
					rstCnt <= '1';
--					rstWrCnt <= '1';
					newHeader <= '1';
					nextState <= stGetHeaderLen;
					-- get header length and version information
					getNewByte <= '1';
				end if;

			when stGetHeaderLen =>
				-- check ip version
				if frameDataLatch (7 downto 4) /= 4 then
					nextState <= stIdle;
				else
					nextState <= stGetHeaderByte;
					-- send data to checksum machine
					inByte <= frameDataLatch;
					newByte <= '1';
					-- get the header length in bytes, rather than 32-bit words
					nextHeaderLen <= frameDataLatch (3 downto 0) & "00";
				end if;
			
			when stGetHeaderByte =>
				-- if we've finished getting the headers and processing them, start on the data
				-- once finished, refragmenting will come next
				if cnt = headerLen then
					-- only operate on data meant for us, or broadcast data
					if checksum = 0 and (targetIP = DEVICE_IP or targetIP = x"FFFFFFFF") then    
					
-- akzare
						nextState <= stCompleteFragment;
--					resetTimeout <= '1';	-- start/restart timer
--					latchIdent <= '1';		-- allocate buffer to data
--					if fragmentOffset = 0 then	-- check if this is the first fragment
--						resetPosition <= '1';	-- give position initial value
--					else
--						updatePosition <= '1';  -- or add to the amount of data stored
--					end if;
            
-- akzare
--						-- determine which buffer should be used to handle the data
--						if ident0 = targetIdent and timeout0 /= FULLTIME then
--							-- the ident matches and the timeout counter has not expired
--							nextBufferSelect <= '0';
--							-- accept the frame if its offset matches what we think it should be
--							-- this drops out of order and duplicate frames.
--							if position0 = fragmentOffset & "000" then
--								nextState <= stGetDataByte;
--							else
--								nextState <= stIdle;
--							end if;												
--						elsif ident1 = targetIdent and timeout1 /= FULLTIME then
--							-- the ident matches and the timeout counter has not expired							
--							nextBufferSelect <= '1';
--							-- accept the frame if its offset matches what we think it should be
--							-- this drops out of order and duplicate frames.
--							if position1 = fragmentOffset & "000" then
--								nextState <= stGetDataByte;
--							else
--								nextState <= stIdle;
--							end if;												
--						elsif (ident0 = 0 or timeout0 = FULLTIME) and fragmentOffset = 0 then
--							-- The ident doesn't match either of the buffers so check if buffer 0
--							-- is free.  If ident = 0 or the timeout has expired then the buffer is free
--							-- This must be the first fragment if it is to go here so also check the offset
--							nextState <= stGetDataByte;
--							nextBufferSelect <= '0';
--						elsif (ident1 = 0 or timeout1 = FULLTIME) and fragmentOffset = 0 then
--							-- The ident doesn't match either of the buffers so check if buffer 1
--							-- is free.  If ident = 0 or the timeout has expired then the buffer is free
--							-- This must be the first fragment if it is to go here so also check the offset
--							nextState <= stGetDataByte;
--							nextBufferSelect <= '1';
--						else
--							nextState <= stIdle;
--						end if;
					else 
						-- ignore frame as it wasn't for us
						nextState <= stIdle;
					end if; 
					
				-- otherwise get the next header byte from RAM
				else
					nextState <= stStoreHeaderByte;
					getNewByte <= '1';
					resetTimeout <= '1';
				end if;
				
			when stStoreHeaderByte =>
				nextState <= stGetHeaderByte;
				-- operate on each value of the header received according to count
				-- count will be one higher than the last byte received, as it is incremented
				-- at the same time as the data is streamed in, so
				-- when the data is seen to be available, count should also be one higher
				
				-- Send data to checksum process
				newByte <= '1';
				inByte <= frameDataLatch;
				
				-- Operate on data in the header
				case cnt(4 downto 0) is				
					when "00011" =>
						nextDatagramLen (10 downto 8) <= frameDataLatch (2 downto 0);
					when "00100" =>
						nextDatagramLen (7 downto 0) <= frameDataLatch;
					when "00101" | "00110" =>
						shiftInIdentification <= '1';
					when "00111" =>
						shiftInFragmentOffset <= '1';
						latchMoreFragments <= '1';
					when "01000" =>
						shiftInFragmentOffset <= '1';
					when "01010" =>
						latchProtocol <= '1';
					when "01101" | "01110" | "01111" | "10000" =>
						shiftInSourceIP <= '1';
					when "10001" | "10010" | "10011" | "10100" =>					
						shiftInTargetIP <= '1';
					when others =>
				end case;
			
--			when stGetDataByte =>
--				-- if we haven't finished receiving the data, then
--				if cnt /= datagramLen then
--					nextState <= stSetupWriteDataByte;
--					-- read an IP data byte from the data stream...
--					getNewByte <= '1';
--				elsif endFrame = '1' and frameValid = '1' then
--					-- this means that the frame is finished and was valid
--					-- so update the buffer data and go to final state
--					nextState <= stCompleteFragment;
--					resetTimeout <= '1';	-- start/restart timer
--					latchIdent <= '1';		-- allocate buffer to data
----					if fragmentOffset = 0 then	-- check if this is the first fragment
----						resetPosition <= '1';	-- give position initial value
----					else
----						updatePosition <= '1';  -- or add to the amount of data stored
----					end if;
--				elsif endFrame = '1' then
--					-- the frame is complete but not valid so ignore it
--					nextState <= stIdle;
--				else
--					-- the frame is not complete so keep looping until it is
--					nextState <= stGetDataByte;
--				end if;
				
--			when stSetupWriteDataByte =>
--				nextState <= stGetDataByte;
--				--Set up to write the byte that was read in stGetDataByte to RAM
--				doWrite <= '1';
----				wrData <= frameDataLatch;

			when stCompleteFragment =>
				-- Signal the transport protocols if the datagram is finished
				-- or await next frame.
				nextState <= stIdle;
				if moreFragments = '0' then 
					-- Last frame so :
					newDatagram <= '1';		-- notify higher protocols it's ready
--					resetIdent <= '1';		-- free buffer for next time
--					if bufferSelectSig = '0' then	-- output datagram size from correct buffer
--						datagramSize <= position0;
					datagramSize <= "00000" & dataLen;

--					else
--						datagramSize <= position1;
--					end if;
				end if;
				
--			when stDoWrite =>
--				-- Wait for RAM write request to be serviced
--				if complete = '0' then
--					-- keep signals asserted until complete is high
--					nextState <= stDoWrite;
--					wrRAM <= '1';
----					-- The address is based on the fragment offset and buffer
----					if bufferSelectSig = '0' then
----						wrAddr <= "001" & (wrCnt + (fragmentOffset & "000"));
----					else
----						wrAddr <= "010" & (wrCnt + (fragmentOffset & "000"));
----					end if;
----					wrData <= frameDataLatch;
--				else
--					-- when write is finished, go to returnState
--					nextState <= returnState;
--					incWrCnt <= '1';
--				end if;

			when stGetNewByte =>
				if timeout0 = FULLTIME then
					nextState <= stIdle;
        elsif newFrameByte = '0' then
					-- wait for new byte to arrive
					nextState <= stgetNewByte;
				else
					-- latch new byte and go to returnState
					nextState <= returnState;
					incCnt <= '1';
					latchFrameData <= '1';
				end if;
			when others =>
		end case;
	end process;
	
	-- Perform 2's complement to one's complement conversion, and invert output
	checksumInt <= checksumLong(15 downto 0) + checksumLong(16);
	checksum <= NOT checksumInt;

	process (clk,rstn)
	begin
		if rstn = '0' then
			checkState <= stMSB;
			latchMSB <= (others => '0');
			checkSumLong <= (others => '0');
			lastNewByte <= '0';
		elsif clk'event and clk = '1' then
			-- this is used to check only for positive transitions
			lastNewByte <= newByte;		
			
			case checkState is
				when stMSB =>
					if newHeader = '1' then
						-- reset calculation
						checkState <= stMSB;
						checkSumLong <= (others => '0');
					elsif newByte = '1' and lastNewByte = '0' then
						-- latch MSB of 16 bit data
						checkState <= stLSB;
						latchMSB <= inByte;
					else
						checkState <= stMSB;
					end if;
				when stLSB =>
					if newHeader = '1' then
						-- reset calculation
						checkState <= stMSB;
						checkSumLong <= (others => '0');
					elsif newByte = '1' and lastnewByte = '0' then
						-- add with 2's complement arithmetic (convert to 1's above)
						checkState <= stMSB;
						checkSumLong <= ('0' & checkSumInt) + ('0' & latchMSB & inByte);
					else
						checkState <= stLSB;
					end if;
				when others =>
					checkState <= stMSB;
			end case;
		end if;
	end process;	
end internet_arch;
