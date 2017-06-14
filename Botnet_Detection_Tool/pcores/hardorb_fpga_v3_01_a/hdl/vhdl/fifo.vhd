----------------------------------------------------------------------
----                                                              ----
---- fifo wrapper                                                 ----
----                                                              ----
---- Author(s):                                                   ----
---- - Slavek Valach, s.valach@dspfpga.com                        ----
----                                                              ----
----------------------------------------------------------------------
----                                                              ----
---- Copyright (C) 2008 Authors and OPENCORES.ORG                 ----
----                                                              ----
---- This source file may be used and distributed without         ----
---- restriction provided that this copyright statement is not    ----
---- removed from the file and that any derivative work contains  ----
---- the original copyright notice and the associated disclaimer. ----
----                                                              ----
---- This source file is free software; you can redistribute it   ----
---- and/or modify it under the terms of the GNU General          ----
---- Public License as published by the Free Software Foundation; ----
---- either version 2.0 of the License, or (at your option) any   ----
---- later version.                                               ----
----                                                              ----
---- This source is distributed in the hope that it will be       ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied   ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ----
---- PURPOSE. See the GNU General Public License for more details.----
----                                                              ----
---- You should have received a copy of the GNU General           ----
---- Public License along with this source; if not, download it   ----
---- from http://www.gnu.org/licenses/gpl.txt                     ----
----                                                              ----
----------------------------------------------------------------------
-- Last Modified:Feb 2010 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity d_fifo is
generic (
   C_DEBUG_MODE                  : integer := 0;	-- 0 = disable, 1 = enable
   C_TCP_OPERATION_MODE          : integer := 0;	-- 0 = NoTCP, 1 = TCP_Server, 2 = TCP_Client, 3 = TCP_Server_Client   
   C_VD_DATA_WIDTH               : integer := 32;
   C_FAMILY                      : string  := "virtex4");
port (
-- System interface      
   Sys_Clk                       : in     std_logic;                    -- Base system clock
   NPI_CLK                       : in     std_logic;
   Sys_Rst                       : in     std_logic;                    -- System reset

-- DMA Channel interface
--   DMA_CLK                       : in     std_logic;     -- DMA clock time domain (the asynchronous FIFO will be used)
   DMA_RD_DREQ                   : out    std_logic;     -- Data request
   DMA_RD_DACK                   : in     std_logic;     -- Data ack
   DMA_RD_DATA                   : in     std_logic_vector(C_VD_DATA_WIDTH - 1 downto 0);
------------------------ TEST -------------------    
tst_fifo_wr_en: out STD_LOGIC;
------------------------ TEST -------------------    

-- User interface (the reader side)
   USER_RD_CLK                   : in     std_logic;                    -- User clk is used as an asynchronous read clock
   USER_RD_RST                   : in     std_logic;
   USER_RD_DREQ                  : in     std_logic;
   USER_RD                       : in     std_logic;
   USER_RD_DRDY                  : out    std_logic;
   USER_RD_DATA                  : out    std_logic_vector(7 downto 0);
   FIFORD_WR_COUNT               : out    std_logic_VECTOR(10 downto 0);
   
	 DMA_WR                        : in     std_logic;
	 DMA_WR_DATA                   : out    std_logic_vector(C_VD_DATA_WIDTH - 1 downto 0);
	 FIFOWR_RD_COUNT               : out    std_logic_VECTOR(10 downto 0);
	 USER_WR_DATA                  : in     std_logic_vector(7 downto 0);
	 USER_WR_CLK                   : in     std_logic;
	 USER_WR                       : in     std_logic;
   FIFOWR_FULL                   : out    std_logic;
   USER_WR_RST                   : in     std_logic;
   DMA_WR_DRDY                   : out    std_logic
   );

end d_fifo;

-----------------------------------------------------------------------------
-- Architecture section
-----------------------------------------------------------------------------
architecture implementation of d_fifo is

component dma_fifo_v4_rd_32
	port (
	din: IN std_logic_VECTOR(31 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(7 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	wr_data_count: OUT std_logic_VECTOR(10 downto 0));
end component;

component dma_fifo_v4_wr_32
	port (
	din: IN std_logic_VECTOR(7 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(31 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
  rd_data_count: OUT std_logic_VECTOR(10 downto 0)
--	wr_data_count: OUT std_logic_VECTOR(12 downto 0)
);
end component;

component dma_fifo_s6_rd_32
	port (
	din: IN std_logic_VECTOR(31 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(7 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	wr_data_count: OUT std_logic_VECTOR(10 downto 0));
end component;


constant low                     : std_logic := '0';
constant high                    : std_logic := '1';

signal fiford_rst                : std_logic;
signal fiford_data_out           : std_logic_vector(7 downto 0);
signal fiford_full               : std_logic;
signal fiford_empty              : std_logic;
signal fiford_wr_en              : std_logic;

signal fifowr_rst                : std_logic;
signal fifowr_empty              : std_logic;

--signal counter : std_logic_vector(31 downto 0);
signal int_FIFO_WR_COUNT : std_logic_VECTOR(10 downto 0);
--signal start_fill_fifo : std_logic;

begin -- architecture IMP
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_fifo_wr_en <= fiford_wr_en;
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_fifo_wr_en <= '0';
end generate;
------------------------ TEST -------------------    

   DMA_RD_DREQ <= '1' When (USER_RD_DREQ = '1') And (fiford_full = '0') Else '0';
   fiford_rst <= '1' When (Sys_Rst = '1') Or (USER_RD_RST = '1') Else '0';
   fifowr_rst <= '1' When (Sys_Rst = '1') Or (USER_WR_RST = '1') Else '0';
   USER_RD_DRDY <= Not fiford_empty;
   DMA_WR_DRDY <= Not fifowr_empty;

  fiford_wr_en <= '1' When DMA_RD_DACK = '1' And Sys_Rst = '0' Else '0';
  
gen_rd_v4 : if (C_FAMILY = "virtex4" and (C_TCP_OPERATION_MODE = 1 or C_TCP_OPERATION_MODE = 3) ) generate
   v4_fw_rd_32 :  If C_VD_DATA_WIDTH = 32 generate 
      data_fifo : dma_fifo_v4_rd_32   
      port map (
         din                     => DMA_RD_DATA, --counter,
         rd_clk                  => USER_RD_CLK,
         rd_en                   => USER_RD,
         rst                     => fiford_rst,
         wr_clk                  => NPI_CLK,
         wr_en                   => fiford_wr_en,--DMA_RD_DACK,
         dout                    => fiford_data_out,
         empty                   => fiford_empty,
         full                    => fiford_full,
         wr_data_count           => int_FIFO_WR_COUNT
			);
   End Generate;
End Generate;

gen_rd_s6 : if ((C_FAMILY = "spartan6" or C_FAMILY = "spartan6t") and (C_TCP_OPERATION_MODE = 1 or C_TCP_OPERATION_MODE = 3)) generate
   s6_fw_rd_32 :  If C_VD_DATA_WIDTH = 32 generate 
      data_fifo : dma_fifo_s6_rd_32   
      port map (
         din                     => DMA_RD_DATA,
         rd_clk                  => USER_RD_CLK,
         rd_en                   => USER_RD,
         rst                     => fiford_rst,
         wr_clk                  => NPI_CLK,
         wr_en                   => DMA_RD_DACK,
         dout                    => fiford_data_out,
         empty                   => fiford_empty,
         full                    => fiford_full,
         wr_data_count           => FIFORD_WR_COUNT
			);
   End Generate;
End Generate;

gen_wr_v4 : if (C_FAMILY = "virtex4" and (C_TCP_OPERATION_MODE = 2 or C_TCP_OPERATION_MODE = 3) ) generate
   v4_fw_wr_32 :  If C_VD_DATA_WIDTH = 32 generate 
      data_fifo : dma_fifo_v4_wr_32   
      port map (
         din                     => USER_WR_DATA,
         rd_clk                  => NPI_CLK,
         rd_en                   => DMA_WR,
         rst                     => fifowr_rst,
         wr_clk                  => USER_WR_CLK,
         wr_en                   => USER_WR,
         dout                    => DMA_WR_DATA,
         empty                   => fifowr_empty,
         full                    => FIFOWR_FULL,
         rd_data_count           => FIFOWR_RD_COUNT
--         wr_data_count           => open  
			);
   End Generate;
End Generate;

USER_RD_DATA <= fiford_data_out;

FIFORD_WR_COUNT <= int_FIFO_WR_COUNT;

--process (NPI_CLK)
--begin
--  
--	if rising_edge(NPI_CLK) then
--	  if Sys_Rst = '1' then
--        counter <= (others => '1');
--        fiford_wr_en <= '0';
--		  start_fill_fifo <= '0';
--		else 
--        if USER_RD_DREQ = '1' then
--		    fiford_wr_en <= '1';
--			 counter <= (others => '1');
--			 start_fill_fifo <= '1';
--		  elsif (conv_integer(int_FIFO_WR_COUNT) < (1000) and start_fill_fifo = '1') then
--		    fiford_wr_en <= '1';
--			 start_fill_fifo <= '1';
--          counter <= counter - 1;
--		  else
--		    fiford_wr_en <= '0';
--			 start_fill_fifo <= '0';
--		  end if;
--		end if;
--	end if;
--end process;

end implementation;
