#!/bin/bash
set -x
dump=$1
CDATE=${CDATE:-$2}
prepdatahome=${prepdatahome}
homepath=${homepath:-/network/asrc/scratch/lulab/sw651133/nomads}
datatank=${datatank:-$homepath/$dump}
logdir=${logdir:-$homepath/logs}
wrktmp=${wrktmp:-$homepath/wrk}
if [ -f $prepdatahome/ush/conda_source ]; then
   source $prepdatahome/ush/conda_source
fi
cd $wrktmp

#setup commands and env variables
datecmd=`which date`
wgetcmd=`which wget`
waittime=300 #check interval (in second)
maxtry=12    #max try
BUFR_APP_EXEC=${prepdatahome}/bin/prepbufr_append_surface.x
if [ ! -s $BUFR_APP_EXEC ]; then
   echo "Error!! $BUFR_APP_EXEC does not exist!"
   exit 11
fi

echo "Start time: `$datecmd -u`"
# Create the target cycle and local folder
echo "Pulling cycle: ${CDATE}"
pdy=`echo $CDATE | cut -c1-8`
cyc=`echo $CDATE | cut -c9-10`
cyc_logs=$logdir/cyclelist.${dump}_NYSM.out
target_dir=${datatank}/${dump}.${pdy}/${cyc}
if [ ! -d $target_dir ]; then
   echo "$target_dir does not exist"
   exit 12
fi

# Set environment variables for convert_NYSM_nc2bufr.py
# Convert and filter observations in assimilation window to intermediate file
export CDATE
export HINT=1
export NYSM_PATH=${NYSM_PATH:-/network/rit/lab/lulab/NY-Meso/proc}
export FIX_PATH=${FIX_PATH:-${prepdatahome}/fix}

python $prepdatahome/ush/python/convert_NYSM_nc2bufr.py
rc=$?
if [ $rc -ne 0 ]; then
   echo 'Fail to convert NYSM to intermediate file'
   exit 13
fi

BUFRTBL=$FIX_PATH/prepbufr.table
BUFR_IN=$target_dir/${dump}.t${cyc}z.prepbufr.nr
BUFR_OUT=$target_dir/${dump}.t${cyc}z.prepbufr.nr.nysmsfc

if [ -s $BUFRTBL -a -s $BUFR_IN -a \
     -s ./intermediate.csv ]; then
   cp $BUFRTBL $wrktmp
   cp $BUFR_IN $wrktmp/prepbufr
   $BUFR_APP_EXEC $CDATE
   if [ $rc -ne 0 ]; then
      echo 'Append intermediate data to prepbufr fail'
      exit 14
   else
      echo "Appending NYSM to prepbufr succeed"
      cp $wrktmp/prepbufr $BUFR_OUT 
   fi
else
   echo "Needed files are not available, please check $wrktmp"
   exit 15
fi
