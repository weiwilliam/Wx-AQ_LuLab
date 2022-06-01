#!/bin/bash
set -x
### This program runs the near realtime (NRT)  WRF-GSI fully cycled system ###
#################################### SETUP SYSTEM ######################################
# WRF/Chem choice, only 0 and 114 tested
chem_opt=0
realtime=0 
da_doms="1 2"
major_rhr=12
cycle_rhr=6
major_cycle_list="00"
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
   prepbufr_suffix="nr"
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
#   runpath="/network/asrc/scratch/lulab/WRF-GSI-CASE"
#   outpath="/network/rit/lab/lulab/WRF-GSI-CASE"
#   runpath="/network/asrc/scratch/lulab/hluo/run"
#   outpath="/network/rit/lab/lulab/hluo/out"
   logpath="$outpath/log"
   first_date="2018071400" #10 digits time at every 6h; +6 hour forecast
    last_date="2018071406"
   prepbufr_suffix="nr"
   
   LISTOS=1
   if [ $LISTOS -eq 1 ]; then
     num_metgrid_levels=32
     gfssource="/network/rit/lab/josephlab/LIN/WORK/DATA/WRF-ICBC/GFS_180714_180817"
     gdassource="/network/rit/lab/josephlab/LIN/WORK/DATA/GSI-OBS/summer"
     # prepbufr_suffix options: nr, nr.nysmsfc, nr.nysmsfc.lidar, nr.nysmsfc.lidar.mwr
     prepbufr_suffix="nr.nysmsfc"
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

majcyclist=${major_cycle_list//" "/"|"}
num_metgrid_levels=${num_metgrid_levels:-34}

sdate=$first_date
while [ $sdate -le $last_date ]; do
     
    cyc=${sdate:8:2}
    ## Determine the forecast length based on major_cycle_list 
    eval "case \$cyc in
    $majcyclist) rhr=\$major_rhr ;;
    *) rhr=\$cycle_rhr ;;
    esac"

    ## End Date and Previous Cycle Date( - 6hr) ##
    edate=`sh ${syspath}/get_ndate.bash $rhr $sdate`
    pdate=`sh ${syspath}/get_ndate.bash -$cycle_rhr $sdate`
    
    ## Create mockdata for LISTOS period experiment
    if [ $LISTOS -eq 1 ]; then
       sh $syspath/create_mockdata.bash $gfssource $gdassource $datpath $obsdir $sdate $edate $syspath
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
    sh $syspath/create_case.bash $datpath $rundir $runpath $syspath $wpspath $wrfpath $lbcpath $gsipath $sdate $cycle_rhr $firstrun
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Run directory already exists. See details in create_case.bash." >> $logfile
      exit ${error}
    fi
    sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath
    sh $syspath/create_namelist.input.bash $rundir $sdate $edate $rhr $num_metgrid_levels 0
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Problem to create namelist.input. See details in create_namelist.input.bash." >> $logfile
      exit ${error}
    fi
     
    
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
    
    echo "WPS finish time: $(date)"
    
    
    ## GOTO WRF ##
    cd $rundir/wrf
    ## REAL ##
    ln -sf $rundir/wps/met_em.d0* .
    sh run_real.sh $rundir/wrf
    cp rsl.error.0000 rsl.error.0000.real
    cp rsl.out.0000 rsl.out.0000.real
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of real.exe." >> $logfile  
      exit ${error}
    fi
    
    echo "Real finish time: $(date)"

    ## WRF/Chem input prep if chem_opt is not 0 ##
    if [ $chem_opt -ne 0 ]; then
      sh $syspath/WRFCHEM_INPUT.bash $rundir $syspath $sdate $edate $num_metgrid_levels $chem_opt
    fi

 
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

       y4=${sdate:0:4}; m2=${sdate:4:2}; d2=${sdate:6:2}; h2=${sdate:8:2}
       if [ $realtime -eq 1 ]; then 
          prepbufr_file=gdas.t${h2}z.prepbufr.${prepbufr_suffix}
       else
          if [ $LISTOS -eq 1 ]; then
             prepbufr_file=prepbufr.gdas.${y4}${m2}${d2}.t${h2}z.${prepbufr_suffix}
          else
             prepbufr_file=gdas.t${h2}z.prepbufr.${prepbufr_suffix}
          fi
       fi
       convinfotag=`echo ${prepbufr_suffix#nr} | sed -e 's/\./_/g'`
       convinfo=global_convinfo${convinfotag}.txt
           
       for d in $da_doms
       do
         sh $syspath/run_gsi_regional.ksh $sdate $d $rundir $gsiwrfoutdir $syspath $gsipath $prepbufr_file $convinfo
       done
       error=$?
       if [ ${error} -ne 0 ]; then
         echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
         echo "Unsuccessful run of GSI" >> $logfile     
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
       mv wrfinput_d02 wrfinput_d02.real
       cp $rundir/lbc/wrf_inout wrfinput_d01
       cp $rundir/gsi/d02/wrf_inout wrfinput_d02 
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
    in_da_doms=`echo $da_doms | sed -e 's/ /_/g'`
    sh $syspath/store_case.bash $rundir $outdir $sdate $firstrun $in_da_doms
    ## CLEAN UP ##
    echo "Firstrun is $firstrun" >> $logfile
    echo "Program Complete for $sdate" >> $logfile
    echo "Program Complete for $sdate" 
    
    ndate=`sh ${syspath}/get_ndate.bash $cycle_rhr $sdate`
    sdate=$ndate

done # End the loop of period

exit
