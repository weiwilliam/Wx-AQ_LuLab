#!/bin/bash
JOBNAME="LBC"
EXE="da_update_bc.exe"
SCRIPTNAME="${JOBNAME}_runscript"
CKFILE="lateralBC.log"
rundir=${1}

cd $rundir/lbc
mv $rundir/wrf/wrfbdy_d01 .
cp -f wrfbdy_d01 wrfbdy_d01.bu
cp -f $rundir/gsi/realtime/wrf_inout .
ls > ${SCRIPTNAME}
./${EXE} > ${CKFILE}
#CHECKPOINT
sqrc=1
count=0
stopcount=10
until [ $sqrc -ne 1 ]
do
    grep -i "Update_bc completed successfully" ${CKFILE} >> ${SCRIPTNAME}
    sqrc=$?
    sleep 20
    count=$((count+1))
    if [ $count -eq $stopcount ]
    then
       echo Timeout ${JOBNAME}
       exit 7
    fi
done

cp wrfbdy_d01 $rundir/wrf/.

#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
