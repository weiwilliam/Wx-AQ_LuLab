#!/bin/bash
DATDIR=${1}
sdate=${2}
realtime=${3}
gfsobsscript="cyclelist.gfs_grib2.out"
CKFILE="$DATDIR/$gfsobsscript"
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
        echo "Error: GFS data failed."
        exit 11
    fi
    
    grep -qi "$sdate Succeed" ${CKFILE} 
    sqrc=$?
    sleep 60
    count=$((count+1))
    if [ $count -eq $stopcount ]
    then
       echo "Error: GFS data not found."
       exit 10 #use different nonzero number for each script
    fi
done
