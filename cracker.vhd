library IEEE
use IEEE.STD_LOGIC_1164.All;
use IEEE.NUMERIC_STD.all;


entity CRACKER is
  port (
    clk_i      : in  std_logic;         -- clock source
    rst        : in  std_logic;         -- reset
    we         : in  std_logic;         -- write enable
    addr       : in  std_ulogic_vector(7 downto 0);     -- address to write to or read from
    read_data  : out std_ulogic_vector(31 downto 0);    -- read data
    write_data : out std_ulogic_vector(31 downto 0););  -- write data

end entity CRACKER;

architecture CRACKER_BODY of CRACKER is
  -- Constant definitions

  constant ADDR_NAME0 : std_ulogic_vector(7 downto 0) := x"0000";
  constant ADDR_NAME1 : std_ulogic_vector(7 downto 0) := x"0001";

  constant NAME0 : std_ulogic_vector(31 downto 0) := x"6D643563";  -- "md5c"
  constant NAME1 : std_ulogic_vector(31 downto 0) := x"726B7220";  -- "rkr "


  constant ADDR_TARGET_DIGEST0 : unsigned(7 downto 0) := x"10";
  constant ADDR_TARGET_DIGEST3 : unsigned(7 downto 0) := x"13";

  signal target_digest: std_ulogic_vector(127 downto 0);

  constant ADDR_STATUS : unsigned(7 downto 0) := x"aa";
  signal   done        : std_logic;

  constant ADDR_INIT : unsigned(7 downto 0) := x"ee";
  constant crack_en  : std_logic;



  begin

    -- write process
    reg_write_i: process(clk_i, rst)
      variable addr_u : unsigned(7 downto 0);

      begin
        addr_u := unsigned(addr);

        if rising_edge(clk_i) then
          if rst = '0' then
            crack_en <= '0';
            target_digest <= (127 downto 0 => '0');

          elsif we = '1' then
              if addr_u = ADDR_INIT then
                crack_en <= '1' when write_data(0 downto 0) = "1" else '0';

              elsif (addr_u <= ADDR_TARGET_DIGEST3) and (addr_u >= ADDR_TARGET_DIGEST0) then
                case (addr_u - ADDR_TARGET_DIGEST0) is
                  when x"00" =>
                    target_digest(127 downto 96) <= write_data;
                  when x"01" =>
                    target_digest(95  downto 64) <= write_data;
                  when x"02" =>
                    target_digest(63  downto 32) <= write_data;
                  when x"03" =>
                    target_digest(31  downto 0)  <= write_data;
                  when others =>
                    null;
                end case;
          end;
        end if;
     end process reg_write_i;


    -- read process
    reg_read_o: process(clk_i)
      variable addr_u : unsigned(7 downto 0);

      begin
        addr_u := unsigned(addr);

        if rising_edge(clk_i) then
          case addr is
            when ADDR_NAME0 =>
              read_data <= NAME0;
            when ADDR_NAME1 =>
              read_data <= NAME1;
            when ADDR_STATUS =>
              read_data <= (31 downto 1 => '0') & (0 downto 0 => done);

            when others =>
              if (addr_u <= ADDR_TARGET_DIGEST3) and (addr_u >= ADDR_TARGET_DIGEST0) then
                case (addr_u - ADDR_TARGET_DIGEST0) is
                  when x"00" =>
                    read_data <= target_digest(127 downto 96);
                  when x"01" =>
                    read_data <= target_digest(95 downto 64);
                  when x"02" =>
                    read_data <= target_digest(63 downto 32);
                  when x"03" =>
                    read_data <= target_digest(31 downto 0);
                  when others =>
                    read_data <= x"deadbeef"; -- Hopefully no such coincidence
                                              -- happens that often
                end case;
              end if;
          end case;
        end if;
      end process;
  end architecture;
