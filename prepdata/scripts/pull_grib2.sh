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
freq=3 # forecast pulling frequency (in hour)
fhmax=36

echo "Start time: `$datecmd -u`"
# Create the target cycle and local folder
echo "Pulling cycle: ${CDATE}"
pdy=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`
cyc_logs=$logdir/cyclelist.${dump}_grib2.out
target_dir=${datatank}/${dump}.${pdy}/${cyc}
if [ ! -d $target_dir ]; then
   mkdir -p $target_dir
fi

if [ -s $wrktmp/grb2filelist ]; then
   rm $wrktmp/grb2filelist
fi

nomadspath="https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/${dump}.${pdy}/${cyc}/atmos"
#nomadspath="https://ftpprd.ncep.noaa.gov/data/nccf/com/gfs/prod/${dump}.${pdy}/${cyc}/atmos"
fhr=0
until [ $fhr -gt $fhmax ]; do
   fhrstr=`printf %3.3i $fhr`
   tmpgrb2="$nomadspath/${dump}.t${cyc}z.pgrb2.0p25.f$fhrstr"
   echo $tmpgrb2 >> $wrktmp/grb2filelist
   fhr=$((fhr+freq))
done

if [ -s $wrktmp/grb2filelist ]; then
# Check the availability on nomads
rc=1
ntry=0
until [ $rc -eq 0 ]; do
   ntry=$((ntry+1))
   echo "Check #$ntry"
   $wgetcmd --spider -i grb2filelist
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
   $wgetcmd -N -i grb2filelist
   rc=$?
   if [ $rc -eq 0 ]; then
      echo "Try #$ntry: Good" 
      flag=1
   else
      echo "Try #$ntry: Fail"
   fi
   sleep 60
done

if [ $flag -eq 1 ]; then
   mvrc=0
   fhr=0
   until [ $fhr -gt $fhmax ]; do
      fhrstr=`printf %3.3i $fhr`
      if [ -s $wrktmp/${dump}.t${cyc}z.pgrb2.0p25.f$fhrstr ]; then
         mv $wrktmp/${dump}.t${cyc}z.pgrb2.0p25.f$fhrstr $target_dir/${dump}.t${cyc}z.pgrb2.0p25.f$fhrstr
         mvrc=$?
      fi
      fhr=$((fhr+freq))
   done
   if [ $mvrc -eq 0 ]; then
      echo "`$datecmd -u` $CDATE Succeed" >> $cyc_logs
   else
      echo "`$datecmd -u` $CDATE Failed: data moving failed" >>$cyc_logs
      echo 4
   fi
else
   echo "Current time: `$datecmd -u`"
   echo "!!!Error!!! Data transfer failed $ntry times ($((ntry*60)) seconds)"
   echo "`$datecmd -u` $CDATE Failed: data transfer failed" >> $cyc_logs
   exit 2 
fi

else
   echo "!!!Error!!! no grb2filelist available, something wrong"
   exit 3
fi

#Purge data
echo "Purging cycle: $PURGE_DATE"
if [ -d $target_dir ]; then
   echo "Removing $target_dir"
   rm -rf $target_dir
fi

echo "Finish time: `$datecmd -u`"
exit 0
