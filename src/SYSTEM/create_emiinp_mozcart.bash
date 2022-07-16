#!/bin/bash

rundir=${1}
run_dom=${2}

fileo=$rundir/emi/mozcart/wesely.inp
cat << EOF > $fileo 

&control

wrf_dir = '$rundir/wrf'
domains = $run_dom,

/
EOF


fileo=$rundir/emi/mozcart/exo_coldens.inp
cat << EOF > $fileo

&control

wrf_dir = '$rundir/wrf'
domains = $run_dom,

/
EOF

