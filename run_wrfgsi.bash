#!/bin/bash

### This program runs the near realtime (NRT)  WRF-GSI fully cycled system ###

#################################### SETUP SYSTEM ######################################

topdir="/network/rit/lab/lulab/WRF-GSI"
srcpath="$topdir/src"
#wrfpath="$srcpath/WRF"
#wpspath="$srcpath/WPS"
lbcpath="$srcpath/LBC"
gsipath="$srcpath/GSI"
wrfpath="/network/rit/lab/lulab/share_lib/WRF/WRF_TEST/WRF/run"
wpspath="/network/rit/lab/lulab/share_lib/WRF/WRF_TEST/WPS"
#wrfpath="/network/rit/lab/lulab/hluo/WRF43/WRF43/run"

# change syspath to your local path
syspath="/network/rit/home/hl682259/Realtime/Wx-AQ/src/SYSTEM"
source $syspath/env.sh

# WRF/Chem choice
chem_opt=114


########################### NRT/RETRO DATE AND IN/OUT DATA PATH SETTINS #################
## Input ##
obsdir="/network/asrc/scratch/lulab/sw651133/nomads/logs/"
datpath="/network/asrc/scratch/lulab/sw651133/nomads"

## Output ##
runpath="/network/asrc/scratch/lulab/WRF-GSI-NRT"
outpath="/network/rit/lab/lulab/WRF-GSI-NRT"
logpath="$outpath/log"

## Start Date for NRT run ##
sdate=`sh ${syspath}/get_sdate.bash`
realtime=1

# START of test/retro control #############
# Manually override output pathes and sdate for test/retro runs; 
# Creating mocking data if during LISTOS/or modify accordingly for other input
  
runpath="/network/asrc/scratch/lulab/WRF-GSI-CASE"
outpath="/network/rit/lab/lulab/WRF-GSI-CASE"
logpath="$outpath/log"
sdate="2018080612" #10 digits time at every 6h; +6 hour forecast
realtime=0

LISTOS=1
gfssource="/network/rit/lab/josephlab/LIN/WORK/DATA/WRF-ICBC/GFS_180714_180817"
gdassource="/network/rit/lab/josephlab/LIN/WORK/DATA/GSI-OBS/201808"
datpath="/network/asrc/scratch/lulab/WRF-GSI-CASE/mockdata"
obsdir="/network/asrc/scratch/lulab/WRF-GSI-CASE/mockdata/logs"
if [ $LISTOS -eq 1 ]; then
  sh $syspath/create_mockdata.bash $gfssource $gdassource $datpath $obsdir $sdate $syspath
fi
# END of retro control################

################################# PROGRAM START ##########################################

## End Date and Previous Cycle Date( - 6hr) ##
edate=`sh ${syspath}/get_edate.bash $sdate`
pdate=`sh ${syspath}/get_pdate.bash $sdate`


## Create Logfile and sdate dependent variables ##
logfile="$logpath/wrfgsi.log.$sdate"
echo "Case  $sdate" 
echo "Start time:"
date
echo "$sdate" > $logfile
rundir="$runpath/$sdate"
datdir="$rundir/dat"
outdir="$outpath/wrfgsi.out.$sdate"

## GFS DATA CHECK ##
sh $syspath/datacheck_gfs.sh $obsdir $sdate $realtime
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "GFS data not found by datacheck_gfs.sh." >> $logfile
  exit ${error}
fi

## First Cycle Check ## 
if [ ! -d $outpath/wrfgsi.out.$pdate ]
then
   firstrun=1
   echo "WRF-GSI: FIRST CYCLE" >> $logfile
else
   firstrun=0
   echo "WRF-GSI: NOT FIRST CYCLE" >> $logfile
fi

## Create Case ##
sh $syspath/create_case.bash $datpath $rundir $runpath $syspath $wpspath $wrfpath $lbcpath  $gsipath $sdate $firstrun
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Run directory already exists. See details in create_case.bash." >> $logfile
  exit ${error}
fi
sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath
sh $syspath/create_namelist.input.bash $rundir $sdate $edate 0

##### BEGIN SYSTEM #####
## GOTO WPS ##
cd $rundir/wps
if [ $firstrun -eq 1 ]
then
  ## GEOGRID ##
  sh run_geogrid.sh $rundir/wps 
  error=$?
  if [ ${error} -ne 0 ]; then
    echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
    echo "Unsuccessful run of geogrid.exe." >> $logfile
    exit ${error}
  fi
fi
# UNGRIB ##
./link_grib.csh $datdir/gfs/
sh run_ungrib.sh $rundir/wps
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessful run of ungrib.exe." >> $logfile
  exit ${error}
fi
## METGRID ##
sh run_metgrid.sh $rundir/wps
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessful run of metgrid.exe." >> $logfile  
  exit ${error}
fi

echo "WPS finish time:"
date


## GOTO WRF ##
cd $rundir/wrf
## REAL ##
ln -sf $rundir/wps/met_em.d0* .
sh run_real.sh $rundir/wrf
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessful run of real.exe." >> $logfile  
  exit ${error}
fi

echo "Real finish time:"
date

## GDAS DATA CHECK ##
if [ $firstrun -eq 0 ] ## Not first run of cycled system.
then
   sh $syspath/datacheck_gdas.sh $obsdir $sdate
   error=$?
   if [ ${error} -ne 0 ]; then
      echo "WARNING: GDAS data not found. Thus, $sdate is now the FIRST CYCLE." >> $logfile
      firstrun=1
   fi
fi
if [ $firstrun -eq 0 ] ## Not first run of cycled system. So run GSI and LBC before WRF
then
   ## GOTO GSI ##
   cd $rundir/gsi
   #GSI with 6 hour wrfout + data from pdate
   ## GSI ##
   #gsiwrfoutdir="$outpath/wrfgsi.out.$pdate"
   gsiwrfoutdir="$runpath/$pdate/wrf"
   ./run_gsi_regional.ksh $sdate $rundir $gsiwrfoutdir > GSI.log  2>&1
   sh datacheck_gsi.sh
   error=$?
   if [ ${error} -ne 0 ]; then
     echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
     echo "Unsuccessful run of real.exe." >> $logfile     
     exit ${error}
   fi
   ## GOTO LBC ##
   cd $rundir/lbc
   ## LBC ##
   sh run_lbc.sh $rundir
   error=$?
   if [ ${error} -ne 0 ]; then
     echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
     echo "Unsuccessful run of da_update_bc.exe." >> $logfile     
     exit ${error}
   fi
   ## GOBACKTO WRF ##
   cd $rundir/wrf
   mv wrfinput_d01 wrfinput_d01.real
   cp $rundir/lbc/wrf_inout wrfinput_d01
fi

## WRF/Chem input prep if chem_opt is not 0 ##
if [ $chem_opt -ne 0 ]; then
  sh $syspath/WRFCHEM_INPUT.bash $rundir $syspath $sdate $edate $chem_opt
fi

## WRF ##
sh run_wrf.sh $rundir/wrf
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessful run of wrf.exe." >> $logfile  
  exit ${error}
fi
## STORE RUN ##
sh $syspath/store_case.bash $rundir $outdir $sdate $firstrun
## CLEAN UP ##
echo "Firstrun is $firstrun" >> $logfile
echo "Program Complete for $sdate" >> $logfile
echo "Program Complete for $sdate" 
exit
