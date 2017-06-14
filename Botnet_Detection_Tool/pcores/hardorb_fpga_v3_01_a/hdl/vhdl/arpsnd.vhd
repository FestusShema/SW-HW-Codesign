-------------------------------------------------------------------------------
-- arpsnd.vhd
--
-- Author(s):     Ashley Partis and Jorgen Peddersen
-- Created:       Feb 2001
-- Last Modified: Feb 2001
-- Last Modified: Feb 2010 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)
-- 
-- Sits transparently between the internet send and ethernet send layers.
-- All frame send requests from the internet layer are passed through after
-- the destination MAC is either looked up from the ARP table, or an ARP 
-- request is sent out and an ARP reply is receiver.  ARP replies are created
-- and then sent to the ethernet later after being requested by the ARP layer.  
-- After each frame is passed on to the ethernet layer and then sent, it informs
-- the layer above that the frame has been sent.
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity ARPSnd is
    generic (
    C_DEBUG_MODE : integer := 0;	-- 0 = disable, 1 = enable
    DEVICE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a"; -- 192.168.1.10
    DEVICE_MAC: STD_LOGIC_VECTOR (47 downto 0) := x"000A3501CB9E"
    );                
    port (
        clk: in STD_LOGIC;								-- clock
        rstn: in STD_LOGIC;								-- aysnchronous active low rese
        complete: in STD_LOGIC;							-- RAM complete signal
        frameSent: in STD_LOGIC;						-- input from the PHY that it's processed our frame
        sendFrame: in STD_LOGIC;						-- send an ethernet frame - from IP layer
        frameLen: in STD_LOGIC_VECTOR (10 downto 0);	-- input from IP giving frame length
        targetIP: in STD_LOGIC_VECTOR (31 downto 0);	-- destination IP from the internet layer
        ARPEntryValid: in STD_LOGIC;					-- input from ARP indicating that it contains the requested IP
        genARPReply: in STD_LOGIC;						-- input from ARP requesting an ARP reply
        genARPIP: in STD_LOGIC_VECTOR (31 downto 0);	-- input from ARP saying which IP to send a reply to
        lookupMAC: in STD_LOGIC_VECTOR (47 downto 0);	-- input from ARP giving a requested MAC
        lookupIP: out STD_LOGIC_VECTOR (31 downto 0);	-- output to ARP requesting an IP to be looked up in the table
        sendingReply: out STD_LOGIC;					-- output to ARP to tell it's sending the ARP reply
        targetMAC: out STD_LOGIC_VECTOR (47 downto 0);	-- destination MAC for the physical layer
        genFrame: out STD_LOGIC;						-- tell the ethernet layer (PHY) to send a frame
        frameType: out STD_LOGIC;						-- tell the PHY to send an ARP frame or normal IP datagram
        frameSize: out STD_LOGIC_VECTOR (10 downto 0);	-- tell the PHY what size the frame size is
        idle: out STD_LOGIC;							-- idle signal
        sendingFrame: out STD_LOGIC; 					-- tell the IP layer that we're sending their data
        wrRAM: out STD_LOGIC;							-- write RAM signal to the RAM
        wrData: buffer STD_LOGIC_VECTOR (7 downto 0);	-- write data bus to the RAM
------------------------ TEST -------------------    
tst_arpxmitpresstate: out STD_LOGIC_VECTOR (3 downto 0);
------------------------ TEST -------------------    
        wrAddr: out STD_LOGIC_VECTOR (7 downto 0)		-- write address bus to the RAM
    );
end ARPSnd;

architecture ARPSnd_arch of ARPSnd is

-- FSM state definitions
TYPE STATETYPE is (stIdle, stGenARPReply, stGetReplyMAC, stStoreARPReply, stCheckARPEntry, stCheckARPEntry2,
			stGenARPRequest, stStoreARPRequest, stWaitForValidEntry, stGenEthFrame);
signal presState: STATETYPE;
signal nextState: STATETYPE;

-- signals to synchronously increment and reset the counter
signal cnt:  STD_LOGIC_VECTOR (4 downto 0);
signal incCnt: STD_LOGIC;
signal rstCnt: STD_LOGIC;

-- next write data value
signal nextWrData: STD_LOGIC_VECTOR (7 downto 0);

-- signals and buffers to latch input data
signal latchTargetIP: STD_LOGIC;
signal latchInternetIP: STD_LOGIC;
signal latchedIP: STD_LOGIC_VECTOR (31 downto 0);
signal latchTargetMAC: STD_LOGIC;
signal latchedMAC: STD_LOGIC_VECTOR (47 downto 0);
signal latchFrameSize: STD_LOGIC;
signal latchedFrameSize: STD_LOGIC_VECTOR (10 downto 0);

-- 20 second ARP reply timeout counter at 50MHz
signal ARPTimeoutCnt: STD_LOGIC_VECTOR (29 downto 0);
signal rstARPCnt: STD_LOGIC;
signal ARPCntOverflow: STD_LOGIC;

-- main clocked process
begin
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_arpxmitpresstate <= conv_std_logic_vector(STATETYPE'pos(presState), 4);
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_arpxmitpresstate <= (others => '0');
end generate;
------------------------ TEST -------------------    
	process (rstn, clk)
	begin
		-- set up the asynchronous active low reset
		if rstn = '0' then
			presState <= stIdle;
		-- catch the rising edge of the clock
		elsif clk'event and clk = '1' then
			presState <= nextState;
			-- set the write data bus to it's next value
			wrData <= nextWrData;
      
  
			-- increment and reset the counter synchronously to avoid race conditions
			if incCnt = '1' then
				cnt <= cnt + 1;
			elsif rstCnt = '1' then
				cnt <= (others => '0');
			end if;
			-- set the ARP counter to 1
			if rstARPCnt = '1' then
				ARPTimeoutCnt <= "00" & x"0000001";
				ARPCntOverflow <= '0';
			-- if the ARP counter isn't 0, keep incrementing it
			elsif ARPTimeoutCnt /= "00" & x"0000000" then
				ARPTimeoutCnt <= ARPTimeoutCnt + 1;
				ARPCntOverflow <= '0';
			-- if the counter is 0, set the overflow signal
			else
				ARPCntOverflow <= '1';
			end if;
			-- latch the IP to send the ARP request to, send the ARP reply to or to lookup
			-- from either the ARP layer or internet send layer
			if latchTargetIP = '1' then
				latchedIP <= genARPIP;
			elsif latchInternetIP = '1' then
				latchedIP <= targetIP;
			end if;
			-- latch the MAC from the ARP table that has been looked up
			if latchTargetMAC = '1' then
				latchedMAC <= lookupMAC;
			end if;
			-- latch the size of the frame size to send from the internet layer
			if latchFrameSize = '1' then
        if genARPReply = '1' then    
				  latchedFrameSize <= "000" & x"2A";
        else
				  latchedFrameSize <= frameLen + 14;
        end if;
			end if;
		end if;
	end process;

-- ARP header format
-- 
--	0                      8                      16                                          31
--	--------------------------------------------------------------------------------------------
--	|                Hardware Type               |               Protocol Type                 |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|   Hardware Address  |   Protocol Address   |                 Operation                   |
--	|       Length        |       Length         |                                             |
--	--------------------------------------------------------------------------------------------
--	|                          Sender Hardware Address (MAC) (bytes 0 - 3)                     |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|           Sender MAC (bytes 4 - 5)         |        Sender IP Address (bytes 0 - 1)      |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|            Sender IP (bytes 2 - 3)         |    Target Hardware Address (bytes 0 - 1)    |
--	|                                            |                                             |
--	--------------------------------------------------------------------------------------------
--	|                                  Target MAC (bytes 2 - 5)                                |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--	|                               Target IP Address (bytes 0 - 3)                            |
--	|                                                                                          |
--	--------------------------------------------------------------------------------------------
--

	-- main FSM process
	process (presState, sendFrame, genARPReply, cnt, complete, latchedIP, latchedMAC, wrData,
			ARPEntryValid, latchedFrameSize, ARPCntOverflow, frameSent)
	begin
		-- remember the value of the RAM write data bus by default
		nextWrData <= wrData;
		-- lookup the latched IP by default
		lookupIP <= latchedIP;
		wrRAM <= '0';
		wrAddr <= (others => '0');
		rstCnt <= '0';
		incCnt <= '0';
		sendingReply <= '0';
		idle <= '0';
		targetMAC <= (others => '0');
		
    genFrame <= '0';
    
		frameType <= '0';
		sendingFrame <= '0';
		frameSize <= (others => '0');
		latchFrameSize <= '0';
		latchInternetIP <= '0';
		latchTargetIP <= '0';
		latchTargetMAC <= '0';
		rstARPCnt <= '0';
    
		case presState is
			when stIdle =>
				-- wait for a frame to arrive
				if sendFrame = '0' and genARPReply = '0' then
					nextState <= stIdle;
					idle <= '1';
					rstCnt <= '1';
				-- create an ARP reply when asked, giving ARP message priority
				elsif genARPReply = '1' then
					nextState <= stGetReplyMAC;
					-- latch the target IP from the ARP layer
					latchTargetIP <= '1';
					latchFrameSize <= '1'; -- akzare
				-- pass through the frame form the IP layer, 
				else
					nextState <= stCheckARPEntry;
					-- latch input from the IP layer
					latchInternetIP <= '1';
					latchFrameSize <= '1';
				end if;
			
			-- create the ARP reply, getting the target MAC from the ARP table
			when stGetReplyMAC =>
				nextState <= stGenARPReply;
				lookupIP <= latchedIP;
				latchTargetMAC <= '1';
				-- tell the ARP table that we're sending the reply
				sendingReply <= '1';
			
			-- generate each byte of the ARP reply according to count
			when stGenARPReply =>
				nextState <= stStoreARPReply;
				case cnt is
					-- Hardware type MSB
					when "00000" =>
						nextWrData <= (others => '0');
					
					-- Hardware type LSB
					when "00001" =>
						nextWrData <= x"01";
						
					-- Protocol type MSB
					when "00010" =>
						nextWrData <= x"08";
					
					-- Protocol type LSB
					when  "00011" =>
						nextWrData <= (others => '0');
						
					-- Hardware Address length in bytes
					when "00100" =>
						nextWrData <= x"06";
						
					-- IP Address length in bytes
					when "00101" =>
						nextWrData <= x"04";
					
					-- Operation MSB
					when "00110" =>
						nextWrData <= x"00";
					
					-- Operation LSB
					when "00111" =>
						nextWrData <= x"02";
					
					-- Sender Hardware Address byte 0
					when "01000" =>
						nextWrData <= DEVICE_MAC (47 downto 40);
						
					-- Sender Hardware Address byte 1
					when "01001" =>
						nextWrData <= DEVICE_MAC (39 downto 32);

					-- Sender Hardware Address byte 2
					when "01010" =>
						nextWrData <= DEVICE_MAC (31 downto 24);
						
					-- Sender Hardware Address byte 3
					when "01011" =>
						nextWrData <= DEVICE_MAC (23 downto 16);
						
					-- Sender Hardware Address byte 4
					when "01100" =>
						nextWrData <= DEVICE_MAC (15 downto 8);
						
					-- Sender Hardware Address byte 5
					when "01101" =>
						nextWrData <= DEVICE_MAC (7 downto 0);
					
					-- Sender IP Address byte 0
					when "01110" =>
						nextWrData <= DEVICE_IP (31 downto 24);

					-- Sender IP Address byte 1
					when "01111" =>
						nextWrData <= DEVICE_IP (23 downto 16);

					-- Sender IP Address byte 2
					when "10000" =>
						nextWrData <= DEVICE_IP (15 downto 8);

					-- Sender IP Address byte 3
					when "10001" =>
						nextWrData <= DEVICE_IP (7 downto 0);

					-- Target Hardware Address byte 0
					when "10010" =>
						nextWrData <= latchedMAC (47 downto 40);

					-- Target Hardware Address byte 1
					when "10011" =>
						nextWrData <= latchedMAC (39 downto 32);

					-- Target Hardware Address byte 2
					when "10100" =>
						nextWrData <= latchedMAC (31 downto 24);

					-- Target Hardware Address byte 3
					when "10101" =>
						nextWrData <= latchedMAC (23 downto 16);

					-- Target Hardware Address byte 4
					when "10110" =>
						nextWrData <= latchedMAC (15 downto 8);

					-- Target Hardware Address byte 5
					when "10111" =>
						nextWrData <= latchedMAC (7 downto 0);

					-- Target IP Address byte 0
					when "11000" =>
						nextWrData <= latchedIP (31 downto 24);

					-- Target IP Address byte 1
					when "11001" =>
						nextWrData <= latchedIP (23 downto 16);

					-- Target IP Address byte 2
					when "11010" =>
						nextWrData <= latchedIP (15 downto 8);

					-- Target IP Address byte 3
					when "11011" =>
						nextWrData <= latchedIP (7 downto 0);

				when others =>
				end case;
			
			-- store the ARP reply for the Ethernet sender
			when stStoreARPReply =>
				-- if we've finished storing the ARP reply, then inform the ethernet layer to send it
				-- and wait for the ethernet layer to then tell us that it has sent it
				if cnt = "11100" then
					-- if the frame has been sent, return to idle
					if frameSent = '1' then
						nextState <= stIdle;
					else
						nextState <= stStoreARPReply;
						genFrame <= '1';
						-- give the ethernet sender the MAC address to send the reply to and tell it 
						-- to send an ARP message
						targetMAC <= latchedMAC;
						frameType <= '0';
						frameSize <= latchedFrameSize;
					end if;
				elsif complete = '0' then
					nextState <= stStoreARPReply;
					wrRAM <= '1';
--					wrAddr <= ("00" & x"000" & cnt) + ("000" & x"000E");
					wrAddr <= ("000" & cnt) + (x"0E");
				-- if not finished, continue to create the reply
				else
					nextState <= stGenARPReply;
					incCnt <= '1';
				end if;		
				
			-----------------------------------------------------------------------------------
			-- handle frames passed on to us from the Internet layer
			-- check to the see if the desired IP is in the ARP table
			when stCheckARPEntry =>
				nextState <= stCheckARPEntry2;
				lookupIP <= latchedIP;

			-- check to see if the ARP entry is valid
			when stCheckARPEntry2 =>
				lookupIP <= latchedIP;
				-- if it's not a valid ARP entry, then generate an ARP request to find the
				-- desired MAC address
				if ARPEntryValid = '0' then
					nextState <= stGenArpRequest;
				-- otherwise latch the target MAC and pass on the frame to the ethernet layer
				else
					nextState <= stGenEthFrame;
					latchTargetMAC <= '1';
				end if;

			-- Todo: it will destroy the prepared reply message with upper layers!!! akzare
      -- create each byte of the ARP request according to cnt
			when stGenARPRequest =>
				nextState <= stStoreARPRequest;
				case cnt is
					-- Hardware type MSB
					when "00000" =>
						nextWrData <= (others => '0');
					
					-- Hardware type LSB
					when "00001" =>
						nextWrData <= x"01";
						
					-- Protocol type MSB
					when "00010" =>
						nextWrData <= x"08";
					
					-- Protocol type LSB
					when  "00011" =>
						nextWrData <= (others => '0');
						
					-- Hardware Address length in bytes
					when "00100" =>
						nextWrData <= x"06";
						
					-- IP Address length in bytes
					when "00101" =>
						nextWrData <= x"04";
					
					-- Operation MSB
					when "00110" =>
						nextWrData <= x"00";
					
					-- Operation LSB
					when "00111" =>
						nextWrData <= x"01";
					
					-- Sender Hardware Address byte 0
					when "01000" =>
						nextWrData <= DEVICE_MAC (47 downto 40);
						
					-- Sender Hardware Address byte 1
					when "01001" =>
						nextWrData <= DEVICE_MAC (39 downto 32);

					-- Sender Hardware Address byte 2
					when "01010" =>
						nextWrData <= DEVICE_MAC (31 downto 24);
						
					-- Sender Hardware Address byte 3
					when "01011" =>
						nextWrData <= DEVICE_MAC (23 downto 16);
						
					-- Sender Hardware Address byte 4
					when "01100" =>
						nextWrData <= DEVICE_MAC (15 downto 8);
						
					-- Sender Hardware Address byte 5
					when "01101" =>
						nextWrData <= DEVICE_MAC (7 downto 0);
					
					-- Sender IP Address byte 0
					when "01110" =>
						nextWrData <= DEVICE_IP (31 downto 24);

					-- Sender IP Address byte 1
					when "01111" =>
						nextWrData <= DEVICE_IP (23 downto 16);

					-- Sender IP Address byte 2
					when "10000" =>
						nextWrData <= DEVICE_IP (15 downto 8);

					-- Sender IP Address byte 3
					when "10001" =>
						nextWrData <= DEVICE_IP (7 downto 0);

					-- Target Hardware Address byte 0
					-- should be 0's for an ARP request
					when "10010" =>
						nextWrData <= x"00";

					-- Target Hardware Address byte 1
					when "10011" =>
						nextWrData <= x"00";

					-- Target Hardware Address byte 2
					when "10100" =>
						nextWrData <= x"00";

					-- Target Hardware Address byte 3
					when "10101" =>
						nextWrData <= x"00";

					-- Target Hardware Address byte 4
					when "10110" =>
						nextWrData <= x"00";

					-- Target Hardware Address byte 5
					when "10111" =>
						nextWrData <= x"00";

					-- Target IP Address byte 0
					when "11000" =>
						nextWrData <= latchedIP (31 downto 24);

					-- Target IP Address byte 1
					when "11001" =>
						nextWrData <= latchedIP (23 downto 16);

					-- Target IP Address byte 2
					when "11010" =>
						nextWrData <= latchedIP (15 downto 8);

					-- Target IP Address byte 3
					when "11011" =>
						nextWrData <= latchedIP (7 downto 0);

				when others =>
				end case;

			-- store the ARP request 
			when stStoreARPRequest =>
				-- once the ARP request has been generated, inform the ethernet layer to send it
				-- wait for the ethernet layer to inform us that it's sent before continuing
--				if cnt = "11011" then
				if cnt = "11100" then
					if frameSent = '1' then
						nextState <= stWaitForValidEntry;
						-- reset the ARP timeout counter to start counting
						rstARPCnt <= '1';
					else
						nextState <= stStoreARPRequest;
						genFrame <= '1';
						targetMAC <= x"FFFFFFFFFFFF";
						frameType <= '0';
            frameSize <= "000" & x"2A";
--            frameSize <= latchedFrameSize;
					end if;
				elsif complete = '0' then
					nextState <= stStoreARPRequest;
					wrRAM <= '1';
--					wrAddr <= ("00" & x"000" & cnt) + ("000" & x"000E");
					wrAddr <= ("000" & cnt) + (x"0E");
				-- if the ARP request hasn't been fully generated then continue creating and 
				-- storing it
				else
					nextState <= stGenARPRequest;
					incCnt <= '1';
				end if;	
			
			-- wait for the ARP entry to become valid
			when stWaitForValidEntry =>
				-- if the ARP entry becomes valid then we fire off the reply
				if ARPEntryValid = '1' then
					nextState <= stGenEthFrame;
					latchTargetMAC <= '1';
				-- otherwise give a certain amount of time for the ARP reply to come
				-- back in (21.5 secs on a 50MHz clock)
				else
					-- if the reply doesn't come back, then inform the above layer that the
					-- frame was sent.  Assume the higher level protocol can account for this
					-- problem, or possibly an error signal could be created once a higher level
					-- protocol has been written that can accomodate this
					if ARPCntOverflow = '1' then
						nextState <= stIdle;
						sendingFrame <= '1';
					else				
						nextState <= stWaitForValidEntry;
					end if;
				end if;
				lookupIP <= latchedIP;
					
			-- send the requested frame
			when stGenEthFrame =>
				-- wait for the ethernet layer to tell us that the frame was sent, and then
				-- inform the internet layer that the frame was sent
				if frameSent = '1' then
					nextState <= stIdle;
					sendingFrame <= '1';
				-- keep telling the ethernet layer to send the frame until it is sent
				else 
					nextState <= stGenEthFrame;
					genFrame <= '1';
					frameType <= '1';
					targetMAC <= latchedMAC;
					frameSize <= latchedFrameSize;
				end if;
				
			when others =>
		end case;
	end process;

end ARPSnd_arch;
