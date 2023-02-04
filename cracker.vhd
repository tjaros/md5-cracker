library IEEE;
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;


entity CRACKER is
  port (
    clk_i      : in  std_logic;         -- clock source
    rst        : in  std_logic;         -- reset
    we         : in  std_logic;         -- write enable
    addr       : in  std_logic_vector(7 downto 0);     -- address to write to or read from
    read_data  : out std_logic_vector(31 downto 0);    -- read data
    write_data : in  std_logic_vector(31 downto 0);     -- write data
	 leds       : out std_logic_vector( 7 downto 0)
  ); 
end CRACKER;

architecture CRACKER_BODY of CRACKER is
  -- Constant definitions

  constant ADDR_NAME0 : std_logic_vector(7 downto 0) := x"00";
  constant ADDR_NAME1 : std_logic_vector(7 downto 0) := x"01";

  constant NAME0 : std_logic_vector(31 downto 0) := x"6D643563";  -- "md5c"
  constant NAME1 : std_logic_vector(31 downto 0) := x"726B7220";  -- "rkr "


  constant ADDR_TARGET_DIGEST0 : std_logic_vector(7 downto 0) := x"10";
  constant ADDR_TARGET_DIGEST1 : std_logic_vector(7 downto 0) := x"11";
  constant ADDR_TARGET_DIGEST2 : std_logic_vector(7 downto 0) := x"12";
  constant ADDR_TARGET_DIGEST3 : std_logic_vector(7 downto 0) := x"13";

  signal target_digest: std_logic_vector(127 downto 0);

  constant ADDR_STATUS : std_logic_vector(7 downto 0) := x"0E";
  signal   done        : std_logic := '0';

  constant ADDR_INIT : std_logic_vector(7 downto 0) := x"0F";
  signal init      : std_logic := '0';


  -- Instantiate MD5_Test component, which is implementation of parralelized MD5
  -- cracking, it was designed by Maruthi Gillela while working on his diploma
  -- thesis at Masaryk university, Brno.
  -- The thesis is available at https://is.muni.cz/th/xa53n
  -- In case link does not work, the name of the thesis is:
  --
  -- Parallelization of brute force attack on MD5 hash algorithm in FPGA
  --

  component MD5_test is
    port (
      clk       : in  std_logic;
      configreg : in  std_logic_vector(31 downto 0);
      hashin1   : in  std_logic_vector(31 downto 0);
      hashin2   : in  std_logic_vector(31 downto 0);
      hashin3   : in  std_logic_vector(31 downto 0);
      hashin4   : in  std_logic_vector(31 downto 0);
      outreg    : out std_logic_vector(31 downto 0);
      passwdH   : out std_logic_vector(31 downto 0);
      passwdL   : out std_logic_vector(31 downto 0)
		);
  end component MD5_test;

  -- This is probably a bad idea to have the circuit stay resetting, until we enable
  signal md5t_config  : std_logic_vector(31 downto 0);
  signal md5t_outreg  : std_logic_vector(31 downto 0);
  signal md5t_clk   : std_logic;

  constant ADDR_PWD0  : std_logic_vector(7 downto 0) := x"20";
  constant ADDR_PWD1  : std_logic_vector(7 downto 0) := x"21";

  signal pwd          : std_logic_vector(63 downto 0);
  signal pwdH         : std_logic_vector(31 downto 0);
  signal pwdL         : std_logic_vector(31 downto 0);
  
  begin
    leds(0) <= we;
	 leds(1) <= init;
	 leds(2) <= rst;
	 leds(3) <= md5t_config(0);
	 leds(7) <= done;


    md5_test_inst: component MD5_test
      port map (
        clk       => md5t_clk ,
        configreg => md5t_config,
        hashin1   => target_digest( 31 downto  0),
        hashin2   => target_digest( 63 downto 32),
        hashin3   => target_digest( 95 downto 64),
        hashin4   => target_digest(127 downto 96),
        outreg    => md5t_outreg,
        passwdH   => pwdH,
        passwdL   => pwdL);

	 md5t_config <= x"00000001" when rst = '0' else x"00000000";
	 md5t_clk    <= clk_i when init = '1' else '0';

    -- write process
    reg_write_i: process(clk_i, rst)
    begin
      if rising_edge(clk_i) then
        if rst = '1' then
		    init <= '0';
		    done <= '0';
          target_digest <= (127 downto 0 => '0');
        else
		    if md5t_outreg(0) = '1' then
			   done <= '1';
				init <= '0';
				pwd(63 downto 32) <= pwdH;
				pwd(31 downto  0) <= pwdL;
			 end if;
			 
			 if we = '1' then
				case addr is
				  when ADDR_INIT =>
					 init <= '1';
				  when ADDR_TARGET_DIGEST0 =>
                target_digest(127 downto 96) <= write_data;
              when ADDR_TARGET_DIGEST1 =>
                target_digest(95  downto 64) <= write_data;
              when ADDR_TARGET_DIGEST2 =>
                target_digest(63  downto 32) <= write_data;
              when ADDR_TARGET_DIGEST3 =>
                target_digest(31  downto 0)  <= write_data;
				  when others => null;
				end case;
			 end if; -- we = '1'
		  end if; -- rst = '0'
      end if; -- rising_edge
    end process reg_write_i;


    -- read process
    reg_read_o: process(clk_i)
      begin
        if rising_edge(clk_i) then
          case addr is
            when ADDR_NAME0 =>
              read_data <= NAME0;
            when ADDR_NAME1 =>
              read_data <= NAME1;
            when ADDR_STATUS =>
              read_data <= (31 downto 1 => '0') & (0 downto 0 => done);
            when ADDR_PWD0 =>
              read_data <= pwd(63 downto 32);
				when ADDR_PWD1 =>
				  read_data <= pwd(31 downto 0);
				when ADDR_TARGET_DIGEST0 =>
				  read_data <= target_digest(127 downto 96);
            when ADDR_TARGET_DIGEST1 =>
              read_data <= target_digest(95 downto 64);
            when ADDR_TARGET_DIGEST2 =>
              read_data <= target_digest(63 downto 32);
            when ADDR_TARGET_DIGEST3 =>
              read_data <= target_digest(31 downto 0);
				when others =>
				  read_data <= x"deadbeef";
          end case;
        end if;
      end process;
  end architecture;
