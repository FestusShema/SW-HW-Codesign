----------------------------------------------------------------------------------
-- Company: University of Arkansas, CSCE department
-- Engineer: Adil Tbatou
-- 
-- Create Date:    May 2013 
-- Design Name: 
-- Module Name:    automat0 - Behavioral 
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

entity AUT_ABCDE is 
	 port(clk	 : in  std_logic; --This clock is kept for debug purposes
			rx_clk : in std_logic;
	      char	: in  std_logic_vector(7 downto 0); 
			nbPatternDetected :out std_logic_vector(31 downto 0);
	      hit	 : inout std_logic_vector(2 downto 0));
end AUT_ABCDE;

architecture STRUCTURAL of AUT_ABCDE is 

  signal debug0: std_logic; 
  signal debug00: std_logic; 
  signal debug1: std_logic; 
  signal debug10: std_logic; 
  signal debug2: std_logic; 
  signal debug20: std_logic; 
  signal intern_pos:std_logic_vector(49 downto 0); 
  
  signal control0: std_logic_vector(35 downto 0);
  signal data : std_logic_vector(13 downto 0); 
  signal clk_div: std_logic_vector(0 downto 0) := "0";
  signal divided_clk: std_logic;
  
  component icon
  port (
    CONTROL0: inout std_logic_vector(35 downto 0));
  end component;
  
  component ila
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(13 downto 0);
    TRIG0: in std_logic_vector(5 downto 0));
  end component;

  component comp_vect0 
	 port(car : in   std_logic_vector(7 downto 0); 
	      pos : out  std_logic_vector(49 downto 0)); 
  end component; 

	 signal Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20, Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30, Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38, Q39, Q40, Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48, Q49, Q50 : std_logic;
 	 signal Q51, Q52, Q53, Q54, Q55, Q56, Q57, Q58, Q59, Q60, Q61, Q62, Q63, Q64, Q65, Q66, Q67, Q68, Q69, Q70, Q71, Q72, Q73, Q74, Q75, Q76, Q77, Q78, Q79, Q80, Q81, Q82, Q83, Q84, Q85, Q86, Q87, Q88, Q89, Q90, Q91, Q92, Q93, Q94, Q95, Q96, Q97, Q98, Q99, Q100 : std_logic;
 	 signal Q101, Q102, Q103, Q104, Q105, Q106, Q107, Q108, Q109, Q110, Q111, Q112, Q113, Q114, Q115, Q116, Q117, Q118, Q119, Q120, Q121, Q122, Q123, Q124, Q125, Q126, Q127, Q128, Q129, Q130, Q131, Q132, Q133, Q134, Q135, Q136, Q137, Q138, Q139, Q140, Q141, Q142, Q143, Q144, Q145, Q146, Q147, Q148, Q149, Q150 : std_logic;
 	 signal Q151, Q152, Q153, Q154, Q155, Q156, Q157, Q158, Q159, Q160, Q161, Q162, Q163, Q164, Q165, Q166, Q167, Q168, Q169, Q170, Q171, Q172, Q173, Q174, Q175, Q176, Q177, Q178, Q179, Q180, Q181, Q182, Q183, Q184, Q185, Q186, Q187, Q188, Q189, Q190, Q191, Q192, Q193, Q194, Q195, Q196, Q197, Q198: std_logic;
	 
   begin
	
--	data <= intern_pos & Q6 & Q5 & Q4 & Q3 & Q2 & Q1 & divided_clk & rx_clk;
	
--	icon_comp : icon
--	port map(CONTROL0=> control0);
--	
--  ila_comp : ila
--  port map (
--    CONTROL => control0,
--    CLK => clk,
--    DATA => data,
--    TRIG0 => intern_pos);
	
  compar0:comp_vect0
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
		variable cntPatternDetected: std_logic_vector (31 downto 0) := x"00000000";
	   begin 
	     if rising_edge (divided_clk) then
		  
			--The code below is used to count how many malware patterns have been detected
		  	if (debug0 /= '0' or debug1 /= '0' or debug2 /= '0') then
				cntPatternDetected := std_logic_vector(unsigned(cntPatternDetected + 1));
				nbPatternDetected <= cntPatternDetected;
			end if;
			--The code above is used to count how many malware patterns have been detected
			
			Q1 <= intern_pos(0); 
	      Q2 <= (intern_pos(0) and Q1); 
	      Q3 <= (intern_pos(0) and Q2); 
	      Q4 <= (intern_pos(0) and Q3); 
	      Q5 <= (intern_pos(0) and Q4); 
	      Q6 <= (intern_pos(0) and Q5); 
	      Q7 <= (intern_pos(0) and Q6); 
	      Q8 <= (intern_pos(1) and Q7); 
	      Q9 <= (intern_pos(2) and Q8); 
	      Q10 <= (intern_pos(0) and Q9); 
	      Q11 <= (intern_pos(0) and Q10); 
	      Q12 <= (intern_pos(0) and Q11); 
	      Q13 <= (intern_pos(0) and Q12); 
	      Q14 <= (intern_pos(0) and Q13); 
	      Q15 <= (intern_pos(0) and Q14); 
	      Q16 <= (intern_pos(1) and Q15); 
	      Q85 <= (intern_pos(3) and Q1); 
	      Q86 <= (intern_pos(0) and Q85); 
	      Q87 <= (intern_pos(0) and Q86); 
	      Q88 <= (intern_pos(0) and Q87); 
	      Q89 <= (intern_pos(0) and Q88); 
	      Q90 <= (intern_pos(0) and Q89); 
	      Q91 <= (intern_pos(0) and Q90); 
	      Q92 <= (intern_pos(0) and Q91); 
	      Q93 <= (intern_pos(0) and Q92); 
	      Q94 <= (intern_pos(0) and Q93); 
	      Q95 <= (intern_pos(0) and Q94); 
	      Q96 <= (intern_pos(4) and Q95); 
	      Q97 <= (intern_pos(0) and Q96); 
	      Q98 <= (intern_pos(0) and Q97); 
	      Q99 <= (intern_pos(0) and Q98); 
	      Q100 <= (intern_pos(5) and Q1); 
	      Q101 <= (intern_pos(6) and Q100); 
	      Q102 <= (intern_pos(0) and Q101); 
	      Q103 <= (intern_pos(0) and Q102); 
	      Q104 <= (intern_pos(7) and Q103); 
	      Q105 <= (intern_pos(0) and Q104); 
	      Q106 <= (intern_pos(8) and Q105); 
	      Q107 <= (intern_pos(0) and Q106); 
	      Q108 <= (intern_pos(0) and Q107); 
	      Q109 <= (intern_pos(0) and Q108); 
	      Q110 <= (intern_pos(9) and Q109); 
	      Q111 <= (intern_pos(0) and Q110); 
	      Q112 <= (intern_pos(10) and Q111); 
	      Q113 <= (intern_pos(0) and Q112); 
	      Q114 <= (intern_pos(11) and Q113); 
	      Q115 <= (intern_pos(12) and Q3); 
	      Q116 <= (intern_pos(0) and Q115); 
	      Q117 <= (intern_pos(0) and Q116); 
	      Q118 <= (intern_pos(0) and Q117); 
	      Q119 <= (intern_pos(0) and Q118); 
	      Q120 <= (intern_pos(3) and Q119); 
	      Q121 <= (intern_pos(13) and Q120); 
	      Q122 <= (intern_pos(0) and Q121); 
	      Q123 <= (intern_pos(1) and Q122); 
	      Q124 <= (intern_pos(0) and Q123); 
	      Q125 <= (intern_pos(0) and Q124); 
	      Q126 <= (intern_pos(0) and Q125); 
	      Q127 <= (intern_pos(14) and Q126); 
	      Q128 <= (intern_pos(0) and Q127); 
	      Q129 <= (intern_pos(0) and Q128); 
	      Q130 <= (intern_pos(15) and Q129); 
	      Q131 <= (intern_pos(0) and Q130); 
	      Q132 <= (intern_pos(0) and Q131); 
	      Q133 <= (intern_pos(16) and Q132); 
	      Q134 <= (intern_pos(0) and Q133); 
	      Q135 <= (intern_pos(1) and Q134); 
	      Q136 <= (intern_pos(0) and Q135); 
	      Q137 <= (intern_pos(0) and Q136); 
	      Q138 <= (intern_pos(0) and Q137); 
	      Q139 <= (intern_pos(17) and Q138); 
	      Q140 <= (intern_pos(0) and Q139); 
	      Q141 <= (intern_pos(0) and Q140); 
	      Q142 <= (intern_pos(0) and Q141); 
	      Q143 <= (intern_pos(0) and Q142); 
	      Q144 <= (intern_pos(0) and Q143); 
	      Q145 <= (intern_pos(0) and Q144); 
	      Q146 <= (intern_pos(0) and Q145); 
	      Q147 <= (intern_pos(18) and Q146); 
	      Q148 <= (intern_pos(19) and Q147); 
	      Q149 <= (intern_pos(0) and Q148); 
	      Q150 <= (intern_pos(0) and Q149); 
	      Q151 <= (intern_pos(20) and Q150); 
	      Q152 <= (intern_pos(0) and Q151); 
	      Q153 <= (intern_pos(0) and Q152); 
	      Q154 <= (intern_pos(0) and Q153); 
	      Q155 <= (intern_pos(21) and Q154); 
	      Q156 <= (intern_pos(22) and Q155); 
	      Q157 <= (intern_pos(0) and Q156); 
	      Q158 <= (intern_pos(0) and Q157); 
	      Q159 <= (intern_pos(0) and Q158); 
	      Q160 <= (intern_pos(0) and Q159); 
	      Q161 <= (intern_pos(23) and Q160); 
	      Q162 <= (intern_pos(0) and Q161); 
	      Q163 <= (intern_pos(0) and Q162); 
	      Q164 <= (intern_pos(24) and Q163); 
	      Q165 <= (intern_pos(0) and Q164); 
	      Q166 <= (intern_pos(15) and Q165); 
	      Q167 <= (intern_pos(4) and Q166); 
	      Q168 <= (intern_pos(0) and Q167); 
	      Q169 <= (intern_pos(0) and Q168); 
	      Q170 <= (intern_pos(25) and Q169); 
	      Q171 <= (intern_pos(0) and Q170); 
	      Q172 <= (intern_pos(10) and Q171); 
	      Q173 <= (intern_pos(0) and Q172); 
	      Q174 <= (intern_pos(0) and Q173); 
	      Q175 <= (intern_pos(0) and Q174); 
	      Q17 <= intern_pos(26); 
	      Q18 <= (intern_pos(13) and Q17); 
	      Q19 <= (intern_pos(27) and Q18); 
	      Q20 <= (intern_pos(1) and Q19); 
	      Q21 <= (intern_pos(7) and Q20); 
	      Q22 <= (intern_pos(2) and Q21); 
	      Q23 <= (intern_pos(3) and Q22); 
	      Q24 <= (intern_pos(28) and Q23); 
	      Q25 <= (intern_pos(7) and Q24); 
	      Q26 <= (intern_pos(29) and Q25); 
	      Q27 <= (intern_pos(30) and Q26); 
	      Q28 <= (intern_pos(31) and Q27); 
	      Q29 <= (intern_pos(7) and Q28); 
	      Q30 <= (intern_pos(32) and Q29); 
	      Q31 <= (intern_pos(26) and Q30); 
	      Q32 <= (intern_pos(13) and Q31); 
	      Q33 <= (intern_pos(30) and Q32); 
	      Q34 <= (intern_pos(33) and Q33); 
	      Q35 <= (intern_pos(7) and Q34); 
	      Q36 <= (intern_pos(24) and Q35); 
	      Q37 <= (intern_pos(34) and Q36); 
	      Q38 <= (intern_pos(35) and Q37); 
	      Q39 <= (intern_pos(36) and Q38); 
	      Q40 <= (intern_pos(36) and Q39); 
	      Q41 <= (intern_pos(34) and Q40); 
	      Q42 <= (intern_pos(35) and Q41); 
	      Q43 <= (intern_pos(17) and Q42); 
	      Q44 <= (intern_pos(37) and Q43); 
	      Q45 <= (intern_pos(38) and Q44); 
	      Q46 <= (intern_pos(39) and Q45); 
	      Q47 <= (intern_pos(36) and Q46); 
	      Q48 <= (intern_pos(28) and Q47); 
	      Q49 <= (intern_pos(40) and Q48); 
	      Q50 <= (intern_pos(4) and Q49); 
	      Q51 <= (intern_pos(41) and Q50); 
	      Q52 <= (intern_pos(42) and Q51); 
	      Q53 <= (intern_pos(28) and Q52); 
	      Q54 <= (intern_pos(43) and Q53); 
	      Q55 <= (intern_pos(44) and Q54); 
	      Q56 <= (intern_pos(28) and Q55); 
	      Q57 <= (intern_pos(40) and Q56); 
	      Q58 <= (intern_pos(44) and Q57); 
	      Q59 <= (intern_pos(4) and Q58); 
	      Q60 <= (intern_pos(28) and Q59); 
	      Q61 <= (intern_pos(43) and Q60); 
	      Q62 <= (intern_pos(42) and Q61); 
	      Q63 <= (intern_pos(39) and Q62); 
	      Q64 <= (intern_pos(45) and Q63); 
	      Q65 <= (intern_pos(39) and Q64); 
	      Q66 <= (intern_pos(40) and Q65); 
	      Q67 <= (intern_pos(6) and Q66); 
	      Q68 <= (intern_pos(41) and Q67); 
	      Q69 <= (intern_pos(4) and Q68); 
	      Q70 <= (intern_pos(42) and Q69); 
	      Q71 <= (intern_pos(38) and Q70); 
	      Q72 <= (intern_pos(41) and Q71); 
	      Q73 <= (intern_pos(42) and Q72); 
	      Q74 <= (intern_pos(4) and Q73); 
	      Q75 <= (intern_pos(46) and Q74); 
	      Q76 <= (intern_pos(39) and Q75); 
	      Q77 <= (intern_pos(47) and Q76); 
	      Q78 <= (intern_pos(38) and Q77); 
	      Q79 <= (intern_pos(1) and Q78); 
	      Q80 <= (intern_pos(37) and Q79); 
	      Q81 <= (intern_pos(25) and Q80); 
	      Q82 <= (intern_pos(48) and Q81); 
	      Q83 <= (intern_pos(25) and Q82); 
	      Q84 <= (intern_pos(49) and Q83); 
	      Q178 <= (intern_pos(34) and Q3); 
	      Q179 <= (intern_pos(0) and Q178); 
	      Q180 <= (intern_pos(10) and Q179); 
	      Q181 <= (intern_pos(0) and Q180); 
	      Q182 <= (intern_pos(0) and Q181); 
	      Q183 <= (intern_pos(0) and Q182); 
	      Q184 <= (intern_pos(10) and Q183); 
	      Q185 <= (intern_pos(0) and Q184); 
	      Q186 <= (intern_pos(23) and Q185); 
	      Q187 <= (intern_pos(0) and Q186); 
	      Q188 <= (intern_pos(0) and Q187); 
	      Q189 <= (intern_pos(38) and Q188); 
	      Q190 <= (intern_pos(15) and Q189); 
	      Q191 <= (intern_pos(0) and Q190); 
	      Q192 <= (intern_pos(10) and Q191); 
	      Q193 <= (intern_pos(0) and Q192); 
	      Q194 <= (intern_pos(23) and Q193); 
	      Q195 <= (intern_pos(0) and Q194); 
	      Q196 <= (intern_pos(0) and Q195); 	
		 end if; 
		 	 
	 end process; 

 debug0 <= Q16 or Q84 or Q114; 

 debug1 <= Q99 or Q114 or Q196; 

 debug2 <= Q84 or Q175 or Q196; 

hit(0) <= debug0; 
hit(1) <= debug1; 
hit(2) <= debug2;

end STRUCTURAL; 

