#!/bin/bash
ulimit -s unlimited
sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 28 ${1}/metgrid.exe"
