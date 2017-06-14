----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    June 2013 
-- Design Name: 
-- Module Name:    comp_vect0_irc - Behavioral 
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

entity comp_vect0_irc is 
	 port(car : in   std_logic_vector(7 downto 0); 
	      pos : out  std_logic_vector(19 downto 0));
end comp_vect0_irc; 

architecture STRUCTURAL of comp_vect0_irc is 
begin 
	  pos(0) <= '1' when car = "01001010" else '0'; 
	  pos(1) <= '1' when car = "01001111" else '0'; 
	  pos(2) <= '1' when car = "01001001" else '0'; 
	  pos(3) <= '1' when car = "01001110" else '0'; 
	  pos(4) <= '1' when car = "01101010" else '0'; 
	  pos(5) <= '1' when car = "01101111" else '0'; 
	  pos(6) <= '1' when car = "01101001" else '0'; 
	  pos(7) <= '1' when car = "01101110" else '0'; 
	  pos(8) <= '1' when car = "01010000" else '0'; 
	  pos(9) <= '1' when car = "01000111" else '0'; 
	  pos(10) <= '1' when car = "01110000" else '0'; 
	  pos(11) <= '1' when car = "01100111" else '0'; 
	  pos(12) <= '1' when car = "01010010" else '0'; 
	  pos(13) <= '1' when car = "01010110" else '0'; 
	  pos(14) <= '1' when car = "01001101" else '0'; 
	  pos(15) <= '1' when car = "01010011" else '0'; 
	  pos(16) <= '1' when car = "01110010" else '0'; 
	  pos(17) <= '1' when car = "01110110" else '0'; 
	  pos(18) <= '1' when car = "01101101" else '0'; 
	  pos(19) <= '1' when car = "01110011" else '0'; 
end STRUCTURAL; 
