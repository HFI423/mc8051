library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ram is

    generic (
        adr_size : natural;
        data_size : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        we : in std_logic;
        adr : in std_logic_vector(adr_size-1 downto 0);
        di : in std_logic_vector(data_size-1 downto 0);
        do : out std_logic_vector(data_size-1 downto 0)
    );

end entity;

architecture rtl of ram is

    constant rows : natural := 2**adr_size;
    type ram_type is array (0 to rows-1) of std_logic_vector(data_size-1 downto 0);
    signal memory : ram_type;

begin

    process(clk)
        variable adr_int : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                do <= (others => '0');
            else
                adr_int := conv_integer(adr);
                if we = '1' then
                    memory(adr_int) <= di;
                end if;
                do <= memory(adr_int);
            end if;
        end if;
    end process;

end architecture;