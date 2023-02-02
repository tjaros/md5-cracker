library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_UART2WB is
    Port (
        CLOCK_50   : in  std_logic; -- Clock 50 MHz
        RST_BTN_N : in  std_logic; -- low active reset button
        -- UART INTERFACE
        UART_RXD  : in  std_logic;
        UART_TXD  : out std_logic
    );
end entity;

architecture RTL of TOP_UART2WB is

    signal rst_btn       : std_logic;
    signal reset         : std_logic;

    signal wb_cyc        : std_logic;
    signal wb_stb        : std_logic;
    signal wb_we         : std_logic;
    signal wb_addr       : std_logic_vector(15 downto 0);
    signal wb_dout       : std_logic_vector(31 downto 0);
    signal wb_stall      : std_logic;
    signal wb_ack        : std_logic;
    signal wb_din        : std_logic_vector(31 downto 0);

     -- That naming -_-
    signal cracker_we_sel     : std_logic;
    signal cracker_we_we      : std_logic;
    signal cracker_we         : std_logic;

begin

    rst_btn <= not RST_BTN_N;

    rst_sync_i : entity work.RST_SYNC
    port map (
        CLK        => CLOCK_50,
        ASYNC_RST  => rst_btn,
        SYNCED_RST => reset
    );

    uart2wbm_i : entity work.UART2WBM
    generic map (
        CLK_FREQ  => 50e6,
        BAUD_RATE => 115200
    )
    port map (
        CLK      => CLOCK_50,
        RST      => reset,
        -- UART INTERFACE
        UART_TXD => UART_TXD,
        UART_RXD => UART_RXD,
        -- WISHBONE MASTER INTERFACE
        WB_CYC   => wb_cyc,
        WB_STB   => wb_stb,
        WB_WE    => wb_we,
        WB_ADDR  => wb_addr,
        WB_DOUT  => wb_din,
        WB_STALL => wb_stall,
        WB_ACK   => wb_ack,
        WB_DIN   => wb_dout
    );


    cracker_we_sel <= '1' when wb_addr(7 downto 0) = X"FF" else '0';
    cracker_we_we  <= wb_stb and wb_we and md5_we_sel;

    din_p : process (CLOCK_50)
    begin
        if (rising_edge(CLOCK_50)) then
            case wb_addr(7 downto 0) is
                when X"FF" => -- set writestrobe
                    if (cracker_we_we = '1') then
                            if wb_din(0 downto 0) = "0" then
                               cracker_we <= '0';
                             else
                               cracker_we <= '1';
                             end if;
                          end if;
                when others =>
                    cracker_address    <= wb_addr(7 downto 0);
                    cracker_write_data <= wb_din;
            end case;
        end if;
    end process;

    wb_stall <= '0';

    wb_ack_reg_p : process (CLOCK_50)
    begin
        if (rising_edge(CLOCK_50)) then
            wb_ack <= wb_cyc and wb_stb;
        end if;
    end process;

    wb_dout_reg_p : process (CLOCK_50)
    begin
        if (rising_edge(CLOCK_50)) then
            case wb_addr(7 downto 0) is
                when X"FF" =>
                    wb_dout <= X"DEADCAFE"; -- sw must beforehand send address and write value, and turn it off afterwards
                when others =>
                    wb_dout <= cracker_read_data;
            end case;
        end if;
    end process;

end architecture;
