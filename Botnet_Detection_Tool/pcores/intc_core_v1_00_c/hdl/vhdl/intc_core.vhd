-------------------------------------------------------------------------------
-- $Id: intc_core.vhd,v 1.11 2006/06/02 04:18:50 nitink Exp $
-------------------------------------------------------------------------------
-- intc_core - entity / architecture pair
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
-- Filename:        intc_core.vhd
-- Version:         v1.00c
-- Description:     intc without a bus interface
--
-------------------------------------------------------------------------------
-- Structure:
--                  <bus type>_intc.vhd
--                    intc_core.vhd  (top level)
--
-------------------------------------------------------------------------------
-- @BEGIN_CHANGELOG EDK_Im_SP1
--
--  Updated pulse_gen.vhd to fix the CR #227994 (unrecognized FSM by XST)
--
-- @END_CHANGELOG
-------------------------------------------------------------------------------
-- Author:      jam
-- History:
--  jam      08/01/2001      -- First version
--  jam      08/06/2001  added generic C_BASE_NUM_BITS for opb_intfc
--  jam      08/10/2001  changed to target_family_type in common
--  jam      08/20/2001  changed to little endian everywhere except in regs
--                       and opb_intfc
--  jam      10/09/2001  change C_NUM_INTR_INPUTS lower range value to 1 and
--                       add get_reg_width function to determine min width of
--                       regs.  added constant REG_WIDTH that is set based on
--                       C_NUM_INTR_INPUTS and used it in generic map for regs. 
--                       added a signal intr_inputs that is the same width as
--                       the regs and two generate statements that assign values
--                       to intr_inputs based on the size of C_NUM_INTR_INPUTS
--  jam      12/04/2001  changed to C_FAMILY
--  jam      06/14/2002  added clr_int signal between int_det and irq_gen to
--                       handle when ier bit is cleared after interrupt input
--                       arrives (caused irq to stay high)
--  jam      09/03/2002  added ONE_KIND_OF_INTR and ONE_KIND_OF_LVL constants
--                       and one_sw_int signal to handle problem with one int
--                       input.  Change the "extra" input to level and make it
--                       active high and then make sure the sw input is always
--                       zero (hw is already zero).  Use generates to pass the
--                       constants and signal when only one int input specified
--  jam      11/04/2002      -- roll to rev c
--  jam      07/15/2003  fixed problem with active low level interrupt inputs
--                       and sw interrupts when low level specified and added
--                       code to ensure artificial interrupt is never enabled
--  lss      01/05/2004  Changed int_det to use int_ack rather than clr_int to 
--                       avoid int_status losing interrupts (Change is to intc_core)
--                       Changed regs to use int_ack as reset to ISR.
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
use ieee.std_logic_1164.all;
use intc_core_v1_00_c.intc_pkg.all;
use intc_core_v1_00_c.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------

entity intc_core is
  generic
  (
    C_FAMILY : string  := "virtex2";
    C_Y      : integer := 0;
    C_X      : integer := 0;
    C_U_SET  : string  := "intc";

    C_DWIDTH : positive := WORD_SIZE;

    C_NUM_INTR_INPUTS : positive range 1 to WORD_SIZE := 2;

    C_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0) := "11111111111111111111111111111111";
    C_KIND_OF_EDGE : std_logic_vector(WORD_SIZE - 1 downto 0) := "11111111111111111111111111111111";
    C_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0) := "11111111111111111111111111111111";

    C_HAS_IPR : boolean := false;
    C_HAS_SIE : boolean := false;
    C_HAS_CIE : boolean := false;
    C_HAS_IVR : boolean := false;

    C_IRQ_IS_LEVEL : boolean   := false;
    C_IRQ_ACTIVE   : std_logic := '1'
  );
  port
  (
    Clk : in std_logic;
    Rst : in std_logic;

    Intr : in  std_logic_vector(C_NUM_INTR_INPUTS - 1 downto 0);
    Irq  : out std_logic;

    Reg_addr : in  reg_sel_type;
    Valid_rd : in  std_logic;
    Valid_wr : in  std_logic;
    Wr_data  : in  std_logic_vector(C_DWIDTH - 1 downto 0);
    Rd_data  : out std_logic_vector(C_DWIDTH - 1 downto 0)
  );

end intc_core;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------

architecture imp of intc_core is

  function get_reg_width(w : positive) return positive is
  begin
    if w > 1 then return w;
    else return 2;
    end if;
  end get_reg_width;

  constant REG_WIDTH : positive range 2 to 64 :=
                                          get_reg_width(C_NUM_INTR_INPUTS);

  constant ONE_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                       C_KIND_OF_INTR(WORD_SIZE - 1 downto 2) &
                                       '0' &
                                       C_KIND_OF_INTR(0);

  constant ONE_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                       C_KIND_OF_LVL(WORD_SIZE - 1 downto 2) &
                                       '1' &
                                       C_KIND_OF_LVL(0);

  signal intr_inputs    : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal enabled_ints   : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal global_enable  : std_logic;
  signal hw_int_enable  : std_logic;
  signal int_ack        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal clr_int        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal int_enables    : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal one_int_en     : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal int_status     : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal ints_pending   : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal sw_ints        : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal one_sw_int     : std_logic_vector(REG_WIDTH - 1 downto 0);
  signal reg_ints       : std_logic_vector(REG_WIDTH - 1 downto 0);

  component int_det
    generic
    (
      C_FAMILY       : string   := "virtex2";
      C_Y            : integer  := 0;
      C_X            : integer  := 0;
      C_U_SET        : string   := "intc";
      C_NUM_INTS     : positive := 2;
      C_KIND_OF_INTR : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                           "11111111111111111111111111111111";
      C_KIND_OF_EDGE : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                           "11111111111111111111111111111111";
      C_KIND_OF_LVL  : std_logic_vector(WORD_SIZE - 1 downto 0) :=
                                           "11111111111111111111111111111111"
    );
    port
    (
      Clk           : in  std_logic;
      Rst           : in  std_logic;
      Hw_int_enable : in  std_logic;
      Int           : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Intr_ack      : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Sw_ints       : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Int_enables   : in  std_logic_vector(C_NUM_INTS - 1 downto 0);
      Enabled_ints  : out std_logic_vector(C_NUM_INTS - 1 downto 0);
      Ints_pending  : out std_logic_vector(C_NUM_INTS - 1 downto 0);
      Int_status    : out std_logic_vector(C_NUM_INTS - 1 downto 0)
    );
  end component;
  
  component irq_gen
    generic
    (
      C_INT_ACTIVE   : std_logic := '1';
      C_ACK_ACTIVE   : std_logic := '1';
      C_IRQ_ACTIVE   : std_logic := '1';
      C_IRQ_IS_LEVEL : boolean   := false;
      C_NUM_INTS     : positive  := 2
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
  end component;

  component regs
    generic
    (
      C_FAMILY     : string   := "virtex2";
      C_Y          : integer  := 0;
      C_X          : integer  := 0;
      C_U_SET      : string   := "intc";
      C_DWIDTH     : positive := WORD_SIZE;
      C_HAS_IPR    : boolean  := false;
      C_HAS_SIE    : boolean  := false;
      C_HAS_CIE    : boolean  := false;
      C_HAS_IVR    : boolean  := false;
      C_RWIDTH     : positive range 2 to 64 := 2
    );
    port
    (
      Clk           : in  std_logic;
      Rst           : in  std_logic;
      Int_status    : in  std_logic_vector(C_RWIDTH - 1 downto 0);
      Ints_pending  : in  std_logic_vector(C_RWIDTH - 1 downto 0);
      Reg_sel       : in  reg_sel_type;
      Valid_rd      : in  std_logic;
      Valid_wr      : in  std_logic;
      Wr_data       : in  std_logic_vector(C_DWIDTH - 1 downto 0);
      Global_enable : out std_logic;
      Hw_int_enable : out std_logic;
      Int_ack       : out std_logic_vector(C_RWIDTH - 1 downto 0);
      Int_enables   : out std_logic_vector(C_RWIDTH - 1 downto 0);
      Rd_data       : out std_logic_vector(C_DWIDTH - 1 downto 0);
      Sw_ints       : out std_logic_vector(C_RWIDTH - 1 downto 0)
    );
  end component;
  
-------------------------------------------------------------------------------
-- End of declarations
-------------------------------------------------------------------------------

begin

    -- minimum register width is 2, so if C_NUM_INTR_INPUTS is 1 then need to
    -- prepend a 0 to the interrupt input to make it 2 bits wide
  ONE_INTR_GEN:
  if C_NUM_INTR_INPUTS = 1
  generate
    intr_inputs <= '0' & Intr(0);
  end generate ONE_INTR_GEN;

    -- if C_NUM_INTR_INPUTS is greater than one then just connect the Int
    -- inputs up directly
  INTR_BUS_GEN:
  if C_NUM_INTR_INPUTS > 1
  generate
    intr_inputs <= Intr;
  end generate INTR_BUS_GEN;

  SW_INTS_I:
  process(reg_ints)
  begin
    for i in reg_ints'range
    loop
      if C_KIND_OF_INTR(i) = '1' then
        sw_ints(i) <= reg_ints(i) xnor C_KIND_OF_EDGE(i);
      else
        sw_ints(i) <= reg_ints(i) xnor C_KIND_OF_LVL(i);
      end if;
    end loop;
  end process SW_INTS_I;

   -- eliminate the software interrupt on the extra bit when only one interrupt
   -- input is specified
  ONE_SW_INT_I:
  process(sw_ints)
  begin
    for i in sw_ints'range
    loop
      if i = 1 then one_sw_int(i) <= '0';
      else one_sw_int(i) <= sw_ints(i);
      end if;
    end loop;
  end process ONE_SW_INT_I;

   -- don't allow the artificial interrupt input to be enabled when there is
   -- only one input
  ONE_INT_EN_I:
  process(int_enables)
  begin
    for i in int_enables'range
    loop
      if i = 1 then one_int_en(i) <= '0';
      else one_int_en(i) <= int_enables(i);
      end if;
    end loop;
  end process ONE_INT_EN_I;
 
  IRQ_GEN_I: irq_gen
    generic map
    (
      C_INT_ACTIVE   => '1',
      C_ACK_ACTIVE   => '1',
      C_IRQ_ACTIVE   => C_IRQ_ACTIVE,
      C_IRQ_IS_LEVEL => C_IRQ_IS_LEVEL,
      C_NUM_INTS     => REG_WIDTH
    )
    port map
    (
      Clk         => Clk,
      Rst         => Rst,
      Masked_ints => enabled_ints,
      Irq_en      => global_enable,
      Int_ack     => int_ack,
      Clr_int     => clr_int,
      Irq         => Irq
    );

  ONE_INTR_DET_GEN:
  if C_NUM_INTR_INPUTS = 1
  generate
    INTR_DET_I: int_det
      generic map
      (
        C_FAMILY       => C_FAMILY,
        C_Y            => C_Y,
        C_X            => C_X,
        C_U_SET        => C_U_SET,
        C_NUM_INTS     => REG_WIDTH,
        C_KIND_OF_INTR => ONE_KIND_OF_INTR,
        C_KIND_OF_EDGE => C_KIND_OF_EDGE,
        C_KIND_OF_LVL  => ONE_KIND_OF_LVL
      )
      port map
      (
        Clk           => Clk,
        Rst           => Rst,
        Hw_int_enable => hw_int_enable,
        Int           => intr_inputs,
--        Intr_ack      => clr_int,  LSS 1/05/04
        Intr_ack      => int_ack, -- LSS 1/05/04
        Sw_ints       => one_sw_int,
        Int_enables   => one_int_en,
        Enabled_ints  => enabled_ints,
        Ints_pending  => ints_pending,
        Int_status    => int_status
      );
  end generate ONE_INTR_DET_GEN;

  MANY_INTR_DET_GEN:
  if C_NUM_INTR_INPUTS > 1
  generate
    INTR_DET_I: int_det
      generic map
      (
        C_FAMILY       => C_FAMILY,
        C_Y            => C_Y,
        C_X            => C_X,
        C_U_SET        => C_U_SET,
        C_NUM_INTS     => REG_WIDTH,
        C_KIND_OF_INTR => C_KIND_OF_INTR,
        C_KIND_OF_EDGE => C_KIND_OF_EDGE,
        C_KIND_OF_LVL  => C_KIND_OF_LVL
      )
      port map
      (
        Clk           => Clk,
        Rst           => Rst,
        Hw_int_enable => hw_int_enable,
        Int           => intr_inputs,
--        Intr_ack      => clr_int,
        Intr_ack      => int_ack, -- LSS 1/05/04 
        Sw_ints       => sw_ints,
        Int_enables   => int_enables,
        Enabled_ints  => enabled_ints,
        Ints_pending  => ints_pending,
        Int_status    => int_status
      );
  end generate MANY_INTR_DET_GEN;

  REGS_I: regs
    generic map
    (
      C_FAMILY     => C_FAMILY,
      C_Y          => C_Y,
      C_X          => C_X,
      C_U_SET      => C_U_SET,
      C_DWIDTH     => C_DWIDTH,
      C_HAS_IPR    => C_HAS_IPR,
      C_HAS_SIE    => C_HAS_SIE,
      C_HAS_CIE    => C_HAS_CIE,
      C_HAS_IVR    => C_HAS_IVR,
      C_RWIDTH     => REG_WIDTH
    )
    port map
    (
      Clk           => Clk,
      Rst           => Rst,
      Int_status    => int_status,
      Ints_pending  => ints_pending,
      Reg_sel       => Reg_addr,
      Valid_rd      => Valid_rd,
      Valid_wr      => Valid_wr,
      Wr_data       => Wr_data,
      Global_enable => global_enable,
      Hw_int_enable => hw_int_enable,
      Int_ack       => int_ack,
      Int_enables   => int_enables,
      Rd_data       => Rd_data,
      Sw_ints       => reg_ints
    );

end imp;

