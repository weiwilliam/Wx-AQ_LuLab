#!/bin/bash
GSI_RUNDIR=$1
#JOBNAME="GSI"
#SCRIPTNAME="${JOBNAME}_runscript"
#CKFILE="realtime.log"

#CHECKPOINT
sqrc=1
count=0
stopcount=10
until [ $sqrc -ne 1 ]
do
    if [ -s $GSI_RUNDIR/wrf_inout ]; then
       sqrc=0
    fi
    #ls realtime/ > ${CKFILE} 
    #grep -i "wrf_inout" ${CKFILE} >> ${SCRIPTNAME}
    #sqrc=$?
    sleep 20
    count=$((count+1))
    if [ $count -eq $stopcount ]
    then
       echo Error: Timeout ${JOBNAME}.
       exit 6 #use different nonzero number for each script
    fi
done


#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
