library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity custom_ram_part is

  generic (
    data_width : natural := 36;
    adr_size : natural := 9
  );

  port (
    clk : in std_logic;
    rst : in std_logic;

    a_en : in std_logic;
    a_we : in std_logic;
    a_adr : in std_logic_vector(adr_size-1 downto 0);
    a_di : in std_logic_vector(data_width-1 downto 0);
    a_do : out std_logic_vector(data_width-1 downto 0);

    b_en : in std_logic;
    b_we : in std_logic;
    b_adr : in std_logic_vector(adr_size-1 downto 0);
    b_di : in std_logic_vector(data_width-1 downto 0);
    b_do : out std_logic_vector(data_width-1 downto 0)
  );

end custom_ram_part;

architecture rtl of custom_ram_part is

  constant rows : natural := 2**adr_size;
  type t_ram is array (0 to rows-1) of std_logic_vector(data_width-1 downto 0); 
  shared variable ram : t_ram;

begin
 
    process (clk)
        variable a_adr_int : integer;
    begin
        if rising_edge(clk) then
            if a_en = '1' then
                a_adr_int := to_integer(unsigned(a_adr));
                if a_we = '1' then
                    ram(a_adr_int) := a_di;
                end if;
                a_do <= ram(a_adr_int);
            end if;
        end if;
    end process;

    process (clk)
        variable b_adr_int : integer;        
    begin
        if rising_edge(clk) then
            if b_en = '1' then
                b_adr_int := to_integer(unsigned(b_adr));
                if b_we = '1' then
                    ram(b_adr_int) := b_di;
                end if;
                b_do <= ram(b_adr_int);
            end if;
        end if;
    end process;
  
end architecture;
