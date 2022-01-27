#!/bin/bash
ulimit -s unlimited
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
