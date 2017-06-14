-------------------------------------------------------------------------------
-- $Id: irq_gen.vhd,v 1.6 2003/08/08 23:46:13 mccoyj Exp $
-------------------------------------------------------------------------------
-- irq_gen - entity / architecture pair
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
-- Filename:        irq_gen.vhd
-- Version:         v1.00c
-- Description:     generate a pulse (edge) or level output
--
-------------------------------------------------------------------------------
-- Structure:
--             intc.vhd
--               mb_intc_top.vhd
--                 irq_gen.vhd
--
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/10/2001  changed use common.all to use common.or_gate
--  jam      08/20/2001  changed to little endian to allow regs to be same
--                       size as number of int inputs and fixed ack logic to
--                       match spec
--  jam      11/05/2001  replaced le_reg with generate using fdr
--  jam      06/14/2002  added Clr_int port to handle problems when ier bit
--                       goes low after interrupt input arrives
--  jam      09/03/2002  added Xon generic
--  jam      11/04/2002      -- roll to rev c
--  jam      03/20/2003  added int_request_dly and replaced int_request with it
--                       for acks and Clr_int signal since registered_ints is
--                       delayed by a clock.  
--  jam      08/08/2003  changed way IRQ generated from int_request so that it
--                       is always inactive after reset regardless of polarity
-- 
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
library intc_core_v1_00_c;
library proc_common_v1_00_a;
library unisim;
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;
use proc_common_v1_00_a.or_gate;
use unisim.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity irq_gen is
  generic
  (
    C_INT_ACTIVE   : std_logic := '1';
    C_ACK_ACTIVE   : std_logic := '1';
    C_IRQ_ACTIVE   : std_logic := '1';
    C_IRQ_IS_LEVEL : boolean   := false;
    C_NUM_INTS     : positive  := 1
  );
  port
  (
    Clk         : in  std_logic;
    Rst         : in  std_logic;
    Masked_ints : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Irq_en      : in  std_logic;
    Int_ack     : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
    Clr_int     : out std_logic_vector(C_NUM_INTS - 1 downto 0);
    Irq         : out std_logic
  );

end irq_gen;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of irq_gen is

  constant NO_INTS : std_logic_vector(C_NUM_INTS - 1 downto 0) :=
                                                              (others => '0');

  signal int_request     : std_logic;
  signal int_request_dly : std_logic;
  signal or_acks         : std_logic_vector(0 to 0);
  signal or_ints         : std_logic_vector(0 to 0);
  signal acks            : std_logic_vector(C_NUM_INTS - 1 downto 0);
  signal registered_ints : std_logic_vector(C_NUM_INTS - 1 downto 0);

  component pulse_gen
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
  end component;

  component or_gate
    generic
    (
      C_OR_WIDTH   : natural range 1 to 32 := 17;
      C_BUS_WIDTH  : natural range 1 to 64 := 1;
      C_USE_LUT_OR : boolean               := TRUE
    );
    port
    (
      A : in  std_logic_vector(0 to C_OR_WIDTH * C_BUS_WIDTH - 1);
      Y : out std_logic_vector(0 to C_BUS_WIDTH - 1)
    );
  end component;

  component fdr
    port
    (
      Q : out std_logic;
      D : in std_logic;
      C : in std_logic;
      R : in std_logic
    );
  end component;

begin

  IRQ_PUSLE_GEN_I: pulse_gen
    generic map
    (
      C_TRIG_ACTIVE   => C_INT_ACTIVE,
      C_ACK_ACTIVE    => C_ACK_ACTIVE,
      C_OUT_ACTIVE    => C_IRQ_ACTIVE,
      C_ACK_ENDS_PLS  => C_IRQ_IS_LEVEL
    )
    port map
    (
      Clk     => Clk,
      Rst     => Rst,
      Trigger => or_ints(0),
      Ack     => or_acks(0),
      Output  => int_request
    );

  Irq <= int_request when Irq_en = '1' else not C_IRQ_ACTIVE;

  OR_INTS_I: or_gate
    generic map
    (
      C_OR_WIDTH   => C_NUM_INTS,
      C_BUS_WIDTH  => 1,
      C_USE_LUT_OR => TRUE
    )
    port map
    (
      A => Masked_ints,
      Y => or_ints
    );

  MASKED_INTS_REG_GEN:
  for i in Masked_ints'range
  generate
    MASKED_INTS_REG_BIT_I : fdr
      port map
      (
        Q => registered_ints(i),
        D => Masked_ints(i),
        C => Clk,
        R => Rst
      );
  end generate MASKED_INTS_REG_GEN;

  INT_REQUEST_DLY_I : FDR
    port map
    (
      Q => int_request_dly,   -- out STD_ULOGIC
      C => Clk,               -- in  STD_ULOGIC
      D => int_request,       -- in  STD_ULOGIC
      R => Rst                -- in  STD_ULOGIC
    );

  acks <= (others => '1') when (registered_ints = NO_INTS and
                                int_request_dly = C_IRQ_ACTIVE
                               ) else registered_ints and Int_ack;

  Clr_int <= (others => '1') when (registered_ints = NO_INTS and
                                   int_request_dly = C_IRQ_ACTIVE
                                  ) else Int_ack;

  OR_ACKS_I: or_gate
    generic map
    (
      C_OR_WIDTH   => C_NUM_INTS,
      C_BUS_WIDTH  => 1,
      C_USE_LUT_OR => TRUE
    )
    port map
    (
      A => acks,
      Y => or_acks
    );

end imp;

