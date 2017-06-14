----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    June 2013 
-- Design Name: 
-- Module Name:    automat0_irc - Behavioral 
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
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AUT_JOIN is 
	 port(clk_150 : in STD_LOGIC; -- Used for debug purposes (ChipScope)
			clk : in  std_logic; -- Used for IRC packet information retrieval
			rx_clk : in std_logic; -- Used for IRC packet detection
	      char	: in  std_logic_vector(7 downto 0);	-- Incoming data on the wire
			newByteRecv : in std_logic; -- Indicates when a new byte has been received
			newTCPMessage : in std_logic; -- Indicate when a new TCP message has been received
			IRCmsgDetected : out std_logic_vector(2 downto 0); -- "001"=JOIN, "010"=PING, "011"=PONG, "100"=PRIVMSG
	      nbIRCmsgDetected :out std_logic_vector(31 downto 0); -- Count the number of IRC message received
			nbJOINmsgDetected :out std_logic_vector(31 downto 0); -- Count the number of JOIN message received
			nbPINGmsgDetected :out std_logic_vector(31 downto 0); -- Count the number of PING message received
			nbPONGmsgDetected :out std_logic_vector(31 downto 0); -- Count the number of PONG message received
			nbPRIVMSGmsgDetected :out std_logic_vector(31 downto 0); -- Count the number of PRIVMSG received
			channelName : out std_logic_vector (399 downto 0); -- channel name retrieved from IRC packet
			nextChannelName : out std_logic_vector(399 downto 0); -- 2nd channel name retrieved from IRC packet
	      hit	 : out std_logic_vector(3 downto 0)); -- Indicate that an IRC packet has been detected
end AUT_JOIN;

architecture STRUCTURAL of AUT_JOIN is 

  signal debug0: std_logic; 
  signal debug00: std_logic; 
  signal debug1: std_logic; 
  signal debug10: std_logic; 
  signal debug2: std_logic; 
  signal debug20: std_logic; 
  signal debug3: std_logic; 
  signal debug30: std_logic; 
  signal intern_pos:std_logic_vector(19 downto 0); 

  signal clk_div: std_logic_vector(0 downto 0) := "0";
  signal divided_clk: std_logic;
 
  signal join_detected: std_logic := '0';
  signal ping_detected: std_logic := '0';
  signal pong_detected: std_logic := '0';
  signal privmsg_detected: std_logic := '0';
  
  type STATETYPE_IRC is (state_idle, state_WaitForSpace, state_WaitForLineFeed, state_GetChannelName, state_GetKey,
					state_GetNextChannelName, state_EndIRCmsg);
  
  signal current_state: STATETYPE_IRC := state_idle;
  
  signal channel_name_size: natural := 0;
  signal next_channel_name_size: natural := 0;
  
  signal control0: STD_LOGIC_VECTOR(35 downto 0);
  signal data_chipscope : std_logic_vector(12 downto 0);
  
  component icon
  port (
    CONTROL0: inout STD_LOGIC_VECTOR(35 downto 0));
  end component;
  
  component ila
  port (
    CONTROL: inout STD_LOGIC_VECTOR(35 downto 0);
    CLK: in STD_LOGIC;
    DATA: in STD_LOGIC_VECTOR(12 downto 0);
    TRIG0: in STD_LOGIC_VECTOR(0 downto 0));
  end component;

  component comp_vect0_irc 
	 port(car : in   std_logic_vector(7 downto 0); 
	      pos : out  std_logic_vector(19 downto 0)); 
  end component; 

	 signal Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20, Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30, Q31, Q32, Q33, Q34: std_logic;
   
	begin

  data_chipscope <= char(3 downto 0) & debug3 & debug2 & debug1 & debug0 & join_detected & privmsg_detected & newByteRecv & divided_clk & clk;
  
  icon_comp : icon
	port map(CONTROL0 => control0);
	
  ila_comp : ila
   port map (
    CONTROL => control0,
    CLK => clk_150,
    DATA => data_chipscope,
    TRIG0(0) => newTCPMessage);

  compar0:comp_vect0_irc
	 Port Map(char, intern_pos);
	 
	 
  --===========================
  --	Clock divider process
  --===========================
  DIV_CLOCK:process(rx_clk)
	begin
	   if rising_edge(rx_clk) then
			clk_div <= clk_div + 1;
	   end if;
  end process;
  --===========================
  --	Clock divider process
  --===========================
  
  divided_clk <= clk_div(0); 

	 SET_STATE:process(divided_clk) 
	   variable cntIRCmsgDetected: std_logic_vector (31 downto 0) := x"00000000";
		variable cntJOINmsgDetected: std_logic_vector (31 downto 0) := x"00000000";
		variable cntPINGmsgDetected: std_logic_vector (31 downto 0) := x"00000000";
		variable cntPONGmsgDetected: std_logic_vector (31 downto 0) := x"00000000";
		variable cntPRIVMSGmsgDetected: std_logic_vector (31 downto 0) := x"00000000";
	   begin 
	     if rising_edge(divided_clk) then
		  
			--The code below is used to count how many IRC packets have been detected
			if (debug0 /= '0' or debug1 /= '0' or debug2 /= '0' or debug3 /= '0') then
				cntIRCmsgDetected := std_logic_vector(unsigned(cntIRCmsgDetected + 1));
				nbIRCmsgDetected <= cntIRCmsgDetected;
				if((debug0 = '1' and debug1 = '0' and debug2 = '0' and debug3 = '0') or (debug0 = '0' and debug1 = '1' and debug2 = '0' and debug3 = '0')) then
					cntJOINmsgDetected := std_logic_vector(unsigned(cntJOINmsgDetected + 1));
					nbJOINmsgDetected <= cntJOINmsgDetected;
					join_detected <= '1';
				elsif ((debug0 = '1' and debug1 = '1' and debug2 = '0' and debug3 = '0') or (debug0 = '0' and debug1 = '0' and debug2 = '1' and debug3 = '0')) then
						cntPINGmsgDetected := std_logic_vector(unsigned(cntPINGmsgDetected + 1));
						nbPINGmsgDetected <= cntPINGmsgDetected;
						ping_detected <= '1';
				elsif ((debug0 = '1' and debug1 = '0' and debug2 = '1' and debug3 = '0') or (debug0 = '0' and debug1 = '1' and debug2 = '1' and debug3 = '0')) then
						cntPONGmsgDetected := std_logic_vector(unsigned(cntPONGmsgDetected + 1));
						nbPONGmsgDetected <= cntPONGmsgDetected;
						pong_detected <= '1';
				elsif ((debug0 = '1' and debug1 = '1' and debug2 = '1' and debug3 = '0') or (debug0 = '0' and debug1 = '0' and debug2 = '0' and debug3 = '1')) then
						cntPRIVMSGmsgDetected := std_logic_vector(unsigned(cntPRIVMSGmsgDetected + 1));
						nbPRIVMSGmsgDetected <= cntPRIVMSGmsgDetected;
						privmsg_detected <= '1';
				else
					join_detected <= '0';
					ping_detected <= '0';
					pong_detected <= '0';
					privmsg_detected <= '0';
				end if;
			end if;	
			--The code above is used to count how many IRC packets have been detected
														
	      Q1 <= intern_pos(0); 
	      Q2 <= (intern_pos(1) and Q1); 
	      Q3 <= (intern_pos(2) and Q2); 
	      Q4 <= (intern_pos(3) and Q3); 
	      Q5 <= intern_pos(4); 
	      Q6 <= (intern_pos(5) and Q5); 
	      Q7 <= (intern_pos(6) and Q6); 
	      Q8 <= (intern_pos(7) and Q7); 
	      Q9 <= intern_pos(8); 
	      Q26 <= (intern_pos(2) and Q9); 
	      Q27 <= (intern_pos(3) and Q26); 
	      Q28 <= (intern_pos(9) and Q27); 
	      Q13 <= intern_pos(10); 
	      Q17 <= (intern_pos(6) and Q13); 
	      Q18 <= (intern_pos(7) and Q17); 
	      Q19 <= (intern_pos(11) and Q18); 
	      Q10 <= (intern_pos(1) and Q9); 
	      Q11 <= (intern_pos(3) and Q10); 
	      Q12 <= (intern_pos(9) and Q11); 
	      Q14 <= (intern_pos(5) and Q13); 
	      Q15 <= (intern_pos(7) and Q14); 
	      Q16 <= (intern_pos(11) and Q15); 
	      Q29 <= (intern_pos(12) and Q9); 
	      Q30 <= (intern_pos(2) and Q29); 
	      Q31 <= (intern_pos(13) and Q30); 
	      Q32 <= (intern_pos(14) and Q31); 
	      Q33 <= (intern_pos(15) and Q32); 
	      Q34 <= (intern_pos(9) and Q33); 
	      Q20 <= (intern_pos(16) and Q13); 
	      Q21 <= (intern_pos(6) and Q20); 
	      Q22 <= (intern_pos(17) and Q21); 
	      Q23 <= (intern_pos(18) and Q22); 
	      Q24 <= (intern_pos(19) and Q23); 
	      Q25 <= (intern_pos(11) and Q24);
			
	 end if; 
	 end process; 

	debug0 <= Q4 or Q12 or Q28 or Q34; 

	debug1 <= Q8 or Q16 or Q28 or Q34; 

	debug2 <= Q12 or Q16 or Q19 or Q34; 

	debug3 <= Q25; 

	hit(0) <= debug0; 
	hit(1) <= debug1; 
	hit(2) <= debug2; 
	hit(3) <= debug3; 

	-- Below: Finite State Machine that handles the mining of information from IRC packets
	IRC_INFO_RETRIEVAL: process (clk)
		constant MAX_CHAR_CHAN_NAME: natural := 50;
		variable next_state: STATETYPE_IRC := state_idle;
		variable nbCharChanNameRecv: natural := 0;
		variable nbCharNextChanNameRecv: natural := 0;
		variable channel_name: std_logic_vector(399 downto 0); --50 characters for the channel name
		variable next_channel_name: std_logic_vector(399 downto 0); --50 characters for the channel name
		begin	
			if(clk'event and clk='1')then
				case current_state is
					when state_idle =>
						nbCharChanNameRecv := 0;
						nbCharNextChanNameRecv := 0;
						channel_name := (others => '0');
						next_channel_name := (others => '0');
						if (join_detected = '1' or privmsg_detected = '1' ) then
							next_state := state_WaitForSpace;
						else
							next_state := state_idle;
						end if;
					when state_WaitForSpace =>
						if (newByteRecv = '1')then
							if (char = x"20") then --0x20 is the "space" ASCII code
								next_state := state_GetChannelName;
							else
								next_state := state_idle;
							end if;
						else
							next_state := state_WaitForSpace;
						end if;
					when state_GetChannelName =>
						if (newByteRecv = '1') then
							if (char = x"0D") then --Carriage character (CR)
								next_state := state_WaitForLineFeed;
							elsif (char = x"0A") then --Line Feed character (LF)
								next_state := state_idle;
							elsif (char = x"20") then --Space character
								next_state := state_idle; --instead of state_GetKey, because the key is useless
							elsif (char = x"2C") then --comma character
								next_state := state_GetNextChannelName;
							elsif(nbCharChanNameRecv < MAX_CHAR_CHAN_NAME) then
								nbCharChanNameRecv := nbCharChanNameRecv + 1;
								channel_name ((399-(8*(50-nbCharChanNameRecv))) downto (400-8*(51-nbCharChanNameRecv))) := char;
								channelName <= channel_name;
								channel_name_size <= nbCharChanNameRecv;
								next_state := state_GetChannelName;
							else
								next_state := state_idle;
							end if;
						else
							next_state := state_GetChannelName;
						end if;
					when state_WaitForLineFeed =>
						--whether the received character is "LF" or not i'll go to state_idle, so I don't ensure that
						--the character is really a "Line Feed" character
						if (newByteRecv = '1') then 
							next_state := state_idle;
						else
							next_state := state_WaitForLineFeed;
						end if;
					when state_GetNextChannelName =>
						if (newByteRecv = '1') then
							if (char = x"0D") then --Carriage character (CR)
								next_state := state_WaitForLineFeed;
							elsif (char = x"0A") then --Line Feed character (LF)
								next_state := state_idle;
							elsif (char = x"20") then --Space character
								next_state := state_idle; --instead of state_GetKey, because the key is useless
--							elsif (char = x"2C") then --comma character
--								next_state := state_GetChannelName;
							elsif(nbCharNextChanNameRecv < MAX_CHAR_CHAN_NAME) then	
								nbCharNextChanNameRecv := nbCharNextChanNameRecv + 1;
								next_channel_name ((399-(8*(50-nbCharNextChanNameRecv))) downto (400-8*(51-nbCharNextChanNameRecv))) := char;
								nextChannelName <= next_channel_name;
								next_channel_name_size <= nbCharNextChanNameRecv;	
								next_state := state_GetNextChannelName;
							else
								next_state := state_idle;
							end if;
						else
							next_state := state_GetNextChannelName;
						end if;	
					when others => null;
				end case;	
				current_state <= next_state;
			end if;
	end process IRC_INFO_RETRIEVAL;
	-- Above: Finite State Machine that handles the mining of information from IRC packets
	
	
	-- The process below is used to set to '0' the signal "IRCmsgDetected" when a new TCP message is rcvd
	RESET_IRCmsgDetected_Signal: process(clk)
		begin
			if(clk'event and clk='1')then
				-- The code below is used to indicate whether a JOIN, PING, PONG or PRIVMSG has been detected.
				-- Thereby,"IRCmsgDetected" must keep its value until a newTCPmessage is received, so that 
				-- the hardware will be able to write into the memory this value (indicating to the software which
				-- IRC message has been received). The software will then be bale to update the statistics per 
				-- channel name.
				if((debug0 = '1' and debug1 = '0' and debug2 = '0' and debug3 = '0') or (debug0 = '0' and debug1 = '1' and debug2 = '0' and debug3 = '0')) then
						IRCmsgDetected <= "001";
				elsif((debug0 = '1' and debug1 = '1' and debug2 = '0' and debug3 = '0') or (debug0 = '0' and debug1 = '0' and debug2 = '1' and debug3 = '0')) then
						IRCmsgDetected <= "010";
				elsif ((debug0 = '1' and debug1 = '0' and debug2 = '1' and debug3 = '0') or (debug0 = '0' and debug1 = '1' and debug2 = '1' and debug3 = '0')) then
						IRCmsgDetected <= "011";
				elsif ((debug0 = '1' and debug1 = '1' and debug2 = '1' and debug3 = '0') or (debug0 = '0' and debug1 = '0' and debug2 = '0' and debug3 = '1')) then
						IRCmsgDetected <= "100";
				end if;

				if(newTCPmessage = '1') then
					IRCmsgDetected <= "000"; -- set IRCmsgDetected to "000" when a newTCPmessage is received
				end if;
				
			end if;
	end process RESET_IRCmsgDetected_Signal;
	-- The process below is used to set to '0' the signal "IRCmsgDetected" when a new TCP message is rcvd
	 
end STRUCTURAL; 