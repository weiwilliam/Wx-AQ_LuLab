#!/bin/bash
set -x
### This program runs the near realtime (NRT)  WRF-GSI fully cycled system ###
#################################### SETUP SYSTEM ######################################
# WRF/Chem choice, only 0 and 114 tested
chem_opt=114
realtime=0 
LISTOS=0
max_dom=2
run_dom=1 
da_doms="1"
major_rhr=6
cycle_rhr=6
major_cycle_list="00"
clean_up=0
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
partition=batch

if [ $realtime -eq 1 ]; then
   ## Input ##
   obsdir="/network/asrc/scratch/lulab/sw651133/nomads/logs/"
   datpath="/network/asrc/scratch/lulab/sw651133/nomads"
   ## Output ##
   runpath="/network/asrc/scratch/lulab/dg771199/WRFChem-GSIMes"
   outpath="/network/rit/lab/lulab/dg771199/WRFChem-GSIMes"
   logpath="$outpath/log"
   prepbufr_suffix="nr.nysmsfc"
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
   runpath="/network/asrc/scratch/lulab/sw651133/wx-aq_run"
   outpath="/network/asrc/scratch/lulab/sw651133/wx-aq_out"
#   runpath="/network/asrc/scratch/lulab/WRF-GSI-CASE"
#   outpath="/network/rit/lab/lulab/WRF-GSI-CASE"
#   runpath="/network/asrc/scratch/lulab/hluo/run"
#   outpath="/network/rit/lab/lulab/hluo/out"
   logpath="$outpath/log"
   first_date="2022070118" #10 digits time at every 6h; +6 hour forecast
    last_date="2022070118"
   prepbufr_suffix="nr.nysmsfc"
   
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
    #echo "Case $sdate" | tee -a $logfile
    echo "$(date): Start case $sdate" | tee -a $logfile
    #echo "$sdate" > $logfile
    rundir="$runpath/$sdate"
    datdir="$rundir/dat"
    outdir="$outpath/wrfgsi.out.$sdate"
    
    ## GFS DATA CHECK ##
    # Check upstream chemistry field as well and pass different return code for.
    sh $syspath/datacheck_gfs.sh $obsdir $sdate $edate $realtime $chem_opt $max_dom $run_dom
    error=$?
    case $error in
    0) chem_bc_flag=0 ; lndown=0;;  # chem_opt=0, met-only
    1) chem_bc_flag=1 ; lndown=1;;  # ACOM
    2) chem_bc_flag=2 ; lndown=0;;  # WACCM
    3) ;; # have_bcs_chem option  
    10|11|17)
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "GFS data or needed chem data not found by datacheck_gfs.sh." >> $logfile
      exit ${error} ;;
    esac

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

    ##### BEGIN SYSTEM #####
    ## GOTO WPS ##
    cd $rundir/wps
    # Always run max domains for geogrid to generate ACOM's domain 1 and nested NYS domain 
    if [ $firstrun -eq 1 ]
    then
      sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath $chem_bc_flag $max_dom
      ## GEOGRID ##
      sh run_geogrid.sh $rundir/wps $partition
      error=$?
      if [ ${error} -ne 0 ]; then
        echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
        echo "Unsuccessful run of geogrid.exe." >> $logfile
        exit ${error}
      fi
    fi
    # Rename geo_em files
    case $chem_bc_flag in
    0|2) 
       if [ $run_dom -eq 1 ]; then
          mv geo_em.d01.nc geo_em.d01.nc.outer
          cp geo_em.d02.nc geo_em.d01.nc 
       fi ;;
    1) 
       if [ -s geo_em.d01.nc.outer ]; then
          echo "WACCM chem_bc was used in $pdate, rename geo_em for ndown"
          mv geo_em.d01.nc geo_em.d02.nc
          mv geo_em.d01.nc.outer geo_em.d01.nc
       else
          echo "Keep 2 domains geo_em for ndown"
       fi ;;
    esac
    if [ $lndown -eq 1 ]; then
       # running ndown needs 2 domains metgrid files
       sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath $chem_bc_flag $geo_doms
    elif [ $lndown -eq 0 ]; then
       # no ndown run.
       # if run_dom = 1, use geo_em.d02 as d01, otherwise use user setting
       sh $syspath/create_namelist.wps.bash $rundir $sdate $edate $wpspath $chem_bc_flag $run_dom
    fi
    # UNGRIB ##
    ./link_grib.csh $datdir/gfs/
    sh run_ungrib.sh $rundir/wps $partition
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of ungrib.exe." >> $logfile
      exit ${error}
    fi
    ## METGRID ##
    sh run_metgrid.sh $rundir/wps $partition
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of metgrid.exe." >> $logfile  
      exit ${error}
    fi
   
    echo "$(date): Finish WPS " | tee -a $logfile

    ## GOTO WRF ##
    cd $rundir/wrf
    # Create namelist.input based on running ndown or not
    # lndown=1: 2-domain configuration
    # lndown=0: 1-domain configuration
    sh $syspath/create_namelist.input.bash $rundir $sdate $edate $rhr $num_metgrid_levels 0 $chem_bc_flag $lndown
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Problem to create namelist.input. See details in create_namelist.input.bash." >> $logfile
      exit ${error}
    fi
    ## REAL ##
    ln -sf $rundir/wps/met_em.d0* .
    sh run_real.sh $rundir/wrf $partition
    cp rsl.error.0000 rsl.error.0000.real
    cp rsl.out.0000 rsl.out.0000.real
    cp namelist.input namelist.input.real
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of real.exe." >> $logfile  
      exit ${error}
    fi

    echo "$(date): Finish Real" | tee -a $logfile

    if [ $lndown -eq 1 ]; then
       echo "Running ndown"
       #mv wrfinput_d02 wrfndi_d02
       #create namelist.input.bash 
    else
       echo "No ndown run"
    fi

    ## WRF/Chem input prep if chem_opt is not 0 ##
    if [ $chem_opt -ne 0 ]; then
	if [ $LISTOS -eq 1 ]; then
	   sh $syspath/WRFCHEM_INPUTLISTOS.bash $rundir $syspath $sdate $edate $num_metgrid_levels $chem_opt $rhr $datpath $logfile
	else 
	   sh $syspath/WRFCHEM_INPUT.bash $rundir $syspath $sdate $edate $num_metgrid_levels $chem_bc_flag \
                                          $chem_opt $rhr $datpath $logfile $run_dom $partition
   	fi
        error=$?
        if [ ${error} -ne 0 ]; then
          echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
          echo "Unsuccessful chem data preparation!." >> $logfile
          exit ${error}
        fi

        echo "$(date): Finish WRFCHEM_INPUT" | tee -a $logfile
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
    if [ $firstrun -eq 0 -a ! -z $da_doms ] ## Not first run of cycled system. So run GSI and LBC before WRF
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
       
       echo "GSI is assimilating ${prepbufr_file} with ${convinfo} at domain $da_doms" >> $logfile
           
       for d in $da_doms
       do
         sh $syspath/run_gsi_regional.ksh $sdate $d $rundir $gsiwrfoutdir $syspath $gsipath $prepbufr_file $convinfo $partition
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
       sh run_lbc.sh $rundir $partition
       error=$?
       if [ ${error} -ne 0 ]; then
         echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
         echo "Unsuccessful run of da_update_bc.exe." >> $logfile     
         exit ${error}
       fi
       ## GOBACKTO WRF ##
       cd $rundir/wrf
       for d in $da_doms
       do
          mv wrfinput_d0${d} wrfinput_d0${d}.real
          if [ $d -eq 1 ]; then
             mv wrfbdy_d0${d} wrfbdy_d0${d}.bf_lbc
             cp $rundir/lbc/wrf_inout $rundir/wrf/wrfinput_d0${d}
             cp $rundir/lbc/wrfbdy_d0${d} $rundir/wrf/wrfbdy_d0${d}
          else
             cp $rundir/gsi/d0${d}/wrf_inout wrfinput_d0${d}
          fi
       done
       echo "$(date): Finish GSI" | tee -a $logfile
    fi
    
    ## WRF ##
    [[ $lndown -eq 1 ]] && lndown=0
    sh $syspath/create_namelist.input.bash $rundir $sdate $edate $rhr $num_metgrid_levels $chem_opt $chem_bc_flag $lndown
    sh run_wrf.sh $rundir/wrf $partition
    error=$?
    if [ ${error} -ne 0 ]; then
      echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
      echo "Unsuccessful run of wrf.exe." >> $logfile  
      exit ${error}
    fi

    echo "$(date): Finish WRF" | tee -a $logfile
    
    ### STORE RUN ##
    in_da_doms=`echo $da_doms | sed -e 's/ /_/g'`
    sh $syspath/store_case.bash $rundir $outdir $sdate $firstrun $in_da_doms 
    ## CLEAN UP ##
    if [ $clean_up -eq 1 ]; then
    #if [ $realtime -eq 1 -a $clean_up -eq 1 ]; then
       # define purge rundir and outdir
       run_pdate=`sh ${syspath}/get_ndate.bash -24 $sdate`
       out_pdate=`sh ${syspath}/get_ndate.bash -168 $sdate`
       purge_rundir="$runpath/$run_pdate"
       purge_outdir="$outpath/wrfgsi.out.$out_pdate"
       sh $syspath/clean_case.bash $purge_rundir $purge_outdir
    fi

    echo "Firstrun is $firstrun" >> $logfile
    echo "Program Complete for $sdate" | tee -a $logfile
    #echo "Program Complete for $sdate" 
    
    ndate=`sh ${syspath}/get_ndate.bash $cycle_rhr $sdate`
    sdate=$ndate

done # End the loop of period

exit
