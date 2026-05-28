#!/usr/bin/env bash
set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: ./runx.sh PROGRAM_FILE_IN_MSIM_WITHOUT_EXTENSION [STOP_TIME, default 1000ns]"
    echo "Example: ./run.sh minitest_fp 1ms"
    exit 1
fi

cd msim
./hex2dual $1.h51
./dua2vhd.sh $1
\mv $1.dua ../vhdl/mc8051_rom.dua
\mv $1.vhd ../vhdl/mc8051_rom.vhd
cd ..
./run.sh tb_mc8051_top ${2:-10us}
