-------------------------------------------------------------------------------
-- icmp.vhd
--
-- Author(s):     Ashley Partis and Jorgen Peddersen
-- Created:       Jan 2001
-- Last Modified: Feb 2001
-- Last Modified: Dec 2009 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)
-- 
-- ICMP(ing) layer which responds only to echo requests with an echo reply.  
-- Any other ICMP messages are discarded / ignored.  Can respond to any ping
-- containing up to (64k - 8) bytes of data.
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity icmp is
    port (
        clk: in STD_LOGIC;										-- clock
        rstn: in STD_LOGIC;										-- asynchronous active low reset
        newDatagram: in STD_LOGIC;								-- asserted when a new datagram arrive
        datagramSize: in STD_LOGIC_VECTOR (15 downto 0);		-- size of the arrived datagram
        bufferSelect: in STD_LOGIC;								-- informs which IP buffer the data is in
   	  protocolIn: in STD_LOGIC_VECTOR (7 downto 0);			-- protocol type of the datagram
		  sourceIP: in STD_LOGIC_VECTOR (31 downto 0);			-- IP address that sent the message
		  filter_ip_addr: in STD_LOGIC;											-- respond only to authorized source IP addresses
        complete: in STD_LOGIC;									-- asserted when then RAM operation is complete
        rdData: in STD_LOGIC_VECTOR (7 downto 0);				-- read data bus from the RAM
--        rdRAM: out STD_LOGIC;									-- asserted to tell the RAM to read
--        rdAddr: out STD_LOGIC_VECTOR (18 downto 0);				-- read address bus to the RAM
        wrRAM: out STD_LOGIC;									-- asserted to tell the RAM to write
        wrData: buffer STD_LOGIC_VECTOR (7 downto 0);			-- write data bus to the RAM
--        wrAddr: out STD_LOGIC_VECTOR (18 downto 0);				-- write address bus to the RAM
        wrAddr: out STD_LOGIC_VECTOR (7 downto 0);				-- write address bus to the RAM
        sendDatagramSize: out STD_LOGIC_VECTOR (15 downto 0);	-- size of the ping to reply to
        sendDatagram: out STD_LOGIC;							-- tells the IP layer to send a datagram
        destinationIP: out STD_LOGIC_VECTOR (31 downto 0);		-- target IP of the datagram
        addressOffset: out STD_LOGIC_VECTOR (2 downto 0);		-- tells the IP layer which buffer the data is in
        protocolOut: out STD_LOGIC_VECTOR (7 downto 0)			-- tells the IP layer which protocol it is
    );
end icmp;

architecture icmp_arch of icmp is

-- state definitions
type STATETYPE is (stIdle, stGetICMPByte, stSetupWriteICMPByte, stWriteICMPByte,
		stWriteChkSum1, stWriteChkSum2, stWaitForCheckSum, stWaitForCheckSumCalc);
signal presState: STATETYPE;
signal nextState: STATETYPE;

-- buffer to hold the size of the ICMP message received, and to send
signal ICMPSize: STD_LOGIC_VECTOR (15 downto 0);
signal nextICMPSize: STD_LOGIC_VECTOR (15 downto 0);

-- counter to handle the message
signal incCnt: STD_LOGIC;
signal rstCnt: STD_LOGIC;
--signal cnt: STD_LOGIC_VECTOR (15 downto 0);
signal cnt: STD_LOGIC_VECTOR (7 downto 0);

-- signal and buffer to latch and hold the data from RAM
signal rdLatch: STD_LOGIC_VECTOR (7 downto 0);
signal latchRdData: STD_LOGIC;

-- signal to remember the previous wrData value
signal nextWrData: STD_LOGIC_VECTOR (7 downto 0);

-- read RAM from the correct address depending on this buffer
signal IPSourceBuffer: STD_LOGIC_VECTOR (1 downto 0);

-- signal to latch the inputs from the previous layer
signal latchDestinationIP: STD_LOGIC;

-- checksum signals - read internet.vhd for checksum commenting
signal checkState : STD_LOGIC;
CONSTANT stMSB : STD_LOGIC := '0';
CONSTANT stLSB : STD_LOGIC := '1';

signal checksumLong : STD_LOGIC_VECTOR (16 downto 0);
signal checksumInt : STD_LOGIC_VECTOR (15 downto 0);

signal latchMSB : STD_LOGIC_VECTOR (7 downto 0);

signal newHeader: STD_LOGIC;
signal newByte: STD_LOGIC;
signal inByte: STD_LOGIC_VECTOR (7 downto 0);

signal checksum: STD_LOGIC_VECTOR (15 downto 0);
signal valid: STD_LOGIC;

begin
	-- always set the IP protocol field to ICMP (01), and set address offset to 
	-- the location of the ICMP buffer
	protocolOut <= x"01";
	addressOffset <= "100";
	
	-- main clocked process
	process (rstn, clk)
	begin
		-- set up the asynchronous active low reset
		if rstn = '0' then
			presState <= stIdle;
		-- catch the rising clock edge
		elsif clk'event and clk = '1' then
			presState <= nextState;
			-- set the ICMP size and write data buses to their next values
			ICMPSize <= nextICMPSize;
			wrData <= nextWrData;
			-- latch the RAM data after reading from the RAM
			if latchRdData = '1' then
				rdLatch <= rdData;
			else
				rdLatch <= rdLatch;
			end if;
			-- increment and reset the counter asynchronously to avoid race conditions
			if incCnt = '1' then
				cnt <= cnt + 1;
			elsif rstCnt = '1' then
				cnt <= (others => '0');
			end if;
			-- latch the inputs and set the IP source buffer accordingly
			if latchDestinationIP = '1' then
				destinationIP <= sourceIP;
				if bufferSelect = '0' then
					IPSourceBuffer <= "01";
				else
					IPSourceBuffer <= "10";
				end if;
			end if;
		end if;
	
	end process;

-- ICMP data protocol unit header format
--
-- Standard echo request and reply ICMP header
--
--	0                      8                      16                                          31
--	--------------------------------------------------------------------------------------------
--	|   Type (8 = echo    |         Code         |                  Checksum                   |
--	| request, 0 = reply) |         (0)          |                                             |
--	--------------------------------------------------------------------------------------------
--	|                 Identifier                 |                Sequence Number              |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                       Optional Data                                      |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                                          ....                                            |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--

	-- main FSM process
	process (presState, newDatagram, datagramSize, rdLatch, ICMPSize, cnt, complete, wrData, checksum,
			protocolIn, filter_ip_addr, IPSourceBuffer)
	begin
		-- signal defaults
		incCnt <= '0';
		rstCnt <= '0';
		wrRAM <= '0';
		-- remember the values of wrData and ICMPSize by default
		nextWrData <= wrData;
		nextICMPSize <= ICMPSize;
		wrAddr <= (others => '0');
--		rdAddr <= (others => '0');
		latchRdData <= '0';
		sendDatagram <= '0';
		sendDatagramSize <= (others => '0');
--		rdRAM <= '0';
		newHeader <= '0';
		newByte <= '0';
		inByte <= (others => '0');
		latchDestinationIP <= '0';
	
		case presState is
			when stIdle =>
				-- wait for a new datagram to arrive with the correct protocol for ICMP
				if newDatagram = '0' or protocolIn /= 1 or filter_ip_addr /= '1' then
					nextState <= stIdle;
					rstCnt <= '1';
					newHeader <= '1';
				else
					nextState <= stGetICMPByte;
					-- latch or remember the inputs about the datagram from the previous layer
					latchDestinationIP <= '1';
					nextICMPSize <= datagramSize;
				end if;
				
			when stGetICMPByte =>
				-- if finished write the checksum and continue
				if cnt = ICMPSize(7 downto 0) then
					nextState <= stWaitForCheckSumCalc;
					-- if uneven number of bytes, pad the checksum with a byte of 0s
					if ICMPSize(0) = '1' then
						newByte <= '1';
						inByte <= (others => '0');
					end if;
				else
					-- read the current ICMP byte from RAM (using IPSourceBuffer
					-- for the correct address) according to count
					if complete = '0' then
						nextState <= stGetICMPByte;
--						rdRAM <= '1';
--						rdAddr <= '0' & IPSourceBuffer & cnt;
					else
						nextState <= stSetupWriteICMPByte;
						latchRdData <= '1';
					end if;
				end if;
			
			when stSetupWriteICMPByte =>
				nextState <= stWriteICMPByte;
				-- give the checksum the data
				newByte <= '1';
				-- set the ICMP data to send according the value of count
				case cnt is
					-- type
					when x"00" =>
						-- if we didn't get an echo request then ignore the ICMP packet
						if rdLatch /= 8 then
							nextState <= stIdle;
						end if;
						nextWrData <= (others => '0');

					-- code
					when x"01" =>
						nextWrData <= (others => '0');

					-- checksum upper byte - write 0s for now
					when x"02" =>
						nextWrData <= (others => '0');

					-- checksum lower byte
					when x"03" =>
						nextWrData <= (others => '0');
					
					-- all other cases - identifier, sequence number and data
					-- must be the same as what we received
					when others =>
						nextWrData <= rdLatch;
						inByte <= rdLatch;
				end case;

			when stWriteICMPByte =>
				-- write the new ICMP data
				if complete = '0' then
					nextState <= stWriteICMPByte;
					wrRAM <= '1';
--					wrAddr <= "100" & cnt;
					wrAddr <= cnt + x"22"; -- akzare
				else
					-- go back and get the next byte of data
					nextState <= stGetICMPByte;
					incCnt <= '1';
				end if;
			
			-- if there was an uneven number of bytes, then the checksum method will require an 
			-- extra clock cycle to work it out
			when stWaitForCheckSumCalc =>
				nextState <= stWaitForCheckSum;
			
			-- setup the write data bus to write the ICMP checksum
			when stWaitForCheckSum =>
				nextState <= stWriteChkSum1;
				nextWrData <= checksum (15 downto 8);
			
			when stWriteChkSum1 =>
				-- write the ICMP checksum MSB
				if complete = '0' then
					nextState <= stWriteChkSum1;
					wrRAM <= '1';
--					wrAddr <= "1000000000000000010";
					wrAddr <= x"24"; -- akzare
				else
					nextState <= stWriteChkSum2;
					-- setup the lower byte of the ICMP checksum to write
					nextWrData <= checksum (7 downto 0);
				end if;	

			when stWriteChkSum2 =>
				-- write the ICMP checksum LSB
				if complete = '0' then
					nextState <= stWriteChkSum2;
					wrRAM <= '1';
--					wrAddr <= "1000000000000000011";
					wrAddr <= x"25"; -- akzare
				else
					nextState <= stIdle;
					sendDatagram <= '1';
					sendDatagramSize <= ICMPSize;
				end if;	
			
			when others =>
		end case;
	end process;


	checksumInt <= 	checksumLong(15 downto 0) + checksumLong(16);
	checksum <= NOT checksumInt;

	process (clk,rstn)
	begin
		if rstn = '0' then
			checkState <= stMSB;
			latchMSB <= (others => '0');
			checkSumLong <= (others => '0');
			valid <= '0';
		elsif clk'event and clk = '1' then	
			case checkState is
				when stMSB =>
					if newHeader = '1' then
						checkState <= stMSB;
						checkSumLong <= (others => '0');
						valid <= '0';
					elsif newByte = '1' then
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
					elsif newByte = '1' then
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
end icmp_arch;
