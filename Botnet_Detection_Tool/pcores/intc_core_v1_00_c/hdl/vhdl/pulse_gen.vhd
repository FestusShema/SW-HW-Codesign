-------------------------------------------------------------------------------
-- $Id: pulse_gen.vhd,v 1.4 2006/05/25 08:53:13 nitink Exp $
-------------------------------------------------------------------------------
-- pulse_gen - entity / architecture
-------------------------------------------------------------------------------
--
--  ***************************************************************************
--  **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
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
-- Filename:        pulse_gen.vhd
-- Version:         v1.00c
-- Description:     state machine for generating the interrupt request output
--
-------------------------------------------------------------------------------
-- Structure:
--
--              intc.vhd
--                mb_intc_top.vhd
--                  irq_gen.vhd
--                    pulse_gen.vhd

-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      11/04/2002      changed when others in comb process to be same as
--                           idle
--  jam      11/04/2002      -- roll to rev c
------------------
-- Nitin Kabra 4/26/2006
-- Updated for fixing CR #227994 formal verification. FSM not recognized by XST
------------------
-- Nitin Kabra 5/22/2006
-- 1. Changed the process lebel GEN_NS_P to GEN_CS_P
-- 2. Combined the signal "output" generation in the process "GEN_CS_P"
--    generating "current_state".
-- 3. Removed the seperate process for generation of signal "output".
------------------
-- Nitin Kabra 5/23/2006
-- 1. FSM is changed to binary encoding from one-hot encoding.
-- 2. Signal "Output" generation is changed from "process" statement to
--   "when else" constract.
------------------
-- Nitin Kabra 5/23/2006
-- 1. FSM is changed to ennumerated type encoding from binary encoding.
-- 2. Changed the code for generation of signal "Output"
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_cmb" 
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

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity pulse_gen is
  generic
  (
    C_TRIG_ACTIVE  : std_logic := '1';
    C_ACK_ACTIVE   : std_logic := '1';
    C_OUT_ACTIVE   : std_logic := '1';
    C_ACK_ENDS_PLS : boolean   := false
  );
  port
  (
    Clk     : in  std_logic;
    Rst     : in  std_logic;
    Trigger : in  std_logic;
    Ack     : in  std_logic;
    Output  : out std_logic
  );

end pulse_gen;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of pulse_gen is

  type STATE_TYPE is (IDLE, GEN_PULSE, WAIT_ACK);

  signal   current_state : STATE_TYPE;


begin

--------------------------------------------------------------
--The sequential process below maintains the current_state
--------------------------------------------------------------
    GEN_CS_P : process (Clk)
        begin
            if(Clk'event and Clk='1') then
                if (Rst = '1') then
                    current_state <= IDLE;
                else
                    case current_state is
                        when IDLE      => if (Trigger = C_TRIG_ACTIVE) then
                                              current_state <= GEN_PULSE;
                                          else
                                              current_state <= IDLE;
                                          end if;
                        when GEN_PULSE => current_state <= WAIT_ACK;
		        
                        when WAIT_ACK  => if (Ack = C_ACK_ACTIVE) then
                                              current_state <= IDLE;
                                          else
                                              current_state <= WAIT_ACK;
                                          end if;
                    end case;
                end if;
            end if;
    end process GEN_CS_P;

--------------------------------------------------------------
--The statement below generates the state machine Output
--------------------------------------------------------------
    Output <= C_OUT_ACTIVE when (current_state = GEN_PULSE) or
                              ((current_state = WAIT_ACK) and C_ACK_ENDS_PLS)
                      else not C_OUT_ACTIVE;



end imp;
----------------------------------------------------------
-- End of file pulse_gen.vhd
----------------------------------------------------------