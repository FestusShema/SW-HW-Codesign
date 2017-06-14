----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    June 2013 
-- Design Name: 
-- Module Name:    pattern_match_irc - Behavioral 
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

entity pattern_match_irc is 
	 port(clk_150 : in STD_LOGIC;
			clk : in  std_logic;
			rx_clk : in std_logic;
	      car	  : in  std_logic_vector(7 downto 0);
			newByteRecv : in std_logic;
			newTCPMessage : in std_logic;
			IRCmsgDetected : out std_logic_vector(2 downto 0);
	      nbIRCmsgDetected :out std_logic_vector(31 downto 0);
			nbJOINmsgDetected :out std_logic_vector(31 downto 0);
			nbPINGmsgDetected :out std_logic_vector(31 downto 0);
			nbPONGmsgDetected :out std_logic_vector(31 downto 0);
			nbPRIVMSGmsgDetected :out std_logic_vector(31 downto 0);
			channel : out std_logic_vector(399 downto 0);
			nextChannel : out std_logic_vector (399 downto 0);
	      hit	  : out std_logic_vector(3 downto 0));
end  pattern_match_irc; 

architecture STRUCTURAL of pattern_match_irc is 

  signal  intern_hit0: std_logic_vector(3 downto 0);

   component AUT_JOIN 
	 port(clk_150 : in STD_LOGIC;
			clk : in  std_logic;
			rx_clk : in std_logic; 
	      char	 : in  std_logic_vector(7 downto 0);
			newByteRecv : in std_logic;
			newTCPMessage : in std_logic;
			IRCmsgDetected : out std_logic_vector (2 downto 0);
	      nbIRCmsgDetected :out std_logic_vector(31 downto 0); 
			nbJOINmsgDetected :out std_logic_vector(31 downto 0);
			nbPINGmsgDetected :out std_logic_vector(31 downto 0);
			nbPONGmsgDetected :out std_logic_vector(31 downto 0);
			nbPRIVMSGmsgDetected :out std_logic_vector(31 downto 0);
			channelName : out std_logic_vector(399 downto 0);
			nextChannelName : out std_logic_vector(399 downto 0);
	      hit	 : out std_logic_vector(3 downto 0));
  end component;

  begin 
	 FSM_INST0:AUT_JOIN 
	   Port Map(clk_150, clk, rx_clk, car, newByteRecv, newTCPMessage, IRCmsgDetected, nbIRCmsgDetected, nbJOINmsgDetected, nbPINGmsgDetected, nbPONGmsgDetected, nbPRIVMSGmsgDetected, channel, nextChannel, intern_hit0); 

	 SET_HIT: process(intern_hit0) 
	 begin 
	   hit <= (intern_hit0); 
	 end process; 
end STRUCTURAL;
