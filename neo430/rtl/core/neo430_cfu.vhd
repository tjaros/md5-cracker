-- #################################################################################################
-- #  << NEO430 - Custom Functions Unit >>                                                         #
-- # ********************************************************************************************* #
-- # This unit is a template for implementing custom functions, which are directly memory-mapped   #
-- # into the CPU's IO address space. The address space of this unit is 16 bytes large. This unit  #
-- # can only be accessed using full word (16-bit) accesses.                                       #
-- # In the original state, this unit only provides 8 16-bit register, that do not perform any     #
-- # kind of data manipulation.                                                                    #
-- # Exemplary applications: Cryptography, complex arithmetic, rocket science, ...                 #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2020, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEO430 Processor - https://github.com/stnolting/neo430                                    #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neo430;
use neo430.neo430_package.all;

entity neo430_cfu is
  port (
    -- host access --
    clk_i       : in  std_ulogic; -- global clock line
    rden_i      : in  std_ulogic; -- read enable
    wren_i      : in  std_ulogic; -- write enable
    addr_i      : in  std_ulogic_vector(15 downto 0); -- address
    data_i      : in  std_ulogic_vector(15 downto 0); -- data in
    data_o      : out std_ulogic_vector(15 downto 0); -- data out
    -- clock generator --
    clkgen_en_o : out std_ulogic; -- enable clock generator
    clkgen_i    : in  std_ulogic_vector(07 downto 0)
    -- custom IOs --
--  ...
  );
end neo430_cfu;

architecture neo430_cfu_rtl of neo430_cfu is

  -- IO space: module base address --
  constant hi_abb_c : natural := index_size_f(io_size_c)-1; -- high address boundary bit
  constant lo_abb_c : natural := index_size_f(cfu_size_c); -- low address boundary bit

  -- access control --
  signal acc_en : std_ulogic; -- module access enable
  signal addr   : std_ulogic_vector(15 downto 0); -- access address
  signal wren   : std_ulogic; -- full word write enable
  signal rden   : std_ulogic; -- read enable

  -- accessible regs (8x16-bit) --
  signal cfu_ctrl_reg : std_ulogic_vector(15 downto 0);
  signal user_reg1    : std_ulogic_vector(15 downto 0);
  signal user_reg2    : std_ulogic_vector(15 downto 0);
  signal user_reg3    : std_ulogic_vector(15 downto 0);
  signal user_reg4    : std_ulogic_vector(15 downto 0);
  signal user_reg5    : std_ulogic_vector(15 downto 0);
  signal user_reg6    : std_ulogic_vector(15 downto 0);
  signal user_reg7    : std_ulogic_vector(15 downto 0);
  


  -- >>> UNIT HARDWARE RESET <<< --
  -- The IO devices DO NOT feature a dedicated reset signal, so make sure your CFU does not require a defined initial state.
  -- If you really require a defined initial state, implement a software reset by implementing a control register with an
  -- enable bit, which resets all internal states when cleared.


  -- Read access --------------------------------------------------------------
  -- -----------------------------------------------------------------------------
  -- This is the read access process. Data must be asserted synchronously to the output data bus
  -- and thus, with exactly 1 cycle delay. The units always output a full 16-bit word, no matter if we want to
  -- read 8- or 16-bit. For actual 8-bit read accesses the corresponding byte is selected in the
  -- hardware of the CPU core.
  rd_access: process(clk_i)
  begin
    if rising_edge(clk_i) then
      data_o <= (others => '0'); -- this is crucial for the final OR-ing of all IO device's outputs
      if (rden = '1') then -- valid read access
        -- use IFs instead of a CASE to prevent some EDA tools from complaining (GHDL)
        if (addr = cfu_reg0_addr_c) then
          data_o <= cfu_ctrl_reg;
        elsif (addr = cfu_reg1_addr_c) then
          data_o <= user_reg1;
        elsif (addr = cfu_reg2_addr_c) then
          data_o <= user_reg2;
        elsif (addr = cfu_reg3_addr_c) then
          data_o <= user_reg3;
        elsif (addr = cfu_reg4_addr_c) then
          data_o <= user_reg4;
        elsif (addr = cfu_reg5_addr_c) then
          data_o <= user_reg5;
        elsif (addr = cfu_reg6_addr_c) then
          data_o <= user_reg6;
        elsif (addr = cfu_reg7_addr_c) then
          data_o <= user_reg7;
        else
          data_o <= (others => '0');
        end if;
      end if;
    end if;
  end process rd_access;


end neo430_cfu_rtl;
