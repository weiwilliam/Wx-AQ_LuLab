#!/bin/bash

rundir=${1}
syear=${2:0:4}
smon=${2:4:2}
sday=${2:6:2}
shr=${2:8:2}
eyear=${3:0:4}
emon=${3:4:2}
eday=${3:6:2}
ehr=${3:8:2}
run_dom=$4

fileo=$rundir/emi/megan/megan_bio_emiss.inp
cat << EOF > $fileo 


&control

domains = $run_dom,
start_lai_mnth = $smon,
end_lai_mnth   = $emon,

wrf_dir   = '$rundir/wrf',
megan_dir = '/network/rit/lab/lulab/WRF-GSI/src/EMI/MEGAN/data'

/
EOF
