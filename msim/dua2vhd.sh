#!/bin/bash

input="$1.dua"
output="$1.vhd"

echo "library ieee;" > $output
echo "use ieee.std_logic_1164.all;" >> $output
echo "package rom_prog is" >> $output
echo "constant ADR_SIZE : natural := 15;" >> $output
echo "constant ROWS : natural := 2**ADR_SIZE;" >> $output
echo "type rom_type is array (0 to ROWS-1) of std_logic_vector(7 downto 0);" >> $output
echo "constant rom : rom_type := (" >> $output

i=0
cat $input | while read line
do
    hex=$(printf "%02X" "$((2#$line))")
    echo "$i => x\"$hex\"," >> $output
    i=$((i+1))
done

echo "others => x\"00\");" >> $output
echo "end package;" >> $output