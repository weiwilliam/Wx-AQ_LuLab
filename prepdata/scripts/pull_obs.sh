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

nomadspath1="https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/${dump}.${pdy}/${cyc}/atmos"
nomadspath2="https://ftpprd.ncep.noaa.gov/data/nccf/com/gfs/prod/${dump}.${pdy}/${cyc}/atmos"
nomadspath3="https://nomads.ncep.noaa.gov/pub/data/nccf/com/obsproc/prod/${dump}.${pdy}"
 local_prepbufr=$target_dir/${dump}.t${cyc}z.prepbufr.nr  
echo $prepbufr

# Check the availability on nomads
rc=1
ntry=0
until [ $rc -eq 0 ]; do
   ntry=$((ntry+1))
   echo "Check #$ntry"
   for path in $nomadspath1 $nomadspath2 $nomadspath3
   do
       remote_prepbufr=$path/${dump}.t${cyc}z.prepbufr.nr  
       $wgetcmd --spider $remote_prepbufr
       rc=$?
       [[ $rc -eq 0 ]]&&break
   done
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
   $wgetcmd -N $remote_prepbufr -O $local_prepbufr
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
   echo "`$datecmd -u` $CDATE Succeed" >> $cyc_logs
else
   echo "Current time: `$datecmd -u`"
   echo "!!!Error!!! Data transfer failed $ntry times ($((ntry*60)) seconds)"
   echo "`$datecmd -u` $CDATE Failed: data transfer failed" >> $cyc_logs
   exit 2 
fi

#Purge data
echo "Purging cycle: $PURGE_DATE"
purge_pdy=${PURGE_DATE:0:8}
purge_cyc=${PURGE_DATE:8:2}
purge_dir=${datatank}/${dump}.${purge_pdy}/${purge_cyc}
if [ -d $purge_dir ]; then
   echo "Removing $purge_dir"
   rm -rf $purge_dir
   if [ $purge_cyc -eq 18 ];then
      echo "Removing ${datatank}/${dump}.${purge_pdy}"
      rm -rf ${datatank}/${dump}.${purge_pdy}
   fi
fi


echo "Finish time: `$datecmd -u`"
exit 0
