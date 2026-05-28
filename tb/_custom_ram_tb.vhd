library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity custom_ram_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant data_width : natural := 8;
    constant adr_size : natural := 4;
    constant chip_data_width : natural := 8;
    constant chip_adr_size : natural := 4;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;

    signal a_en : std_logic;
    signal a_we : std_logic;
    signal a_adr : std_logic_vector(adr_size-1 downto 0);
    signal a_di : std_logic_vector(data_width-1 downto 0);

    signal b_en : std_logic;
    signal b_we : std_logic;
    signal b_adr : std_logic_vector(adr_size-1 downto 0);
    signal b_di : std_logic_vector(data_width-1 downto 0);

    -- Outputs
    signal a_do : std_logic_vector(data_width-1 downto 0);
    signal b_do : std_logic_vector(data_width-1 downto 0);

end entity;

architecture rtl of custom_ram_tb is

begin

    uut: entity work.custom_ram
        generic map(
            data_width => data_width,
            adr_size => adr_size,
            chip_data_width => chip_data_width,
            chip_adr_size => chip_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            a_en => a_en,
            a_we => a_we,
            a_adr => a_adr,
            a_di => a_di,
            a_do => a_do,
            b_en => b_en,
            b_we => b_we,
            b_adr => b_adr,
            b_di => b_di,
            b_do => b_do
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        a_adr <= (others => '0');
        b_adr <= (others => '0');
        rst <= '1';
        wait for clk_period;
        assert a_do = "00000000";
        assert b_do = "00000000";
        rst <= '0';

        b_en <= '0';
        a_en <= '1';
        a_we <= '1';
        a_adr <= "0001";
        a_di <= "10100101";
        wait for clk_period;
        a_we <= '0';
        b_en <= '1';
        b_adr <= "0001";
        wait for clk_period;
        assert a_do = "10100101";
        assert b_do = "10100101";
        a_we <= '1';
        a_di <= "11110000";
        b_we <= '1';
        b_adr <= "1001";
        b_di <= "00001111";
        wait for clk_period;
        assert a_do = "11110000";
        a_we <= '0';
        b_we <= '0';
        wait for clk_period;
        assert a_do = "11110000";
        assert b_do = "00001111";

        report "Done";
        wait;
    end process;

end architecture;