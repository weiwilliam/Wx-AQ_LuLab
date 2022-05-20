#!/bin/ksh
set -x
dump=$1
CDATE=${CDATE:-$2}
datapath=${datapath:-/network/asrc/scratch/lulab/sw651133/nomads}
datatank=${datatank:-$datapath/$dump}
logdir=${logdir:-$datapath/logs}
wrktmp=${wrktmp:-$datapath/wrk}
cd $wrktmp
#setup commands and env variables
datecmd=`which date`
wgetcmd=`which wget`
waittime=300 #check interval (in second)
maxtry=12    #max try
freq=1      
fdaymax=10

echo "Start time: `$datecmd -u`"
# Create the target cycle and local folder
echo "Pulling cycle: ${CDATE}"
pdy=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`
cyc_logs=$logdir/cyclelist.${dump}_waccm.out
target_dir=${datatank}/waccm
if [ ! -d $target_dir ]; then
   mkdir -p $target_dir
fi

acompath="https://www.acom.ucar.edu/waccm/DATA"

fday=0
until [ $fday -eq $fdaymax ]; do
   tmpdate=$(date +%Y%m%d -d "${CDATE:0:8} +$fday days")
   fday=$((fday+freq))
   y4=${tmpdate:0:4}; m2=${tmpdate:4:2}; d2=${tmpdate:6:2}
   tmpwaccmnc=$acompath/f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3.${y4}-${m2}-${d2}-00000.nc
   $wgetcmd --spider $tmpwaccmnc
   rc=$?
   if [ $rc -eq 0 ]; then
      echo $tmpwaccmnc >> $wrktmp/waccmfilelist
   else
      echo "`$datecmd -u` !!!WARNGING!!! $CDATE: day $fday is not available" >> $cyc_logs
   fi
done

if [ -s $wrktmp/waccmfilelist ];then
   cd $target_dir
   ntry=0
   flag=0
   until [ $ntry -eq 2 ];do
      ntry=$((ntry+1))
      $wgetcmd -N -i $wrktmp/waccmfilelist
      rc=$?
      if [ $rc -eq 0 ]; then
         echo "Try #$ntry: Good"
         flag=1
      else
         echo "Try #$ntry: Fail"
      fi
      sleep 60
   done
   
   if [ $flag -ne 1 ]; then
      echo "Current time: `$datecmd -u`"
      echo "!!!Error!!! Data transfer failed $ntry times ($((ntry*60)) seconds)"
      echo "`$datecmd -u` $CDATE Failed: data transfer failed" >> $cyc_logs
      exit 2
   fi

else
   echo "!!!Error!!! no waccmfilelist available, something wrong"
   exit 3
fi

echo "Finish time: `$datecmd -u`"
exit 0
