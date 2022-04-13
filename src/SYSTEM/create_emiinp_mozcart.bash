#!/bin/bash

rundir=${1}

fileo=$rundir/emi/mozcart/wesely.inp
cat << EOF > $fileo 

&control

wrf_dir = '$rundir/wrf'
domains = 2,

/
EOF


fileo=$rundir/emi/mozcart/exo_coldens.inp
cat << EOF > $fileo

&control

wrf_dir = '$rundir/wrf'
domains = 2,

/
EOF

