#!/bin/bash
set -x
#export GDAS_OBS_PATH=/network/rit/home/sw651133/Wx-AQ/develop/NYSM_SFC/ADP
#export INPUT_PATH=/network/rit/home/sw651133/Wx-AQ/develop/NYSM_SFC/INPUT/
#export FIX_PATH=/network/rit/home/sw651133/Wx-AQ/develop/NYSM_SFC/fix
#export BUFR_APP_EXEC=/network/rit/home/sw651133/Wx-AQ/develop/NYSM_SFC/bin/prepbufr_append_surface.x
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
BUFR_APP_EXEC=/network/rit/home/sw651133/Wx-AQ/develop/NYSM_SFC/bin/prepbufr_append_surface.x

echo "Start time: `$datecmd -u`"
# Create the target cycle and local folder
echo "Pulling cycle: ${CDATE}"
pdy=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`
cyc_logs=$logdir/cyclelist.${dump}_NYSM.out
target_dir=${datatank}/${dump}.${pdy}/${cyc}
if [ ! -d $target_dir ]; then
   mkdir -p $target_dir
fi

# Get NYSM data
NYSM_SAVEDIR=$homepath/NYSM/$pdy

# Convert and filter observations in assimilation window to intermediate file
export CDATE
export HINT=1
python $HOMEPATH/convert_NYSM_2bufr.py
rc=$?
if [ $rc -ne 0 ]; then
   echo 'NYSM to intermediate conversion is failed'
   exit 11
fi

BUFRTBL=$FIX_PATH/prepbufr.table
BUFR_IN=$GDAS_OBS_PATH/prepbufr.gdas.20180715.t00z.nr

if [ -s $BUFRTBL -a -s $BUFR_IN -a \
     -s ./intermediate.csv ]; then
   cp $BUFRTBL $WRKDIR
   cp $BUFR_IN $WRKDIR/prepbufr
   $BUFR_APP_EXEC
   if [ $rc -ne 0 ]; then
      echo 'Append intermediate data to prepbufr fail'
      exit 12
   fi
else
   echo 'BUFRDATA is not available'
   exit 13
fi
