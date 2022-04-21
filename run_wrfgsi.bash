#!/bin/bash
set -x
### This program runs the near realtime (NRT)  WRF-GSI fully cycled system ###
#################################### SETUP SYSTEM ######################################
# WRF/Chem choice
chem_opt=114
realtime=0 
# When run retro case (realtime=0), please carefully 
# define your own path for $obsdir, $datpath, $runpath, $outpath below.

## Set Environment ##
topdir=$PWD 
syspath="$topdir/src/SYSTEM"
# Define your folders of installed packages
# A clean alternative WRF installation tested on Kratos
# wrfpath="/network/rit/lab/lulab/hluo/WRF43/WRF43/run"
#wrfpath="/network/rit/lab/lulab/WRF-GSI/src/WRF"
#wpspath="/network/rit/lab/lulab/WRF-GSI/src/WPS"
wrfpath="/network/rit/lab/lulab/share_lib/WRF/WRF_TEST/WRF/run"
wpspath="/network/rit/lab/lulab/share_lib/WRF/WRF_TEST/WPS"
lbcpath="/network/rit/lab/lulab/WRF-GSI/src/LBC"
gsipath="/network/rit/lab/lulab/WRF-GSI/src/GSI"
source $syspath/env.sh

if [ $realtime -eq 1 ]; then
   ## Input ##
   obsdir="/network/asrc/scratch/lulab/sw651133/nomads/logs/"
   datpath="/network/asrc/scratch/lulab/sw651133/nomads"
   ## Output ##
   runpath="/network/asrc/scratch/lulab/WRF-GSI-NRT"
   outpath="/network/rit/lab/lulab/WRF-GSI-NRT"
   logpath="$outpath/log"
   ## Start Date for NRT run ##
   sdate=`sh ${syspath}/get_sdate.bash`

elif [ $realtime -eq 0 ]; then
   ################################START of test/retro control ############################
   # Manually override output pathes and sdate for test/retro runs; 
   # Creating mocking data if during LISTOS/or modify accordingly for other input
   ## Input ##
   obsdir="/network/asrc/scratch/lulab/sw651133/nomads/logs/"
   datpath="/network/asrc/scratch/lulab/sw651133/nomads"
   ## Output ##
   runpath="/network/asrc/scratch/lulab/sw651133/wx-aq_test"
   outpath="/network/asrc/scratch/lulab/sw651133/wx-aq_out"
#  runpath="/network/asrc/scratch/lulab/WRF-GSI-CASE"
#  outpath="/network/rit/lab/lulab/WRF-GSI-CASE"
   logpath="$outpath/log"
   first_date="2018071418" #10 digits time at every 6h; +6 hour forecast
    last_date="2018071418"
   
   LISTOS=1
   if [ $LISTOS -eq 1 ]; then
     num_metgrid_levels=32
     gfssource="/network/rit/lab/josephlab/LIN/WORK/DATA/WRF-ICBC/GFS_180714_180817"
     gdassource="/network/rit/lab/josephlab/LIN/WORK/DATA/GSI-OBS/summer"
     datpath="${runpath}/mockdata"
     obsdir="${runpath}/mockdata/logs"
     [[ ! -d $datpath ]]&& mkdir -p $datpath
     [[ ! -d  $obsdir ]]&& mkdir -p $obsdir
   fi
   #################################### END of retro control ################################
fi

## Create folders if it doesn't exist
if [ ! -d $runpath ]; then
   mkdir -p $runpath
fi
if [ ! -d $outpath ]; then
   mkdir -p $outpath
fi
if [ ! -d $logpath ]; then
   mkdir -p $logpath
fi

if [ $realtime -eq 1 ]; then
   ## In realtime, first_date equals last_date
   first_date=$sdate
    last_date=$sdate
fi

num_metgrid_levels=${num_metgrid_levels:-34}

sdate=$first_date
while [ $sdate -le $last_date ]; do

    ## End Date and Previous Cycle Date( - 6hr) ##
    edate=`sh ${syspath}/get_edate.bash $sdate`
    pdate=`sh ${syspath}/get_pdate.bash $sdate`
    
    ## Create mockdata for LISTOS period experiment
    if [ $LISTOS -eq 1 ]; then
       sh $syspath/create_mockdata.bash $gfssource $gdassource $datpath $obsdir $sdate $syspath
    fi
    
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
    sh $syspath/create_case.bash $datpath $rundir $runpath $syspath $wpspath $wrfpath $lbcpath $gsipath $sdate $firstrun
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Run directory already exists. See details in create_case.bash." >> $logfile
      exit ${error}
    fi
    sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath
    sh $syspath/create_namelist.input.bash $rundir $sdate $edate $num_metgrid_levels 0
    
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
       sh $syspath/run_gsi_regional.ksh $sdate $rundir $gsiwrfoutdir $syspath $gsipath > GSI.log  2>&1
       sh $syspath/datacheck_gsi.sh $rundir/gsi
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
      sh $syspath/WRFCHEM_INPUT.bash $rundir $syspath $sdate $edate $num_metgrid_levels $chem_opt
    fi
    
    ## WRF ##
    sh run_wrf.sh $rundir/wrf
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of wrf.exe." >> $logfile  
      exit ${error}
    fi
    ### STORE RUN ##
    sh $syspath/store_case.bash $rundir $outdir $sdate $firstrun
    ## CLEAN UP ##
    echo "Firstrun is $firstrun" >> $logfile
    echo "Program Complete for $sdate" >> $logfile
    echo "Program Complete for $sdate" 
    
    ndate=`sh ${syspath}/get_ndate.bash $sdate`
    sdate=$ndate

done # End the loop of period

exit
