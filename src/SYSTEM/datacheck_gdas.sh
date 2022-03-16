#!/bin/bash
DATDIR=${1}
sdate=${2}
gdasobsscript="cyclelist.gdas_obs.out"
gfsobsscript="cyclelist.gfs_grib2.out"
CKFILE="$DATDIR/$gdasobsscript"
#CHECKPOINT
sqrc=1
count=0
stopcount=5
until [ $sqrc -ne 1 ]
do
    grep -qi "$sdate Failed" ${CKFILE} 
    sqrc=$?
    if [ $sqrc -ne 1 ]
    then
        echo "Data not found"
        exit 13
    fi
    grep -qi "$sdate Succeed" ${CKFILE} 
    sqrc=$?
    sleep 60
    count=$((count+1))
    if [ $count -eq $stopcount ]
    then
       echo "Timeout"
       exit 12 #use different nonzero number for each script
    fi
done
