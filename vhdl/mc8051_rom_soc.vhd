-------------------------------------------------------------------------------
--                                                                           --
--          X       X   XXXXXX    XXXXXX    XXXXXX    XXXXXX      X          --
--          XX     XX  X      X  X      X  X      X  X           XX          --
--          X X   X X  X         X      X  X      X  X          X X          --
--          X  X X  X  X         X      X  X      X  X         X  X          --
--          X   X   X  X          XXXXXX   X      X   XXXXXX      X          --
--          X       X  X         X      X  X      X         X     X          --
--          X       X  X         X      X  X      X         X     X          --
--          X       X  X      X  X      X  X      X         X     X          --
--          X       X   XXXXXX    XXXXXX    XXXXXX    XXXXXX      X          --
--                                                                           --
--                                                                           --
--                       O R E G A N O   S Y S T E M S                       --
--                                                                           --
--                            Design & Consulting                            --
--                                                                           --
-------------------------------------------------------------------------------
--                                                                           --
--         Web:           http://www.oregano.at/                             --
--                                                                           --
--         Contact:       mc8051@oregano.at                                  --
--                                                                           --
-------------------------------------------------------------------------------
--                                                                           --
--  MC8051 - VHDL 8051 Microcontroller IP Core                               --
--  Copyright (C) 2001 OREGANO SYSTEMS                                       --
--                                                                           --
--  This library is free software; you can redistribute it and/or            --
--  modify it under the terms of the GNU Lesser General Public               --
--  License as published by the Free Software Foundation; either             --
--  version 2.1 of the License, or (at your option) any later version.       --
--                                                                           --
--  This library is distributed in the hope that it will be useful,          --
--  but WITHOUT ANY WARRANTY; without even the implied warranty of           --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        --
--  Lesser General Public License for more details.                          --
--                                                                           --
--  Full details of the license can be found in the file LGPL.TXT.           --
--                                                                           --
--  You should have received a copy of the GNU Lesser General Public         --
--  License along with this library; if not, write to the Free Software      --
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA  --
--                                                                           --
-------------------------------------------------------------------------------
--
--
--         Author:                 Helmut Mayrhofer
--
--         Filename:               mc8051_rom_sim.vhd
--
--         Date of Creation:       Mon Aug  9 12:14:48 1999
--
--         Version:                $Revision: 1.2 $
--
--         Date of Latest Version: $Date: 2002-01-07 12:16:57 $
--
--
--         Description: The mc8051 ROM model.
--
--
--
--
-------------------------------------------------------------------------------
architecture soc of mc8051_rom is

  constant ADR_SIZE : natural := 14;
  constant ROWS : natural := 2**ADR_SIZE;

  type rom_type is array (0 to ROWS-1) of std_logic_vector(7 downto 0);

  impure function init_rom return rom_type is
    file f_initfile : text open read_mode is c_init_file;
    variable v_line : line;
    variable v_rom : rom_type;
    variable v_data : bit_vector(7 downto 0);
    variable i : integer := 0;
  begin
    while (not endfile(f_initfile) and i < ROWS) loop
      readline(f_initfile, v_line);
      read(v_line, v_data);
      v_rom(i) := to_stdlogicvector(v_data);
      i := i + 1;
    end loop;
    return v_rom;
  end function;

  signal rom : rom_type := init_rom;

begin

    process(clk)
    begin
      if rising_edge(clk) then
        rom_data_o <= rom(conv_integer(unsigned(rom_adr_i)));
      end if;
    end process;

end architecture;