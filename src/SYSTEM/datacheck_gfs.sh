#!/bin/bash
DATDIR=${1}
sdate=${2}
edate=${3}
realtime=${4}
chem_opt=${5}
max_dom=$6
run_dom=$7

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

if [ $chem_opt -ne 0 ]; then
   eyy=${edate:0:4}; emm=${edate:4:2}; edd=${edate:6:2}; ehh=${edate:8:2} 
   acom_edate_output=$DATDIR/../chem/acom/abc.nc
   waccm_edate_output=$DATDIR/../chem/waccm/f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3.${eyy}-${emm}-${edd}-00000.nc
   # Check ACOM folder
   if [ -s $acom_edate_output -a $max_dom -ne $run_dom ]; then
      exit 1
   # Check WACCM folder
   elif [ -s $waccm_edate_output ]; then
      exit 2
   else
   # when have_bcs_chem option ready modify the messages and exit code
      echo "ACOM and WACMM not found"
      exit 17 
   fi 
fi
