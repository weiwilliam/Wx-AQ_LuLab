#!/bin/ksh

BIN_DIR=${PWD}/../bin
export BUFR_DIR=/network/rit/lab/josephlab/LIN/GSI/build

if [ ! -d $BIN_DIR ]; then
   mkdir -p $BIN_DIR
fi

make clean
make

if [ -s prepbufr_append_surface.x ]; then
   mv prepbufr_append_surface.x $BIN_DIR
fi

