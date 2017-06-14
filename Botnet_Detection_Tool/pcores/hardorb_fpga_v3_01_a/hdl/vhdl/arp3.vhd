-------------------------------------------------------------------------------
-- arp3.vhd
--
-- Author(s):     Ashley Partis and Jorgen Peddersen
-- Created:       Feb 2001
-- Last Modified: Feb 2001
-- Last Modified: Dec 2009 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)
-- 
-- Manages an ARP table for the network stack project.  This protocol listens
-- to incoming data and when an ARP request or reply arrives, the data of the
-- source is added to the ARP table.  The ARP table contains two entries.
-- When a request arrives a signal is also asserted telling the arp sender to
-- send an ARP reply when possible.  The incoming data from the ethernet layer
-- is a byte stream.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
--use work.global_constants.all;

entity ARP is
  generic (
    C_DEBUG_MODE : integer := 0;	-- 0 = disable, 1 = enable
    DEVICE_IP : STD_LOGIC_VECTOR (31 downto 0) := x"c0a8010a"; -- 192.168.1.10
    DEVICE_MAC: STD_LOGIC_VECTOR (47 downto 0) := x"000A3501CB9E"
    );                
    port (
		clk: in STD_LOGIC;								-- clock signal
		rstn: in STD_LOGIC;								-- asynchronous active low reset
		newFrame: in STD_LOGIC;							-- from ethernet layer indicates data arrival
		frameType: in STD_LOGIC;						-- '0' for an ARP message
		newFrameByte: in STD_LOGIC;						-- indicates a new byte in the stream
		frameData: in STD_LOGIC_VECTOR (7 downto 0);	-- the stream data
--		endFrame: in STD_LOGIC;							-- asserted at the end of a frame
		frameValid: in STD_LOGIC; 						-- indicates validity while endFrame is asserted
		ARPSendAvail: in STD_LOGIC;						-- ARP sender asserts this when the reply is transmitted
		requestIP: in STD_LOGIC_VECTOR (31 downto 0);	-- ARP sender can request MACs for this address
		genARPRep: out STD_LOGIC;						-- tell ARP sender to generate a reply
		genARPIP: out STD_LOGIC_VECTOR (31 downto 0);	-- destination IP for generated reply
		lookupMAC: out STD_LOGIC_VECTOR (47 downto 0);	-- if valid, MAC for requested IP
------------------------ TEST -------------------    
tst_arprecpresstate: out STD_LOGIC_VECTOR (1 downto 0);
tst_arprecnewFrame: out STD_LOGIC;
tst_arprecframeType: out STD_LOGIC;
------------------------ TEST -------------------    
		validEntry: out STD_LOGIC						-- indicates if requestIP is in table
    );
end ARP;

architecture ARP_arch of ARP is

-- State signals and types
type STATETYPE is (stIdle, stHandleARP, stOperate, stCheckValid);
signal presState: STATETYPE;
signal nextState: STATETYPE;

signal cnt: STD_LOGIC_VECTOR (4 downto 0);				-- header count
signal incCnt: STD_LOGIC;								-- signal to increment cnt
signal rstCnt: STD_LOGIC;								-- signal to clear cnt

signal latchFrameData: STD_LOGIC;						-- signal to latch stream data
signal frameDataLatch: STD_LOGIC_VECTOR (7 downto 0);	-- register for latched data
signal shiftSourceIPIn: STD_LOGIC;						-- signal to shift in source IP
signal sourceIP: STD_LOGIC_VECTOR (31 downto 0);		-- stores source IP
signal shiftSourceMACIn: STD_LOGIC;						-- signal to shift in source MAC
signal sourceMAC: STD_LOGIC_VECTOR (47 downto 0);		-- stores source MAC

signal ARPOperation: STD_LOGIC;							-- '0' for reply, '1' for request
signal determineOperation: STD_LOGIC;					-- signal to latch ARPOperation from stream

signal updateARPTable: STD_LOGIC;						-- this signal updates the ARP table
signal ARPEntryIP: STD_LOGIC_VECTOR (31 downto 0);		-- most recent ARP entry IP
signal ARPEntryMAC: STD_LOGIC_VECTOR (47 downto 0);		-- most recent ARP entry MAC
signal ARPEntryIPOld: STD_LOGIC_VECTOR (31 downto 0);	-- 2nd ARP entry IP
signal ARPEntryMACOld: STD_LOGIC_VECTOR (47 downto 0);	-- 2nd ARP entry MAC

signal doGenARPRep: STD_LOGIC;							-- asserted when an ARP reply must be generated

begin
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_arprecpresstate <= conv_std_logic_vector(STATETYPE'pos(presState), 2);
tst_arprecnewFrame <= newFrame; 
tst_arprecframeType <= frameType; 
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_arprecpresstate <= (others => '0');
tst_arprecnewFrame <= '0'; 
tst_arprecframeType <= '0'; 
end generate;
------------------------ TEST -------------------    
	process (clk, rstn)
	begin
		if rstn = '0' then		-- reset state and ARP entries
			presState <= stIdle;
			ARPEntryIP <= (others => '0');
			ARPEntryMAC <= (others => '0');
			ARPEntryIPOld <= (others => '0');
			ARPEntryMACOld <= (others => '0');
      
      genARPRep <= '0'; -- akzare
		elsif clk'event and clk = '1' then
			presState <= nextState;	-- go to next state
			if incCnt = '1' then	-- handle counter
				cnt <= cnt + 1;
			elsif rstCnt = '1' then
				cnt <= (others => '0');
			end if;
			if latchFrameData = '1' then	-- latch stream data
				frameDataLatch <= frameData;
			end if;
			if determineOperation = '1' then	-- determine ARP Operation value
				ARPOperation <= frameDataLatch(0);
			end if;
			if shiftSourceIPIn = '1' then	-- shift in IP
				sourceIP <= sourceIP (23 downto 0) & frameDataLatch;
			end if;
			if shiftSourceMACIn = '1' then	-- shift in MAC
				sourceMAC <= sourceMAC (39 downto 0) & frameDataLatch;
			end if;
			if updateARPTable = '1' then	-- update ARP table
				if ARPEntryIP = sourceIP then	-- We already have this ARP, so update
					ARPEntryMAC <= SourceMAC;
				else							-- Lose one old ARP entry and add new one.
					ARPEntryIPOld <= ARPEntryIP;
					ARPEntryMACOld <= ARPEntryMAC;
					ARPEntryIP <= sourceIP;
					ARPEntryMAC <= sourceMAC;
				end if;
			end if;
			-- genARPRep is asserted by doGenARPRep and will stay high until cleared 
			-- by ARPSendAvail
			if doGenARPRep = '1' then	
				genARPRep <= '1';		-- when a request is needed assert genARPRep
				genARPIP <= sourceIP;	-- and latch the outgoing address
			elsif ARPSendAvail = '1' then
				genARPRep <= '0';		-- when the request has been generated, stop requesting
			end if;						
		end if;	
	end process;

--	process (presState, sourceIP, ARPOperation, cnt, newFrame, frameType,
--			newFrameByte, frameDataLatch, endFrame, frameValid)
	process (presState, sourceIP, ARPOperation, cnt, newFrame, frameType,
			newFrameByte, frameDataLatch, frameValid)
	begin
		-- defaulting of signals
		rstCnt <= '0';
		incCnt <= '0';
		shiftSourceIPIn <= '0';
		determineOperation <= '0';
		updateARPTable <= '0';
		shiftSourceIPIn <= '0';
		shiftSourceMACIn <= '0';
		latchFrameData <= '0';
		doGenARPRep <= '0';
	
		case presState is
			when stIdle =>
				-- wait for an ARP frame to arrive
				if newFrame = '1' and frameType = '0' then
					nextState <= stHandleARP;
					rstCnt <= '1';
				else
					nextState <= stIdle;
				end if;
		 
			when stHandleARP =>
				-- receive a byte from the stream
				if newFrameByte = '0' then
					nextState <= stHandleARP;
				else
					nextState <= stOperate;
					latchFrameData <= '1';
				end if;
			
			when stOperate =>
				-- increment counter
				incCnt <= '1';
				-- choose state based on values in the header
				-- The following will make us ignore the frame (all values hexadecimal):
				-- Hardware Type /= 1
				-- Protocol Type /= 800
				-- Hardware Length /= 6
				-- Protocol Length /= 8
				-- Operation /= 1 or 2
				-- Target IP /= our IP (i.e. message is not meant for us)
				if ((cnt = "00000" or cnt = "00011" or cnt = "00110") and frameDataLatch /= 0 )or 
				(cnt = "00001" and frameDataLatch /= 1) or
				(cnt = "00010" and frameDataLatch /= 8) or
				(cnt = "00100" and frameDataLatch /= 6) or
				(cnt = "00101" and frameDataLatch /= 4) or
				(cnt = "00111" and frameDataLatch /= 1 and frameDataLatch /= 2 )or
				(cnt = "11000" and frameDataLatch /= DEVICE_IP (31 downto 24)) or
				(cnt = "11001" and frameDataLatch /= DEVICE_IP (23 downto 16)) or
				(cnt = "11010" and frameDataLatch /= DEVICE_IP (15 downto 8)) or
				(cnt = "11011" and frameDataLatch /= DEVICE_IP (7 downto 0)) then
					nextState <= stIdle;
				elsif cnt = "11011" then
					nextState <= stCheckValid;	-- exit when data is totally received
				else
					nextState <= stHandleARP;	-- otherwise loop until complete
				end if;
				
				-- latch and shift in signals from stream when needed
				if cnt = "00111" then
					determineOperation <= '1';	
				end if;
				if cnt =  "01000" or cnt =  "01001" or cnt = "01010" or cnt = "01011" or cnt = "01100" or cnt = "01101" then
					shiftSourceMACIn <= '1';
				end if;
				if cnt = "01110" or cnt = "01111" or cnt = "10000" or cnt = "10001" then
					shiftSourceIPIn <= '1';
				end if;
								
			when stCheckValid =>
--				if endFrame = '0' then
					-- wait for the end of the frame
--					nextState <= stCheckValid;
				if frameValid = '0' then
					-- frame failed CRC so ignore it
					nextState <= stCheckValid;
--					nextState <= stIdle;
				else
					-- generate a reply if required and wait for more messages
					if ARPOperation = '1' then
						doGenARPRep <= '1';
					end if;			
					nextState <= stIdle;
					updateARPTable <= '1';	-- update the ARP table with the new data
				end if;
			
			when others =>
			
		end case;
	end process;

	-- handle requests for entries in the ARP table.
	process (requestIP, ARPEntryIP, ARPEntryMAC, ARPEntryIPOld, ARPEntryMACOld)
	begin
		if requestIP = ARPEntryIP then			-- check most recent entry
			validEntry <= '1';
			lookupMAC <= ARPEntryMAC;
		elsif requestIP = ARPEntryIPOld then	-- check 2nd entry
			validEntry <= '1';
			lookupMAC <= ARPEntryMACOld;
		else									-- if neither entry matches, valid = 0
			validEntry <= '0';
			lookupMAC <= (others => '1');
		end if;
	end process;
end ARP_arch;
