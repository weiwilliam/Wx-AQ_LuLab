#!/bin/ksh
set -x
dump=$1
CDATE=${CDATE:-$2}
homepath=${homepath:-/network/asrc/scratch/lulab/sw651133/nomads}
datatank=${datatank:-$homepath/$dump}
logdir=${logdir:-$homepath/logs}
wrktmp=${wrktmp:-$homepath/wrk}
cd $wrktmp
#setup commands and env variables
datecmd=`which date`
wgetcmd=`which wget`
waittime=300 #check interval (in second)
maxtry=12    #max try

echo "Start time: `$datecmd -u`"
# Create the target cycle and local folder
echo "Pulling cycle: ${CDATE}"
pdy=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`
cyc_logs=$logdir/cyclelist.${dump}_obs.out
target_dir=${datatank}/${dump}.${pdy}/${cyc}
if [ ! -d $target_dir ]; then
   mkdir -p $target_dir
fi

nomadspath="https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/${dump}.${pdy}/${cyc}/atmos"
remote_prepbufr=$nomadspath/${dump}.t${cyc}z.prepbufr.nr  
 local_prepbufr=$target_dir/${dump}.t${cyc}z.prepbufr.nr  
echo $prepbufr

# Check the availability on nomads
rc=1
ntry=0
until [ $rc -eq 0 ]; do
   ntry=$((ntry+1))
   echo "Check #$ntry"
   $wgetcmd --spider $remote_prepbufr
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

rc=2
ntry=0
until [ $ntry -eq 5 ];do
   ntry=$((ntry+1))
   $wgetcmd -c $remote_prepbufr -O $local_prepbufr
   rc=$?
   if [ $rc -eq 0 ]; then
      echo "   Try #$ntry: Good" >> $cyc_logs
   else
      echo "   Try #$ntry: Fail" >> $cyc_logs
   fi
   sleep 60
done

if [ $rc -eq 0 ]; then
   echo "`$datecmd -u` $CDATE Succeed" >> $cyc_logs
else
   echo "Current time: `$datecmd -u`"
   echo "!!!Error!!! Data transfer failed 5 times ($((ntry*60)) seconds)"
   echo "`$datecmd -u` $CDATE Failed: data transfer failed" >> $cyc_logs
   exit 2 
fi

echo "Finish time: `$datecmd -u`"
exit 0
