-------------------------------------------------------------------------------
-- interrupt_register.vhd
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2006 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        interrupt_register.vhd
-- Description:       
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  sdma.vhd
--                      |- sample_cycle.vhd
--                      |- sdma_cntl.vhd
--                      |   |- ipic_if.vhd
--                      |   |   |-sample_cycle.vhd
--                      |   |- interrupt_register.vhd
--                      |   |- dmac_regfile_arb.vhd
--                      |   |- read_data_delay.vhd
--                      |   |- addr_arbiter.vhd
--                      |   |- port_arbiter.vhd
--                      |   |- tx_write_handler.vhd
--                      |   |- tx_read_handler.vhd
--                      |   |- tx_port_controller.vhd
--                      |   |- rx_read_handler.vhd
--                      |   |- rx_write_handler.vhd
--                      |   |- rx_port_controller.vhd
--                      |   |- tx_rx_state.vhd
--                      |
--                      |
--                      |- sdma_datapath.vhd
--                      |   |- reset_module.vhd
--                      |   |- channel_status_reg.vhd
--                      |   |- address_counter.vhd
--                      |   |- length_counter.vhd
--                      |   |- tx_byte_shifter.vhd
--                      |   |- rx_byte_shifter.vhd
--                  sdma_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:      Jeff Hao
-- History:
--  JYH     02/04/05
-- ~~~~~~
--  - Initial EDK Release
-- ^^^^^^
--  GAB     10/02/06
-- ~~~~~~
--  - Converted from verilog to vhdl
--  - Modified interrupt coalescing/delay timer to match hard DMA functionality
-- ^^^^^^
--  GAB     6/18/07
-- ~~~~~~
--  - Added channel reset logic to function keeping track of descriptor updates
-- ^^^^^^
--  GAB     8/30/07
-- ~~~~~~
--  - Added logic to prevent delay and coalesce counters from rolling over.  This
-- was done to fix an issue where the interrupt output de-asserted prematurely.
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "LLink_Clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_com"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    
use ieee.std_logic_misc.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.proc_common_pkg.log2;
use proc_common_v2_00_a.proc_common_pkg.max2;
use proc_common_v2_00_a.family_support.all;
use proc_common_v2_00_a.ipif_pkg.all;

library unisim;
use unisim.vcomponents.all;

library sdma_v1_00_b;
use sdma_v1_00_b.all;
use sdma_v1_00_b.sdma_pkg.all;

-------------------------------------------------------------------------------
entity interrupt_register is
    generic (
        C_PRESCALAR                     : integer := 1023;
        C_INSTANTIATE_TIMER_TX          : integer := 0;
        C_INSTANTIATE_TIMER_RX          : integer := 0;
        C_FAMILY                        : string := "virtex5"
    );
    port(
        LLink_Clk                       : in  std_logic;                 
        LLink_Rst                       : in  std_logic;                 
        
        PI_WrFIFO_Empty                 : in  std_logic;
        IPIC_RX_Int_Reg_WE              : in  std_logic;
        IPIC_TX_Int_Reg_WE              : in  std_logic;
        IPIC_TX_Cntl_Reg_WE             : in  std_logic;
        IPIC_RX_Cntl_Reg_WE             : in  std_logic;


        IPIC_WrDBus                     : in  std_logic_vector(0 to 31); 
        
        TX_End                          : in  std_logic;                 
        TX_IntOnEnd                     : in  std_logic;                 
        TX_ChannelRST                   : in  std_logic;                 
        TX_Control_Reg                  : in  std_logic_vector(0 to 31);
        TX_SOF                          : in std_logic;
        TX_EOF                          : in std_logic;
        Tx_Error_Int_Detect             : in std_logic;
        Tx_IRQ_Reg                      : out std_logic_vector(0 to 31);

        RX_End                          : in  std_logic;                 
        RX_IntOnEnd                     : in  std_logic;                 
        RX_ChannelRST                   : in  std_logic;                 
        RX_Control_Reg                  : in  std_logic_vector(0 to 31);
        RX_SOF                          : in  std_logic;
        RX_EOF                          : in  std_logic;
        Rx_Error_Int_Detect             : in  std_logic;
        Rx_IRQ_Reg                      : out std_logic_vector(0 to 31);

        SDMA_Rx_IntOut                  : out std_logic;
        SDMA_Tx_IntOut                  : out std_logic
    );
end Interrupt_Register;


-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of interrupt_register is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
constant ZERO_COUNT         : std_logic_vector(0 to 3) := (others => '0');
constant ZERO_VALUE         : std_logic_vector(0 to 7) := (others => '0');
constant ALL_ONES           : std_logic_vector(0 to 3) := (others => '1');
-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal tx_int_cnt           : std_logic_vector(0 to 3);
signal rx_int_cnt           : std_logic_vector(0 to 3);
signal tx_int_detect        : std_logic;
signal rx_int_detect        : std_logic;

signal tx_lost_int_detect   : std_logic;
signal rx_lost_int_detect   : std_logic;
signal tx_int_enable        : std_logic;
signal rx_int_enable        : std_logic;


signal tx_dly_cnt           : std_logic_vector(0 to 1);
signal rx_dly_cnt           : std_logic_vector(0 to 1);
signal tx_timer_int_detect  : std_logic;
signal rx_timer_int_detect  : std_logic;

signal timer_ack_tx_i       : std_logic;
signal timer_ack_rx_i       : std_logic;


signal timer_int_tx         : std_logic;
signal timer_int_rx         : std_logic;
signal timer_ce_tx          : std_logic;
signal timer_ce_rx          : std_logic;
signal timer_ce_mask_tx     : std_logic;
signal timer_ce_mask_rx     : std_logic;

signal clk_divide_cnt       : std_logic_vector(0 to 9); 
signal timer_ce             : std_logic;

signal tx_dlytmr_value      : std_logic_vector(0 to 7);
signal rx_dlytmr_value      : std_logic_vector(0 to 7);

signal tx_irq_reg_i         : std_logic_vector(0 to 31);
signal rx_irq_reg_i         : std_logic_vector(0 to 31);

signal timer_reg_tx         : std_logic_vector(0 to 7);
signal coalsc_reg_tx        : std_logic_vector(0 to 7);
signal timer_reg_rx         : std_logic_vector(0 to 7);
signal coalsc_reg_rx        : std_logic_vector(0 to 7);

signal timer_rst_tx         : std_logic;
signal timer_rst_rx         : std_logic;

signal incr_tx_coalesce_cnt : std_logic;
signal load_tx_coalesce_cnt : std_logic;
signal incr_rx_coalesce_cnt : std_logic;
signal load_rx_coalesce_cnt : std_logic;
signal rx_coalesce_cnt      : std_logic_vector(0 to 7);
signal tx_coalesce_cnt      : std_logic_vector(0 to 7);
signal coal_int_rx          : std_logic;
signal coal_int_tx          : std_logic;

signal tx_desc_update       : std_logic;
signal tx_done              : std_logic;
signal rx_desc_update       : std_logic;
signal rx_done              : std_logic;
signal tx_eof_reg           : std_logic;
signal rx_eof_reg           : std_logic;

signal tx_timeout_value     : std_logic_vector(0 to 7);
signal rx_timeout_value     : std_logic_vector(0 to 7);
signal tx_timer_load        : std_logic;
signal rx_timer_load        : std_logic;
signal rx_tout_eq_zero      : std_logic;
signal tx_tout_eq_zero      : std_logic;

signal tx_ipif_load         : std_logic;
signal rx_ipif_load         : std_logic;

--signal tx_coalcnt_overflow  : std_logic; --FUTURE
--signal tx_dlycnt_overflow   : std_logic; --FUTURE
--signal rx_coalcnt_overflow  : std_logic; --FUTURE
--signal rx_dlycnt_overflow   : std_logic; --FUTURE
--signal ResetErrIrq          : std_logic; --FUTURE



-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

SDMA_Rx_IntOut  <=  (rx_int_enable and ((Rx_Error_Int_Detect and RX_Control_Reg(CHNL_CNTRL_IRQERREN_BIT)) 
                                     or (rx_int_detect       and RX_Control_Reg(CHNL_CNTRL_IRQCOALEN_BIT))
                                     or (rx_timer_int_detect and RX_Control_Reg(CHNL_CNTRL_IRQDLYEN_BIT))));




SDMA_Tx_IntOut  <=  (tx_int_enable and ((Tx_Error_Int_Detect and TX_Control_Reg(CHNL_CNTRL_IRQERREN_BIT)) 
                                     or (tx_int_detect       and TX_Control_Reg(CHNL_CNTRL_IRQCOALEN_BIT))
                                     or (tx_timer_int_detect and TX_Control_Reg(CHNL_CNTRL_IRQDLYEN_BIT))));


-- Transmit Interrupt Status                    
tx_irq_reg_i    <= tx_dlytmr_value & tx_coalesce_cnt 
                    & "00" & tx_int_cnt & tx_dly_cnt 
                    & "00000" & Tx_Error_Int_Detect 
                    & tx_timer_int_detect & tx_int_detect;

-- Receieve Interrupt Status                    
rx_irq_reg_i    <= rx_dlytmr_value & rx_coalesce_cnt 
                    & "00" & rx_int_cnt & rx_dly_cnt 
                    & "00000" & Rx_Error_Int_Detect 
                    & rx_timer_int_detect & rx_int_detect;
                    
Tx_IRQ_Reg      <= tx_irq_reg_i;
Rx_IRQ_Reg      <= rx_irq_reg_i;


-- Transmit Delay Timer and Coalesce Counter TC Values
timer_reg_tx    <= TX_Control_Reg(0 to 7);
coalsc_reg_tx   <= TX_Control_Reg(8 to 15);

-- Receive Delay Timer and Coalesce Counter TC Values
timer_reg_rx    <= RX_Control_Reg(0 to 7);
coalsc_reg_rx   <= RX_Control_Reg(8 to 15);

-- Transmit / Receive Global Interrupt Enable
tx_int_enable   <= TX_Control_Reg(CHNL_CNTRL_IRQEN_BIT);
rx_int_enable   <= RX_Control_Reg(CHNL_CNTRL_IRQEN_BIT);


GEN_CLK_DIVIDE : if C_INSTANTIATE_TIMER_TX = 1 
                 or C_INSTANTIATE_TIMER_RX = 1 generate


    -------------------------------------------------------------------------------
    -- CLK_DIVIDE_PROCESS
    -------------------------------------------------------------------------------
    CLK_DIVIDE_PROCESS : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if (LLink_Rst ='1' or timer_ce = '1')then
                    clk_divide_cnt <= (others => '0');
                else
                    clk_divide_cnt <= std_logic_vector(unsigned(clk_divide_cnt) + 1);
                end if;
            end if;
        end process CLK_DIVIDE_PROCESS;

    -- Generate Timer CE and C_PRESCALAR terminal count
    timer_ce <= '1' when to_integer(unsigned(clk_divide_cnt)) = C_PRESCALAR
         else   '0';

end generate GEN_CLK_DIVIDE;              
    

DONT_GEN_CLK_DIVICE : if C_INSTANTIATE_TIMER_TX = 0 
                      and C_INSTANTIATE_TIMER_RX = 0 generate
 

    clk_divide_cnt <= (others => '0');

    timer_ce       <= '0';                     
                      
end generate DONT_GEN_CLK_DIVICE;                      

-------------------------------------------------------------------------------
-- Transmit interrupt
-------------------------------------------------------------------------------
GEN_TX_INTR : if C_INSTANTIATE_TIMER_TX = 1 generate

    -- Seting delay timeout value to zero will reset
    -- the delay timer preventing a delay timeout
    tx_tout_eq_zero <= '1' when timer_reg_tx=ZERO_VALUE
                  else '0';

    timer_ce_tx <= timer_ce and timer_ce_mask_tx;

    timer_rst_tx <= '1' when timer_int_tx='1' 
                        or (coal_int_tx='1' and TX_Control_Reg(CHNL_CNTRL_IRQCOALEN_BIT)='1')
                        or TX_SOF='0'
                        or TX_ChannelRST = '1'
               else '0';

    TX_Source_Rdy : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if (LLink_Rst='1' or timer_rst_tx='1')then
                    timer_ce_mask_tx <= '0';
                elsif (TX_EOF='0')then
                    timer_ce_mask_tx <= '1';
                end if;

            end if;
        end process TX_Source_Rdy;

    -- Delay Timer - generate a delay timeout interrupt when timeout value is
    -- reached.
    TX_INTRPT_TMR_I : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1' or timer_rst_tx='1' or tx_tout_eq_zero='1')then
                    tx_dlytmr_value <= (others => '0');
                    timer_int_tx    <= '0';
                elsif(tx_dlytmr_value = timer_reg_tx)then
                    tx_dlytmr_value <= (others => '0');
                    timer_int_tx    <= '1';
                elsif(timer_ce_tx='1')then
                    tx_dlytmr_value <= std_logic_vector(unsigned(tx_dlytmr_value) + 1);
                    timer_int_tx    <= '0';
                end if;
            end if;
        end process TX_INTRPT_TMR_I;
        
end generate GEN_TX_INTR;

GEN_NO_TX_INTR : if C_INSTANTIATE_TIMER_TX = 0 generate
    timer_ce_tx         <= '0';
    timer_rst_tx        <= '0';
    timer_ce_mask_tx    <= '0';
    timer_int_tx        <= '0';
end generate GEN_NO_TX_INTR;


-------------------------------------------------------------------------------
-- Receive interrupt
-------------------------------------------------------------------------------
GEN_RX_INTR : if C_INSTANTIATE_TIMER_RX = 1 generate

    -- Seting delay timeout value to zero will reset
    -- the delay timer preventing a delay timeout
    rx_tout_eq_zero <= '1' when timer_reg_rx=ZERO_VALUE
                  else '0';

    timer_ce_rx <= timer_ce and timer_ce_mask_rx;

    timer_rst_rx <= '1' when timer_int_rx='1' 
                        or (coal_int_rx='1' and RX_Control_Reg(CHNL_CNTRL_IRQCOALEN_BIT)='1')
                        or RX_SOF='0'
                        or RX_ChannelRST = '1'
               else '0';

    RX_Source_Rdy : process(LLink_Clk)    
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if (LLink_Rst='1' or timer_rst_rx='1')then
                    timer_ce_mask_rx <= '0';
                elsif(RX_EOF='0')then
                    timer_ce_mask_rx <= '1';
                end if;
            end if;
        end process RX_Source_Rdy;

    -- Delay Timer - generate a delay timeout interrupt when timeout value is
    -- reached.
    RX_INTRPT_TMR_I : process(LLink_Clk)
        begin
            if(LLink_Clk'EVENT and LLink_Clk='1')then
                if(LLink_Rst = '1' or timer_rst_rx='1' or rx_tout_eq_zero='1')then
                    rx_dlytmr_value <= (others => '0');
                    timer_int_rx    <= '0';
                elsif(rx_dlytmr_value = timer_reg_rx)then
                    rx_dlytmr_value <= (others => '0');
                    timer_int_rx    <= '1';
                elsif(timer_ce_rx='1')then
                    rx_dlytmr_value <= std_logic_vector(unsigned(rx_dlytmr_value) + 1);
                    timer_int_rx    <= '0';
                end if;
            end if;
        end process RX_INTRPT_TMR_I;


end generate GEN_RX_INTR;

GEN_NO_RX_INTR : if C_INSTANTIATE_TIMER_RX = 0 generate
    timer_ce_rx         <= '0';
    timer_rst_rx        <= '0';
    timer_ce_mask_rx    <= '0';
    timer_int_rx        <= '0';
end generate GEN_NO_RX_INTR;

-------------------------------------------------------------------------------
-- Transmit Delay Counter
-------------------------------------------------------------------------------
TX_TMR_CNTR :   process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1') then
                tx_dly_cnt <=(others => '0');
            
-- GAB 8/30/07 - prevent rollover of counter            
--            elsif (Timer_Int_TX='1') then
            elsif (Timer_Int_TX='1' and tx_dly_cnt /= ALL_ONES(0 to 1)) then
                tx_dly_cnt      <= std_logic_vector(unsigned(tx_dly_cnt) + 1);
                        
            elsif (IPIC_TX_Int_Reg_WE='1' and IPIC_WrDBus(IRQ_REG_DLYIRQ_BIT)='1') then
                if (tx_dly_cnt /= ZERO_COUNT(0 to 1)) then
                    tx_dly_cnt  <= std_logic_vector(unsigned(tx_dly_cnt) - 1);
                end if;
            end if;
        end if;
    end process TX_TMR_CNTR;

-- FUTURE- Add overflow interrupt
--TX_TMR_CNTR_OF : process(LLink_Clk)
--    begin
--        if(LLink_Clk'EVENT and LLink_Clk='1')then
--            if (LLink_Rst='1' or TX_ChannelRST='1' or ) then
--                tx_dlycnt_overflow <= '0';
--            elsif(tx_dly_cnt = ALL_ONES(0 to 1) and Timer_Int_TX = '1' 
--            and TX_Control_Reg(DMA_CNTRL_TXOFERRDIS_BIT)='1')then
--                tx_dlycnt_overflow <= '1';
--            else
--                tx_dlycnt_overflow <= '0';
--            end if;
--        end if;
--    end process TX_TMR_CNTR_OF;

-- Transmit Delay Interrupt Event
tx_timer_int_detect <= '1' when (tx_dly_cnt /= ZERO_COUNT(0 to 1)) else '0';

-------------------------------------------------------------------------------
-- Receive Delay Counter
-------------------------------------------------------------------------------
RX_TMR_CNTR :   process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1') then
                rx_dly_cnt <=(others => '0');
            
-- GAB 8/30/07 - prevent rollover of counter            
--            elsif (Timer_Int_RX='1') then
            elsif (Timer_Int_RX='1' and rx_dly_cnt /= ALL_ONES(0 to 1)) then
                rx_dly_cnt      <= std_logic_vector(unsigned(rx_dly_cnt) + 1);
                        
            elsif (IPIC_RX_Int_Reg_WE='1' and IPIC_WrDBus(IRQ_REG_DLYIRQ_BIT)='1') then
                if (rx_dly_cnt /= ZERO_COUNT(0 to 1)) then
                    rx_dly_cnt  <= std_logic_vector(unsigned(rx_dly_cnt) - 1);
                end if;
            end if;
        end if;
    end process RX_TMR_CNTR;

-- Transmit Delay Interrupt Event
rx_timer_int_detect <= '1' when (rx_dly_cnt /= ZERO_COUNT(0 to 1)) else '0';

-------------------------------------------------------------------------------
-- Transmit Coalesce Counter
-------------------------------------------------------------------------------
-- Register and hold EOF until descriptor has been updated into 
-- remote memory
LOG_TX_EOF : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or TX_End='1' or TX_ChannelRST = '1')then
                tx_eof_reg <= '0';
            elsif(TX_EOF = '0') then
                tx_eof_reg <= '1';
            end if;
        end if;
    end process LOG_TX_EOF;

-- Issue a done if tx_end and interrupt on end is enabled and Use Interrupt On end is enabled
-- otherwise issue a done if an EOF has occured and Use Interrupt On end is disabled.
tx_done <= '1' when (TX_End='1' and TX_IntOnEnd='1' and TX_Control_Reg(CHNL_CNTRL_USEIOE_BIT)='1')
                 or (TX_End='1' and tx_eof_reg ='1' and TX_Control_Reg(CHNL_CNTRL_USEIOE_BIT)='0')
      else '0';

-- Do not register an end event interrupt until the PI Write FIFO
-- has been emptied.
TX_END_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or TX_ChannelRST = '1')then
                tx_desc_update          <= '0';
                incr_tx_coalesce_cnt    <= '0';
            elsif(tx_desc_update = '1' and PI_WrFIFO_Empty = '1')then
                tx_desc_update          <= '0';
                incr_tx_coalesce_cnt    <= '1';
            elsif(tx_done = '1' and tx_desc_update = '0')then
                tx_desc_update          <= '1';
                incr_tx_coalesce_cnt    <= '0';
            else
                tx_desc_update          <= tx_desc_update;
                incr_tx_coalesce_cnt    <= '0';
            end if;
        end if;
    end process TX_END_PROCESS;

REG_TX_IPIC_WR : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
                tx_ipif_load <= '0';
            elsif(IPIC_TX_Cntl_Reg_WE = '1' and IPIC_WrDBus(CHNL_CNTRL_IRQLDCNT_BIT) = '1')then
                tx_ipif_load <= '1';
            else
                tx_ipif_load <= '0';
            end if;
        end if;
    end process REG_TX_IPIC_WR;

load_tx_coalesce_cnt <= '1' when  tx_ipif_load = '1' 
                               or (timer_int_tx='1' and TX_Control_Reg(CHNL_CNTRL_IRQDLYEN_BIT)='1')
                               or coal_int_tx = '1'
                   else '0';                                

TX_CLSC_CNTR_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1') then
                tx_coalesce_cnt <= (others => '1');
            elsif(load_tx_coalesce_cnt = '1')then
                if(coalsc_reg_tx /= "00000000")then
                    tx_coalesce_cnt <= coalsc_reg_tx;
                else
                    tx_coalesce_cnt <= (others => '1');
                end if;
            elsif(incr_tx_coalesce_cnt = '1' and tx_coalesce_cnt /= ZERO_VALUE)then
                tx_coalesce_cnt <= std_logic_vector(unsigned(tx_coalesce_cnt) - 1);
            end if;
        end if;
    end process TX_CLSC_CNTR_PROCESS;
    
coal_int_tx <= '1' when tx_coalesce_cnt = ZERO_VALUE
          else '0';

TX_INT :   process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or TX_ChannelRST='1') then
                tx_int_cnt <=(others => '0');
            
-- GAB 8/30/07 - prevent rollover of counter            
--            elsif (coal_int_tx='1') then
            elsif (coal_int_tx='1' and tx_int_cnt /= ALL_ONES) then

                tx_int_cnt      <= std_logic_vector(unsigned(tx_int_cnt) + 1);
                        
            elsif (IPIC_TX_Int_Reg_WE='1' and IPIC_WrDBus(IRQ_REG_COALIRQ_BIT)='1') then
                if (tx_int_cnt /= ZERO_COUNT) then
                    tx_int_cnt  <= std_logic_vector(unsigned(tx_int_cnt) - 1);
                end if;
            end if;
        end if;
    end process TX_INT;

-- Transmit Coalesce Interrupt Event
tx_int_detect <= '1' when (tx_int_cnt /= ZERO_COUNT) else '0';

-------------------------------------------------------------------------------
-- Receive Coalesce Counter
-------------------------------------------------------------------------------
-- Register and hold EOF until descriptor has been updated into 
-- remote memory
LOG_RX_EOF : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or RX_End='1' or RX_ChannelRST = '1')then
                rx_eof_reg <= '0';
            elsif(RX_EOF = '0') then
                rx_eof_reg <= '1';
            end if;
        end if;
    end process LOG_RX_EOF;

-- Issue a done if tx_end and interrupt on end is enabled and Use Interrupt On end is enabled
-- otherwise issue a done if an EOF has occured and Use Interrupt On end is disabled.
rx_done <= '1' when (RX_End='1' and RX_IntOnEnd='1' and RX_Control_Reg(CHNL_CNTRL_USEIOE_BIT)='1')
                 or (RX_End='1' and rx_eof_reg ='1' and RX_Control_Reg(CHNL_CNTRL_USEIOE_BIT)='0')
      else '0';

-- Do not register an end event interrupt until the PI Write FIFO
-- has been emptied.
RX_END_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if(LLink_Rst = '1' or RX_ChannelRST = '1')then
                rx_desc_update          <= '0';
                incr_rx_coalesce_cnt    <= '0';
            elsif(rx_desc_update = '1' and PI_WrFIFO_Empty = '1')then
                rx_desc_update          <= '0';
                incr_rx_coalesce_cnt    <= '1';
            elsif(rx_done = '1' and rx_desc_update = '0')then
                rx_desc_update          <= '1';
                incr_rx_coalesce_cnt    <= '0';
            else
                rx_desc_update          <= rx_desc_update;
                incr_rx_coalesce_cnt    <= '0';
            end if;
        end if;
    end process RX_END_PROCESS;

REG_RX_IPIC_WR : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1') then
                rx_ipif_load <= '0';
            elsif(IPIC_RX_Cntl_Reg_WE = '1' and IPIC_WrDBus(CHNL_CNTRL_IRQLDCNT_BIT) = '1')then
                rx_ipif_load <= '1';
            else
                rx_ipif_load <= '0';
            end if;
        end if;
    end process REG_RX_IPIC_WR;

load_rx_coalesce_cnt <= '1' when  rx_ipif_load = '1' 
                               or (timer_int_rx='1' and RX_Control_Reg(CHNL_CNTRL_IRQDLYEN_BIT)='1')
                               or coal_int_rx = '1'
                   else '0';                                

RX_CLSC_CNTR_PROCESS : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or RX_ChannelRST='1') then
                rx_coalesce_cnt <= (others => '1');
            elsif(load_rx_coalesce_cnt = '1')then
                if(coalsc_reg_rx /= "00000000")then
                    rx_coalesce_cnt <= coalsc_reg_rx;
                else
                    rx_coalesce_cnt <= (others => '1');
                end if;
            elsif(incr_rx_coalesce_cnt = '1' and rx_coalesce_cnt /= ZERO_VALUE)then
                rx_coalesce_cnt <= std_logic_vector(unsigned(rx_coalesce_cnt) - 1);
            end if;
        end if;
    end process RX_CLSC_CNTR_PROCESS;
    
coal_int_rx <= '1' when rx_coalesce_cnt = ZERO_VALUE
          else '0';
    
RX_INT : process(LLink_Clk)
    begin
        if(LLink_Clk'EVENT and LLink_Clk='1')then
            if (LLink_Rst='1' or RX_ChannelRST='1') then
                rx_int_cnt <= (others => '0');
-- GAB 8/30/07 - prevent rollover of counter            
--            elsif (coal_int_rx='1') then 
            elsif (coal_int_rx='1' and rx_int_cnt /= ALL_ONES) then
                rx_int_cnt      <= std_logic_vector(unsigned(rx_int_cnt) + 1);
            
            elsif (IPIC_RX_Int_Reg_WE='1' and IPIC_WrDBus(IRQ_REG_COALIRQ_BIT)='1') then
                if (rx_int_cnt /= ZERO_COUNT) then
                    rx_int_cnt  <= std_logic_vector(unsigned(rx_int_cnt) - 1);
                end if;
            end if;
        end if;
    end process RX_INT;

-- Receive Coalesce Interrupt Event
rx_int_detect <= '1' when (rx_int_cnt /= ZERO_COUNT) else '0';


end implementation;
