#!/bin/ksh
set -x
Eaddress=swei@albany.edu
export dump=$1 # gdas or gfs
export datatype=$2 # obs or grib2
export scrptshome=/network/rit/home/sw651133/scripts
export homepath=/network/asrc/scratch/lulab/sw651133/nomads
export datatank=$homepath/$dump
[[ ! -d $datatank ]]&&mkdir -p $datatank
export logdir=$homepath/logs
[[ ! -d $logdir ]]&&mkdir -p $logdir
export wrktmp=$homepath/wrk
if [ ! -d $wrktmp ]; then
   mkdir -p $wrktmp
else
   rm $wrktmp/*
fi
cd $wrktmp
#setup commands and env variables
wgetcmd=`which wget`
datecmd=`which date`
export waittime=300 #check interval (in second)
export maxtry=12    #max try

echo "Start time: `$datecmd -u`"
RDATE=`$datecmd -u +%Y%m%d%H%M`
pdy=`echo $RDATE | cut -c1-8`
R_cyc=10#`echo $RDATE | cut -c9-10`
#echo "Current time (UTC): $RDATE"
case $dump in
'gfs')
   # prepbufr for gfs dump is available at +3hr30mins
   if   (($R_cyc >= 10#00 && $R_cyc < 10#06 )); then
      cyc='00'
   elif (($R_cyc >= 10#06 && $R_cyc < 10#12 )); then
      cyc='06'
   elif (($R_cyc >= 10#12 && $R_cyc < 10#18 )); then
      cyc='12'
   elif (($R_cyc >= 10#18 && $R_cyc < 10#24 )); then
      cyc='18'
   fi ;;
'gdas')
   # prepbufr for gdas dump is available at +6hr40mins
   if   (($R_cyc >= 10#06 && $R_cyc < 10#12 )); then
      cyc='00'
   elif (($R_cyc >= 10#12 && $R_cyc < 10#18 )); then
      cyc='06'
   elif (($R_cyc >= 10#18 && $R_cyc < 10#24 )); then
      cyc='12'
   elif (($R_cyc >= 10#00 && $R_cyc < 10#06 )); then
      pdy=`$datecmd -ud "1 day ago" +%Y%m%d`
      cyc='18'
   fi ;;
esac

export CDATE=${pdy}${cyc}
echo "Pull cycle: $CDATE"

# Purge the data 7 days ago
####
cyy=`echo $CDATE | cut -c1-4`
cdd=`echo $CDATE | cut -c5-6`
cmm=`echo $CDATE | cut -c7-8`
chh=`echo $CDATE | cut -c9-10`
PURGE_DATE=`$datecmd -ud "1 week ago ${cyy}-${cdd}-${cmm} ${chh}:00:00" +%Y%m%d%H%M`
echo "Testing Purge cycle: $PURGE_DATE"
#purge_pdy=`echo $PURGE_DATE | cut -c1-8`
#purge_cyc=`echo $PURGE_DATE | cut -c9-10`
#if [ -d $datatank/$dump/${dump}.${purge_pdy}/${purge_cyc} ]; then
#   rm -rf $datatank/$dump/${dump}.${purge_pdy}/${purge_cyc}
#fi
#if [ -s $logdir/log.${dump}_${datatype}.${PURGE_DATE} ]; then
#   rm $logdir/log.${dump}_${datatype}.${PURGE_DATE}
#fi

case $datatype in
'obs')
   scrpts=$scrptshome/pull_obs.sh ;;
'grib2')
   scrpts=$scrptshome/pull_grib2.sh ;;
'NYSM')
   scrpts=$scrptshome/pull_nysm.sh ;;
esac

sh $scrpts $dump $CDATE > $logdir/log.${dump}_${datatype}.${CDATE} 2>&1

rc=$?
if [ $rc -ne 0 ]; then
   echo "`$datecmd -u`: !Warning! $CDATE code:$rc"
   echo "`$datecmd -u`: !Warning! $CDATE code:$rc" | mail -s "Failed,$dump,$datatype,$CDATE" $Eaddress
   exit $rc
else
   echo "Finish time: `$datecmd -u`"
   # echo "Finish time: `$datecmd -u`" | mail -s "Finished,$dump,$datatype,$CDATE" $Eaddress
fi


exit 0
