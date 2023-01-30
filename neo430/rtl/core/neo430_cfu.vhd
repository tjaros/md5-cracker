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
  
  -- CF registers
  signal alg_chosen:     std_logic;
  signal alg_clk:        std_logic;
  
  -- Flags
  signal reset_flag:     std_logic;
  signal cs_flag:        std_logic;
  signal we_flag:        std_logic;

  
  -- MD5 implementation registers
  signal md5_chosen:     std_logic;
  signal md5_reset_n:    std_logic;
  signal md5_cs:         std_logic;
  signal md5_we:         std_logic;
  signal md5_address:    std_ulogic_vector(7 downto 0);
  signal md5_write_data: std_ulogic_vector(31 downto 0);
  signal md5_read_data:  std_ulogic_vector(31 downto 0);
  
  component MD5 is
   port (
      clk:        in  std_logic;
		reset_n:    in  std_logic;
		cs:         in  std_logic; 
		we:         in  std_logic;
		address:    in  std_ulogic_vector(7 downto 0);
      write_data: in  std_ulogic_vector(31 downto 0);
		read_data:  out std_ulogic_vector(31 downto 0)
   );
  end component;

begin

  -- Access Control -----------------------------------------------------------
  -- -----------------------------------------------------------------------------
  -- These assignments are required to check if this unit is accessed at all.
  -- Do NOT modify this for your custom application (unless you really know what you are doing)!
  acc_en <= '1' when (addr_i(hi_abb_c downto lo_abb_c) = cfu_base_c(hi_abb_c downto lo_abb_c)) else '0';
  addr   <= cfu_base_c(15 downto lo_abb_c) & addr_i(lo_abb_c-1 downto 1) & '0'; -- word aligned
  wren   <= acc_en and wren_i;
  rden   <= acc_en and rden_i;


  -- Clock System -------------------------------------------------------------
  -- -----------------------------------------------------------------------------
  -- The top unit implements a clock generator providing 8 "derived clocks"
  -- Actually, these signals must not be used as direct clock signals, but as clock enable signals.
  -- If wou want to drive a system at MAIN_CLK/8 use the following construct:

  -- if rising_edge(clk_i) then -- Always use the main clock for all clock processes!
  --   if (clkgen_i(clk_div8_c) = '1') then -- the div8 "clock" is actually a clock enable
  --     ...
  --   end if;
  -- end if;

  -- The following clock divider rates are available:
  -- clkgen_i(clk_div2_c)    -> MAIN_CLK/2
  -- clkgen_i(clk_div4_c)    -> MAIN_CLK/4
  -- clkgen_i(clk_div8_c)    -> MAIN_CLK/8
  -- clkgen_i(clk_div64_c)   -> MAIN_CLK/64
  -- clkgen_i(clk_div128_c)  -> MAIN_CLK/128
  -- clkgen_i(clk_div1024_c) -> MAIN_CLK/1024
  -- clkgen_i(clk_div2048_c) -> MAIN_CLK/2048
  -- clkgen_i(clk_div4096_c) -> MAIN_CLK/4096

  -- this signal enabled the generator driving the clkgen_i
  -- set this signal to '0' when you do not need the clkgen_i signal or when your CFU is disabled
  -- to reduce dynamic power consumption
  -- clkgen_en_o <= '0';
  clkgen_en_o <= '0';
 
  -- MD5 Instance
  
  MD5_Hash: MD5 port map (
      clk        => alg_clk,
		reset_n    => md5_reset_n,
		cs         => md5_cs,
		we         => md5_we,
		address    => md5_address,
      write_data => md5_write_data,
		read_data  => md5_read_data
  );
  
  
  -- Check if CFU_REG0 an algorithm is specified
  alg_chosen <= '1' when (CFU_ctrl_reg(15 downto 15) = "1") and (CFU_ctrl_reg(7 downto 0) /= x"00") else '0';
  
  -- Start generating clock signal if the alg was chosen
--gen_alg_clk: process(clk_i)
--begin
--  if rising_edge(clk_i) then
--	   if (clkgen_i(clk_div2_c) = '1') then
--	     alg_clk <= '1';
--	   else 
--	     alg_clk <= '0';
--		end if;
--	 end if;
--end process gen_alg_clk;
alg_clk <= clk_i;
  
  -- setup flags based on registers
  flag_setup: process(clk_i)
  begin
    if rising_edge(clk_i) then
	   if cfu_ctrl_reg(14 downto 14) = "1" and reset_flag = '0' then
		  -- Active low reset and set reset flag to prevent continuous resetting
		  md5_reset_n <= '0';
		  reset_flag  <= '1';
		else
		  md5_reset_n <= '1';
		end if;
		
		-- Flag in register was annulled, so we can unmask reset
		if cfu_ctrl_reg(14 downto 14) = "0" then
		  reset_flag <= '0';
		end if;
		
		if cfu_ctrl_reg(13 downto 13) = "1" and cs_flag = '0' then
		  md5_cs <= '1';
		end if;
		
		if cfu_ctrl_reg(13 downto 13) = "0" then
		  md5_cs  <= '0';
		  cs_flag <= '0';
		end if;
		
		if cfu_ctrl_reg(12 downto 12) = "1" and we_flag = '0' then
		  md5_we  <= '1';
		  we_flag <= '1';
		end if;
		
		if cfu_ctrl_reg(12 downto 12) = "0" then
		  md5_we  <= '0';
		  we_flag <= '0';
		end if;
	 end if;
  end process;
  
 -- Map memory
 md5_address <= user_reg1(7 downto 0);
 -- Registers 2, 3 are mapped to md5 input
 md5_write_data(31 downto 16) <= user_reg2;
 md5_write_data(15 downto 0)  <= user_reg3;
 -- MD5 output is written into registers 4, 5
 user_reg4 <= md5_read_data(31 downto 16);
 user_reg5 <= md5_read_data(15 downto 0);
  
  

  -- Write access -------------------------------------------------------------
  -- -----------------------------------------------------------------------------
  -- Here we are writing to the interface registers of the module. This unit can only be accessed
  -- in full 16-bit word mode!
  -- Please note, that all register of every unit are cleared during the processor boot sequence.
  -- Make cfu_reg0_addr_c the CFU's control register. This register is cleared first during booting.
  -- If the control register is cleared no actions should be taken when writing to other CFU registers.
  wr_access: process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- write access to user registers --
      if (wren = '1') then -- valid write access
          if (addr = cfu_reg0_addr_c) then
            cfu_ctrl_reg <= data_i;
          end if;
          if (addr = cfu_reg1_addr_c) then
            user_reg1 <= data_i;
          end if;
          if (addr = cfu_reg2_addr_c) then
		      user_reg2 <= data_i;
          end if;
          if (addr = cfu_reg3_addr_c) then 
		      user_reg3 <= data_i;
          end if;
			 -- Upper 4 registers cannot be written in by cfu users,
			 -- to prevent multiple writers 
          --if (addr = cfu_reg4_addr_c) then
          --  user_reg4 <= data_i;
          --end if;
          --if (addr = cfu_reg5_addr_c) then
          --  user_reg5 <= data_i;
          --end if;
          --if (addr = cfu_reg6_addr_c) then
          --  user_reg6 <= data_i;
          --end if;
          --if (addr = cfu_reg7_addr_c) then
          --  user_reg7 <= data_i;
          --end if;
      end if;
    end if;
  end process wr_access;

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
