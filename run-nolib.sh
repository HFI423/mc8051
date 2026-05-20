#!/bin/bash
set -e

if [ "$#" -eq 0 ]; then
    echo "Usage: ./run-nolib.sh ENTITY [STOP_TIME, default 1000ns]"
    echo "Example: ./run-nolib.sh counter_tb"
    exit 1
fi

mkdir -p work
cd work

echo "Import src and test..."
ghdl -i --std=87 -fsynopsys --syn-binding $(find ../vhdl -name "*.vhd") $(find ../tb -name "*.vhd")

echo "Make $1..."
ghdl -m --std=87 -fsynopsys --syn-binding --workdir=. $1

echo "Run $1..."
ghdl -r --std=87 -fsynopsys --syn-binding $1 --stop-time=${2:-1000ns} --wave=$1.ghw --assert-level=${3:-error}

echo "Wave $1..."
gtkwave $1.ghw --rcvar 'do_initial_zoom_fit yes'
