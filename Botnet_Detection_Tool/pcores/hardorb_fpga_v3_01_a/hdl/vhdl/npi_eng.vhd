----------------------------------------------------------------------
----                                                              ----
---- NPI DMA Engine                                               ----
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
-- Last Modified: Feb 2010 by Ali Akbar Zarezadeh (akzare) to fit inside PICSY project
-- HardORB FPGA project
-- (University of Potsdam, Computer Science Department)

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity npi_eng is
generic (
   C_DEBUG_MODE : integer := 0;	-- 0 = disable, 1 = enable

   C_TCP_OPERATION_MODE    : integer := 0;	-- 0 = NoTCP, 1 = TCP_Server, 2 = TCP_Client, 3 = TCP_Server_Client   
   C_RD_MEMBLK_ADDR        : std_logic_vector := x"00800000";
   C_WR_MEMBLK_ADDR        : std_logic_vector := x"07600000";
   C_TOTAL_BYTE_NUM        : integer := 640;
	
   C_NPI_BURST_SIZE        : integer := 256;
   C_NPI_ADDR_WIDTH        : integer := 32;
   C_NPI_DATA_WIDTH        : integer := 64;
   C_NPI_BE_WIDTH          : integer := 8;
   C_NPI_RDWDADDR_WIDTH    : integer := 4);
port(
   NPI_Clk                 : in     std_logic;
   Sys_Clk                 : in     std_logic;
   NPI_RST                 : in     std_logic;

   NPI_Addr                : out    std_logic_vector(C_NPI_ADDR_WIDTH - 1 downto 0);
   NPI_AddrReq             : out    std_logic;
   NPI_AddrAck             : in     std_logic;
   NPI_RNW                 : out    std_logic;
   NPI_Size                : out    std_logic_vector(3 downto 0);
   NPI_WrFIFO_Data         : out    std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
   NPI_WrFIFO_BE           : out    std_logic_vector(C_NPI_BE_WIDTH - 1 downto 0);
   NPI_WrFIFO_Push         : out    std_logic;
   NPI_RdFIFO_Data         : in     std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
   NPI_RdFIFO_Pop          : out    std_logic;
   NPI_RdFIFO_RdWdAddr     : in     std_logic_vector(C_NPI_RDWDADDR_WIDTH - 1 downto 0);
   NPI_WrFIFO_Empty        : in     std_logic;
   NPI_WrFIFO_AlmostFull   : in     std_logic;
   NPI_WrFIFO_Flush        : out    std_logic;
   NPI_RdFIFO_Empty        : in     std_logic;
   NPI_RdFIFO_Flush        : out    std_logic;
   NPI_RdFIFO_Latency      : in     std_logic_vector(1 downto 0);
   NPI_RdModWr             : out    std_logic;
   NPI_InitDone            : in     std_logic;

------------------------ TEST -------------------    
tst_burst_cnt_one: out STD_LOGIC;
tst_burst_cnt: out STD_LOGIC_VECTOR (5 downto 0);
------------------------ TEST -------------------    
   -- reader interface
   DMA_RD_INIT             : out    std_logic;
   DMA_RD_DREQ             : in     std_logic;     -- Data request
   DMA_RD_DACK             : out    std_logic;     -- Data ack
   DMA_RD_DATA             : out    std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
   DMA_RD_BURST_END        : out    std_logic;

   -- writer interface
   DMA_WR_RST              : in     std_logic; 
   DMA_WR_DREQ             : in     std_logic; 
	 DMA_WR                  : out    std_logic;
	 DMA_WR_DATA             : in     std_logic_vector(C_NPI_DATA_WIDTH - 1 downto 0);
	 DMA_FIFOWR_RD_COUNT     : in     std_logic_vector(10 downto 0);
   DMA_WR_DRDY             : in     std_logic
	);
end entity;

architecture arch_npi_eng of npi_eng is

function get_NPI_Size(constant C_NPI_DATA_WIDTH : integer; constant C_NPI_BURST_SIZE : integer) return std_logic_vector is
BEGIN
   Case C_NPI_BURST_SIZE is
      When 4 => 
         If C_NPI_DATA_WIDTH = 64 Then
         ASSERT FALSE
            REPORT "4 byte NPI Burst size is not supported for 64bit interface!"
            SEVERITY ERROR;
            return x"F";
         Else
            return x"0";
         End If;
         
      When 8 => 
         If C_NPI_DATA_WIDTH = 64 Then
            return x"0";
         Else
--            return x"2"; -- only for testing simulation
            REPORT "8 byte NPI Burst size is not supported for 32bit interface!"
            SEVERITY ERROR;
            return x"F";
         End If;

      When 16 =>
         If C_NPI_DATA_WIDTH = 64 Then
            return x"1";
         Else
            return x"1";
         End If;

      When 32 =>      
         If C_NPI_DATA_WIDTH = 64 Then
            return x"2";
         Else
            return x"2";
         End If;
         
      When 64 =>
         If C_NPI_DATA_WIDTH = 64 Then
            return x"3";
         Else
            return x"3";
         End If;

      When 128 =>
         If C_NPI_DATA_WIDTH = 64 Then
            return x"4";
         Else
            return x"4";
         End If;
      When 256 =>                   
         If C_NPI_DATA_WIDTH = 64 Then
            return x"5";
         Else
            ASSERT FALSE
               REPORT "NPI Burst size is not supported!"
               SEVERITY ERROR;
            return x"F";
         End If;

      When Others => 
         ASSERT FALSE
            REPORT "NPI Burst size is not supported!"
            SEVERITY ERROR;
         return x"F";
   End Case;
END FUNCTION get_NPI_Size;

--constant RD_BURST_LENGHT : integer := C_TOTAL_BYTE_NUM / C_NPI_BURST_SIZE;
constant WR_BURST_LENGHT : integer := C_NPI_BURST_SIZE / 4;

--constant RD_BURST_LENGHT : integer := 8;
constant RD_BURST_LENGHT : std_logic_vector(5 downto 0) := conv_std_logic_vector(integer'pos((C_TOTAL_BYTE_NUM / C_NPI_BURST_SIZE)), 6);
   
--signal rd_burst_cnt              : integer range 0 to RD_BURST_LENGHT;
signal rd_burst_cnt : std_logic_vector(5 downto 0);
signal rd_burst_cnt_one : std_logic;

signal rd_addr_cnt_i : std_logic_vector(C_NPI_ADDR_WIDTH - 1 downto 0);   
signal wr_addr_cnt_i : std_logic_vector(C_NPI_ADDR_WIDTH - 1 downto 0);   

signal NPI_AddrReq_i : std_logic;
signal NPI_RNW_i : std_logic;
signal NPI_RdFIFO_Pop_i : std_logic;

signal NPI_RST_i : std_logic;
signal RD_Req : std_logic;

signal DMA_RD_DataReq : std_logic;

signal DMA_RD_DACK_D0 : std_logic;
signal DMA_RD_DACK_D1 : std_logic;

signal wr_state_cnt : std_logic_VECTOR(1 downto 0);
signal wr_burst_cnt : integer range 0 to 255;
--signal WR_START : std_logic;
signal DMA_WR_DREQ_D : std_logic;
signal WR_BUSY : std_logic;
signal WR_Req : std_logic;
signal RD_BUSY : std_logic;
signal DMA_WR_DataReq : std_logic;

signal NPI_RdFIFO_Empty_D : std_logic;
signal NPI_WrFIFO_Empty_D : std_logic;

BEGIN
------------------------ TEST -------------------    
DEBUG: if C_DEBUG_MODE = 1 generate
tst_burst_cnt_one <= rd_burst_cnt_one;
--tst_burst_cnt <= conv_std_logic_vector(integer'pos(rd_burst_cnt), 4);
tst_burst_cnt <= rd_burst_cnt;
end generate;

DEBUG_NON: if C_DEBUG_MODE = 0 generate
tst_burst_cnt_one <= '0';
tst_burst_cnt <= (others => '0');
end generate;
------------------------ TEST -------------------    

DMA_RD_BURST_HNDLR : PROCESS(NPI_CLK)
BEGIN
   If NPI_CLK'event And NPI_CLK = '1' Then
      If (NPI_RST_i = '1') Then
         rd_burst_cnt <= RD_BURST_LENGHT;
      ElsIf (NPI_AddrAck = '1') Then
         If (rd_burst_cnt_one = '1') Then
            rd_burst_cnt <= RD_BURST_LENGHT;
         Else
            rd_burst_cnt <= rd_burst_cnt - 1;
         End If;
      End If;
   End If;
END PROCESS DMA_RD_BURST_HNDLR;

rd_burst_cnt_one <= '1' When rd_burst_cnt = 1 Else '0';
DMA_RD_BURST_END <= rd_burst_cnt_one;

DMA_RD_ADDR_HNDLR : PROCESS(NPI_CLK)
BEGIN
   If NPI_CLK'event And NPI_CLK = '1' Then
      If (NPI_RST_i = '1') Then
         rd_addr_cnt_i <= C_RD_MEMBLK_ADDR;
      ElsIf (NPI_AddrAck = '1') Then
         If (rd_burst_cnt_one = '1') Then
            rd_addr_cnt_i <= C_RD_MEMBLK_ADDR;
         Else
            rd_addr_cnt_i <= rd_addr_cnt_i + C_NPI_BURST_SIZE;
         End If;
      End If;
   End If;
END PROCESS DMA_RD_ADDR_HNDLR;

DMA_RD_DataReq <= DMA_RD_DREQ;

NPI_RST_i <= Not NPI_InitDone Or NPI_RST;   

DMA_ADDRREQ_HNDLR : PROCESS (NPI_CLK)
BEGIN
   If NPI_CLK'event And NPI_CLK = '1' Then
      If NPI_RST_i = '1' Then
         NPI_AddrReq_i <= '0';
         WR_BUSY <= '0';
         RD_BUSY <= '0';
      ElsIf NPI_AddrAck = '1' Then
         NPI_AddrReq_i <= '0';
      ElsIf (RD_Req = '1' and WR_BUSY = '0') Then
         NPI_AddrReq_i <= '1';
         RD_BUSY <= '1';
      ElsIf (NPI_RdFIFO_Empty = '1' and NPI_RdFIFO_Empty_D = '0') Then
         RD_BUSY <= '0';
      ElsIf (WR_Req = '1' and RD_BUSY = '0') Then
         NPI_AddrReq_i <= '1';
         WR_BUSY <= '1';
      ElsIf (NPI_WrFIFO_Empty = '1' and NPI_WrFIFO_Empty_D = '0') Then
         WR_BUSY <= '0';
      End If;
      NPI_RdFIFO_Empty_D <= NPI_RdFIFO_Empty;
      NPI_WrFIFO_Empty_D <= NPI_WrFIFO_Empty;
   End If;
END PROCESS DMA_ADDRREQ_HNDLR;

NPI_RNW_i <= NPI_AddrReq_i and (not WR_BUSY);
NPI_RNW <= NPI_RNW_i;
NPI_AddrReq <= NPI_AddrReq_i;

RD_Req <= '1' When NPI_AddrAck = '0' And DMA_RD_DataReq = '1' Else '0';
WR_Req <= '1' When NPI_AddrAck = '0' And DMA_WR_DataReq = '1' Else '0';

NPI_RdFIFO_Pop_i <= Not NPI_RdFIFO_Empty;

ADDRSS_RD : if (C_TCP_OPERATION_MODE = 1) generate
NPI_Addr <= rd_addr_cnt_i;
end generate;

ADDRSS_WR : if (C_TCP_OPERATION_MODE = 2) generate
NPI_Addr <= wr_addr_cnt_i;
end generate;

ADDRSS_RDWR : if (C_TCP_OPERATION_MODE = 3) generate
NPI_Addr <= rd_addr_cnt_i When RD_BUSY = '1' Else wr_addr_cnt_i;
end generate;

NPI_Size <= get_NPI_Size(C_NPI_DATA_WIDTH, C_NPI_BURST_SIZE);
NPI_RdFIFO_Flush <= NPI_RST_i;

NPI_RdFIFO_Pop <= NPI_RdFIFO_Pop_i;

-- Data are fliped
DATA64: if C_NPI_DATA_WIDTH = 64 generate
DMA_RD_DATA <= NPI_RdFIFO_Data(31 downto 0) & NPI_RdFIFO_Data(63 downto 32);
end generate;

DATA32: if C_NPI_DATA_WIDTH = 32 generate
DMA_RD_DATA <= NPI_RdFIFO_Data(31 downto 0);
end generate;


PROCESS (NPI_Clk)
BEGIN
   If NPI_Clk'event And NPI_CLK = '1' Then
      If NPI_RST_i = '1' Then
         DMA_RD_DACK_D0 <= '1';
         DMA_RD_DACK_D1 <= '1';
      Else
         DMA_RD_DACK_D0 <= NPI_RdFIFO_Empty;
         DMA_RD_DACK_D1 <= DMA_RD_DACK_D0;
      End If;
   End If;
END PROCESS;

DMA_RD_DACK <= Not NPI_RdFIFO_Empty When NPI_RdFIFO_Latency = "00" Else
            Not DMA_RD_DACK_D0 When NPI_RdFIFO_Latency = "01" Else
            Not DMA_RD_DACK_D1 When NPI_RdFIFO_Latency = "10" Else '0';

DMA_RD_INIT <= NPI_InitDone;

DMA_WR_ADDR_HNDLR: PROCESS(NPI_CLK)
BEGIN
   If NPI_CLK'event And NPI_CLK = '1' Then
      DMA_WR_DREQ_D <= DMA_WR_DREQ;
--      IF NPI_RST_i = '1' Then
--         WR_START <= '0';
--      ELSIF (DMA_WR_DREQ = '1' and DMA_WR_DREQ_D = '0') then 
--         WR_START <= '1';
--      End If;

      If (NPI_RST_i = '1' or (DMA_WR_DREQ = '1' and DMA_WR_DREQ_D = '0')) Then
         wr_addr_cnt_i <= C_WR_MEMBLK_ADDR;
      ElsIF NPI_AddrAck = '1' Then
--         IF (WR_START = '1') then 
--            wr_addr_cnt_i <= C_WR_MEMBLK_ADDR;
--            WR_START <= '0';
--         Else
            wr_addr_cnt_i <= wr_addr_cnt_i + C_NPI_BURST_SIZE;
--         End If;
      End If;
   End If;
END PROCESS DMA_WR_ADDR_HNDLR;

DMA_WR_HNDLR: process (NPI_CLK)
BEGIN
   if NPI_CLK'event and NPI_CLK = '1' then
      if NPI_RST_i = '1' then
         wr_state_cnt <= (others => '0');

         NPI_RdModWr      <= '0';
         NPI_WrFIFO_Data  <= (Others => '0'); 
         NPI_WrFIFO_BE    <= (Others => '0'); 
         NPI_WrFIFO_Push  <= '0'; 
         NPI_WrFIFO_Flush <= '1';

         DMA_WR <= '0';

         DMA_WR_DataReq <= '0';

         wr_burst_cnt <= WR_BURST_LENGHT;
      else
         NPI_RdModWr      <= '0';
         NPI_WrFIFO_Data  <= (Others => '0'); 
         NPI_WrFIFO_BE    <= (Others => '0'); 
         NPI_WrFIFO_Push  <= '0'; 
         NPI_WrFIFO_Flush <= '0';

         DMA_WR <= '0';

         DMA_WR_DataReq <= '0';
         
--         wr_burst_cnt <= WR_BURST_LENGHT - 1;
         wr_burst_cnt <= WR_BURST_LENGHT;

         case wr_state_cnt is
				  when "00" =>
              if (DMA_WR_DREQ = '1' or DMA_WR_DRDY = '1') then 
                wr_state_cnt <= "01";
              else
                wr_state_cnt <= "00";
              end if;

				  when "01" =>
              if (conv_integer(DMA_FIFOWR_RD_COUNT) >= WR_BURST_LENGHT) then
--              if (conv_integer(DMA_FIFOWR_RD_COUNT) >= (C_NPI_BURST_SIZE-2)) then
--              if (conv_integer(DMA_FIFOWR_RD_COUNT) >= 6) then
--                wr_burst_cnt <= WR_BURST_LENGHT - 1;
                wr_burst_cnt <= WR_BURST_LENGHT;
                wr_state_cnt <= "10";
--              elsif (DMA_WR_DREQ = '0' and (conv_integer(DMA_FIFOWR_RD_COUNT) >= (NEW_BURST_SIZE-2))) then
--                wr_burst_cnt <= NEW_BURST_SIZE - 1; -- Todo: start decrease burst size to consume all data
--                wr_state_cnt <= "10";
--              elsif (DMA_WR_DREQ = '0') then
              elsif (DMA_WR_RST = '1') then
                wr_state_cnt <= "00";
              else
                wr_state_cnt <= "01";
              end if;

				  when "10" =>
              if (wr_burst_cnt = 1) then
                 DMA_WR_DataReq <= '1';
              end if;
              if (wr_burst_cnt = 0) then
                 wr_state_cnt <= "11";
              else 
                 wr_state_cnt <= "10";
                 wr_burst_cnt <= wr_burst_cnt - 1;
              end if;
              
              if (NPI_WrFIFO_AlmostFull = '0') then
                 DMA_WR <= '1';
                 if (wr_burst_cnt /= WR_BURST_LENGHT) then
                    NPI_WrFIFO_Data <= DMA_WR_DATA; 
                    NPI_WrFIFO_BE <= (Others => '1'); 
                    NPI_WrFIFO_Push <= '1'; 
                 end if;
              end if;

				  when "11" =>
              if (NPI_WrFIFO_Empty = '1') then
                 wr_state_cnt <= "00";
              else
                 wr_state_cnt <= "11";
              end if;
				  when others =>
              wr_state_cnt <= "00";
         end case;
      end if;  
   end if;  
END PROCESS DMA_WR_HNDLR;

end arch_npi_eng;

