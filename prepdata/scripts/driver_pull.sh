#!/bin/ksh
set -x
Eaddress=swei@albany.edu
export dump=$1 # gdas or gfs
export datatype=$2 # obs or grib2
export prepdatahome=${PWD}/..
export scrptshome=${prepdatahome}/scripts
export datapath=/network/asrc/scratch/lulab/sw651133/nomads
export datatank=$datapath/$dump
[[ ! -d $datatank ]]&&mkdir -p $datatank
export logdir=$datapath/logs
[[ ! -d $logdir ]]&&mkdir -p $logdir
export wrktmp=$datapath/wrk/wrk.${dump}_${datatype}
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
'chem')
   # WACCM data is available near 12 UTC
   # Prior day FINN data is available at 06 UTC
   cyc='00' ;;
esac

export CDATE=${pdy}${cyc}
echo "Pull cycle: $CDATE"

# Purge the data 7 days ago
####
cyy=`echo $CDATE | cut -c1-4`
cdd=`echo $CDATE | cut -c5-6`
cmm=`echo $CDATE | cut -c7-8`
chh=`echo $CDATE | cut -c9-10`
PURGE_DATE=`$datecmd -ud "2 week ago ${cyy}-${cdd}-${cmm} ${chh}:00:00" +%Y%m%d%H%M`
echo "Purging cycle: $PURGE_DATE"
if [ -s $logdir/log.${dump}_${datatype}.${PURGE_DATE} ]; then
   echo "Removing $logdir/log.${dump}_${datatype}.${PURGE_DATE}"
   rm $logdir/log.${dump}_${datatype}.${PURGE_DATE}
fi

case $datatype in
'obs')
   scrpts=$scrptshome/pull_obs.sh ;;
'grib2')
   scrpts=$scrptshome/pull_grib2.sh ;;
'waccm')
   scrpts=$scrptshome/pull_waccm.sh ;;
'finn')
   scrpts=$scrptshome/pull_finn.sh ;;
esac

sh $scrpts $dump $CDATE $PURGE_DATE > $logdir/log.${dump}_${datatype}.${CDATE} 2>&1

rc=$?
if [ $rc -ne 0 ]; then
   echo "`$datecmd -u`: !Warning! $CDATE code:$rc"
   echo "`$datecmd -u`: !Warning! $CDATE code:$rc" | mail -s "Failed,$dump,$datatype,$CDATE" $Eaddress
   exit $rc
else
   echo "Finish time: `$datecmd -u`"
   # echo "Finish time: `$datecmd -u`" | mail -s "Finished,$dump,$datatype,$CDATE" $Eaddress
fi

if [ $datatype == 'obs' ]; then
   sh $scrptshome/append_nysm2bufr.sh $dump $CDATE >> $logdir/log.${dump}_${datatype}.${CDATE} 2>&1
   rc=$?
   if [ $rc -ne 0 ]; then
      echo "`$datecmd -u`: !Warning! $CDATE code:$rc"
      echo "`$datecmd -u`: !Warning! $CDATE code:$rc" | mail -s "Failed,$dump,$datatype,$CDATE,append_nysm" $Eaddress
      exit $rc
   else
      echo "Finish time: `$datecmd -u`"
   fi
fi


exit 0
