library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity custom_ram is

  generic (
    data_width : natural := 32;
    adr_size : natural := 12;
    chip_data_width : natural := 36;
    chip_adr_size : natural := 9
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

end custom_ram;

architecture rtl of custom_ram is

  function minimum(
    a : integer;
    b : integer
  ) return integer is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;

  function maximum(
    a : integer;
    b : integer
  ) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;

  constant w_num : natural := natural(ceil(real(data_width)/real(chip_data_width)));
  constant l_num : natural := natural(maximum(2**(adr_size-chip_adr_size), 1));
  constant part_data_width : natural := minimum(data_width, chip_data_width);
  constant part_adr_size : natural := minimum(adr_size, chip_adr_size);

  signal a_adr_part : std_logic_vector(adr_size-chip_adr_size-1 downto 0);
  signal a_adr_part_reg : std_logic_vector(adr_size-chip_adr_size-1 downto 0);
  signal b_adr_part : std_logic_vector(adr_size-chip_adr_size-1 downto 0);
  signal b_adr_part_reg : std_logic_vector(adr_size-chip_adr_size-1 downto 0);

  type t_parts_do is array (0 to l_num-1) of std_logic_vector(data_width-1 downto 0);
  signal parts_a_en : std_logic_vector(l_num-1 downto 0);
  signal parts_a_we : std_logic_vector(l_num-1 downto 0);
  signal parts_a_do : t_parts_do;
  signal parts_b_en : std_logic_vector(l_num-1 downto 0);
  signal parts_b_we : std_logic_vector(l_num-1 downto 0);
  signal parts_b_do : t_parts_do;

begin

  a_adr_part <= std_logic_vector(a_adr(adr_size-1 downto chip_adr_size));
  a_do <= parts_a_do(conv_integer(a_adr_part_reg));
  b_adr_part <= std_logic_vector(b_adr(adr_size-1 downto chip_adr_size));
  b_do <= parts_b_do(conv_integer(b_adr_part_reg));

  gen_rams_w: for w in 0 to w_num-1 generate
    gen_rams_l: for l in 0 to l_num-1 generate

      gen_ram_ctrl_single: if l_num = 1 generate
        parts_a_en(l) <= a_en;
        parts_a_we(l) <= a_we;
        parts_b_en(l) <= b_en;
        parts_b_we(l) <= b_we;
      end generate;

      gen_ram_ctrl_multi: if l_num /= 1 generate
        parts_a_en(l) <= '1' when a_en = '1' and a_adr_part = conv_std_logic_vector(l, adr_size-chip_adr_size) else '0';
        parts_a_we(l) <= '1' when a_we = '1' and a_adr_part = conv_std_logic_vector(l, adr_size-chip_adr_size) else '0';
        parts_b_en(l) <= '1' when b_en = '1' and b_adr_part = conv_std_logic_vector(l, adr_size-chip_adr_size) else '0';
        parts_b_we(l) <= '1' when b_we = '1' and b_adr_part = conv_std_logic_vector(l, adr_size-chip_adr_size) else '0';
      end generate;

      ram_part: entity work.custom_ram_part
        generic map(
          data_width => minimum(part_data_width, data_width-w*part_data_width),
          adr_size => part_adr_size
        )
        port map(
          clk => clk,
          rst => rst,
          a_en => parts_a_en(l),
          a_we => parts_a_we(l),
          a_adr => a_adr(part_adr_size-1 downto 0),
          a_di => a_di(minimum(part_data_width*(w+1), data_width)-1 downto part_data_width*w),
          a_do => parts_a_do(l)(minimum(part_data_width*(w+1), data_width)-1 downto part_data_width*w),
          b_en => parts_b_en(l),
          b_we => parts_b_we(l),
          b_adr => b_adr(part_adr_size-1 downto 0),
          b_di => b_di(minimum(part_data_width*(w+1), data_width)-1 downto part_data_width*w),
          b_do => parts_b_do(l)(minimum(part_data_width*(w+1), data_width)-1 downto part_data_width*w)
        );
    end generate;
  end generate;

  process (clk)
  begin
    if rising_edge(clk) then
      a_adr_part_reg <= a_adr_part;
      b_adr_part_reg <= b_adr_part;
    end if;
  end process;

end architecture;
