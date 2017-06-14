----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    May 2013 
-- Design Name: 
-- Module Name:    pattern_match - Behavioral 
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

Library UNISIM;
use UNISIM.vcomponents.all;

entity pattern_match is 
	 port(clk	  : in  std_logic; 
			rx_clk : in std_logic;
	      car	  : in  std_logic_vector(7 downto 0);
			nbPatternDetected :out std_logic_vector(31 downto 0);
	      hit	  : out std_logic_vector(2 downto 0));
end  pattern_match; 

architecture STRUCTURAL of pattern_match is 

  signal  intern_hit0: std_logic_vector(2 downto 0);

   component AUT_ABCDE 
	 port(clk	 : in  std_logic; 
			rx_clk : in std_logic;
	      char	 : in  std_logic_vector(7 downto 0); 
			nbPatternDetected :out std_logic_vector(31 downto 0);
	      hit	 : inout std_logic_vector(2 downto 0));
  end component;

  begin 
	
	 FSM_INST0:AUT_ABCDE 
	   Port Map(clk, rx_clk, car, nbPatternDetected, intern_hit0); 

	 SET_HIT: process(intern_hit0) 
	 begin 
	   hit <= (intern_hit0); 
	 end process; 
end STRUCTURAL;
