#!/bin/bash

### This program runs the near realtime (NRT)  WRF-GSI fully cycled system ###

topdir="/network/rit/home/dg771199/WRF-GSI"
runpath="/network/asrc/scratch/lulab/dg771199"
datpath="/network/asrc/scratch/lulab/sw651133/nomads"
outpath="/network/rit/lab/lulab/dg771199"
srcpath="$topdir/src"
logpath="$topdir/log"
obsdir="/network/asrc/scratch/lulab/sw651133/nomads/logs/"
gdasobsscript="cyclelist.gdas_obs.out"
gfsobsscript="cyclelist.gfs_grib2.out"

##### SETUP SYSTEM ####
## Set Environment ##
source $srcpath/FUNC/env.sh
## Start Date ##
sdate=`sh ${srcpath}/FUNC/get_sdate.bash`
#sdate=${1}
## Manual override for manual runs
#sdate="2021083000" #+6 hour forecast
## End Date, Previous Cycle Date( - 6hr)
edate=`sh ${srcpath}/FUNC/get_edate.bash $sdate`
pdate=`sh ${srcpath}/FUNC/get_pdate.bash $sdate`
## Create Logfile and sdate dependent variables##
logfile="$logpath/wrfgsi.log.$sdate"
echo "$sdate" 
echo "$sdate" > $logfile
rundir="$runpath/wrfgsi.run.$sdate"
datdir="$rundir/dat"
outdir="$outpath/wrfgsi.out.$sdate"
## GFS DATA CHECK GFS##
sh $srcpath/SCRIPTS/run_gfsdatacheck.sh $obsdir $sdate
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
## First Cycle Check ## 
#if [ ! -d $outpath/wrfgsi.out.$pdate ]
if [ ! -d $runpath/wrfgsi.run.$pdate ]
then
   firstrun=1
   echo "WRF-GSI: FIRST CYCLE" >> $logfile
else
   firstrun=0
   echo "WRF-GSI: NOT FIRST CYCLE" >> $logfile
fi
## Create Case ##
#sh $srcpath/FUNC/create_case.bash $datpath $rundir $outpath $srcpath $sdate $firstrun
sh $srcpath/FUNC/create_case.bash $datpath $rundir $runpath $srcpath $sdate $firstrun #also got change func
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
sh $srcpath/FUNC/create_namelist.wps.bash $rundir $sdate $edate
sh $srcpath/FUNC/create_namelist.input.bash $rundir $sdate $edate

##### BEGIN SYSTEM #####
## GOTO WPS ##
cd $rundir/wps
if [ $firstrun -eq 1 ]
then
  ## GEOGRID ##
  sh run_geogrid.sh $rundir/wps 
  error=$?
  if [ ${error} -ne 0 ]; then
    echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
    exit ${error}
  fi
fi
# UNGRIB ##
./link_grib.csh $datdir/ 
sh run_ungrib.sh $rundir/wps
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
## METGRID ##
sh run_metgrid.sh $rundir/wps
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
## GOTO WRF ##
cd $rundir/wrf
## REAL ##
ln -sf $rundir/wps/met_em.d0* .
sh run_real.sh $rundir/wrf
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
## GDAS DATA CHECK ##
if [ $firstrun -eq 0 ] ## Not first run of cycled system.
then
   sh $srcpath/SCRIPTS/run_gdasdatacheck.sh $obsdir $sdate
   error=$?
   if [ ${error} -ne 0 ]; then
      echo "WARNING: GDAS data not found. Thus, $sdate is now the FIRST CYCLE" >> $logfile
      firstrun=1
   fi
fi
if [ $firstrun -eq 0 ] ## Not first run of cycled system. So run GSI and LBC before WRF
then
   ## DATA CHECK ###
   sh $srcpath/SCRIPTS/run_gdasdatacheck.sh $obsdir $sdate
   ##IF GDAS Fails then just run wrf, which is assuming its like a first run.
     if [ ${error} -ne 0 ]; then
     echo "WARNING: GDAS data not found. Thus, $sdate is now the FIRST CYCLE" >> $logfile
     firstrun=1
     break ${error}
   fi
   ## GOTO GSI ##
   cd $rundir/gsi
   #GSI with 6 hour wrfout + data from pdate
   ## GSI ##
   #gsiwrfoutdir="$outpath/wrfgsi.out.$pdate"
   gsiwrfoutdir="$runpath/wrfgsi.run.$pdate/wrf"
   ./run_gsi_regional.ksh $sdate $rundir $gsiwrfoutdir > GSI.log  2>&1
   sh run_gsicheck.sh
   error=$?
   if [ ${error} -ne 0 ]; then
     echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
     exit ${error}
   fi
   ## GOTO LBC ##
   cd $rundir/lbc
   ## LBC ##
   sh run_lbc.sh $rundir
   error=$?
   if [ ${error} -ne 0 ]; then
     echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
     exit ${error}
   fi
   ## GOBACKTO WRF ##
   cd $rundir/wrf
   mv wrfinput_d01 wrfinput_d01.real
   cp $rundir/lbc/wrf_inout wrfinput_d01
fi
## WRF ##
sh run_wrf.sh $rundir/wrf
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}" >> $logfile
  exit ${error}
fi
## STORE RUN ##
sh $srcpath/FUNC/store_case.bash $rundir $outdir $sdate $firstrun
## CLEAN UP ##
echo "Firstrun is $firstrun" >> $logfile
echo "Program Complete for $sdate" >> $logfile
echo "Program Complete for $sdate" 
exit
