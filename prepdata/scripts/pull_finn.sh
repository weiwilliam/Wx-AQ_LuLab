#!/bin/ksh
set -x
dump=$1
CDATE=${CDATE:-$2}
PURGE_DATE=${PURGE_DATE:-$3}
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
cyc_logs=$logdir/cyclelist.${dump}_finn.out
target_dir=${datatank}/finn
if [ ! -d $target_dir ]; then
   mkdir -p $target_dir
fi

finnpath="https://www.acom.ucar.edu/acresp/MODELING/finn_emis_txt"

jdate=$(date +%Y%j -d "${CDATE:0:8} -1 days")
remote_finngz=$finnpath/GLOB_MOZ4_${jdate}.txt.gz

# Check the availability on nomads
rc=1
ntry=0
until [ $rc -eq 0 ]; do
   ntry=$((ntry+1))
   echo "Check #$ntry"
   $wgetcmd --spider $remote_finngz
   rc=$?
   [[ $rc -ne 0 ]]&&sleep $waittime
   if [[ $ntry -eq $maxtry ]]; then
      echo "Current time: `$datecmd -u`"
      echo "!!!Error!!! Data is not available after $((ntry*waittime)) seconds"
      echo "`$datecmd -u` $CDATE Failed: data not available" >> $cyc_logs
      exit 1
   fi
done

if [ $rc -eq 0 ]; then
   echo "Data available time:`$datecmd -u`"
fi

ntry=0
flag=0
until [ $ntry -eq 2 ];do
   ntry=$((ntry+1))
   $wgetcmd -N $remote_finngz
   rc=$?
   if [ $rc -eq 0 ]; then
      echo "   Try #$ntry: Good" >> $cyc_logs
      flag=1
   else
      echo "   Try #$ntry: Fail" >> $cyc_logs
   fi
   sleep 60
done

if [ $flag -eq 1 ]; then
   if [ -s $wrktmp/GLOB_MOZ4_${jdate}.txt.gz ]; then
      cd $wrktmp
      gunzip GLOB_MOZ4_${jdate}.txt.gz
   fi
   if [ -s $wrktmp/GLOB_MOZ4_${jdate}.txt ]; then
      mv $wrktmp/GLOB_MOZ4_${jdate}.txt $target_dir
   fi
   echo "`$datecmd -u` $CDATE Succeed" >> $cyc_logs
else
   echo "Current time: `$datecmd -u`"
   echo "!!!Error!!! Data transfer failed $ntry times ($((ntry*60)) seconds)"
   echo "`$datecmd -u` $CDATE Failed: data transfer failed" >> $cyc_logs
   exit 2
fi

# Purge the data if it exists
p_jday=$(date +%Y%j -d "${PURGE_DATE:0:8}")
echo "Purging jday: $p_jday"
if [ -s $target_dir/GLOB_MOZ4_${p_jday}.txt ]; then
   echo "Removing FINN data: $target_dir/GLOB_MOZ4_${p_jday}.txt"
   rm $target_dir/GLOB_MOZ4_${p_jdate}.txt
fi


echo "Finish time: `$datecmd -u`"
exit 0
