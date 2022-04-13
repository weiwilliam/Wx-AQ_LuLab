#!/bin/bash

rundir=${1}
syspath=${2}
sdate=${3}
edate=${4}
num_metgrid_levels=${5}
chem_opt=${6}

mkdir $rundir/emi

## megan
mkdir $rundir/emi/megan
cd $rundir/emi/megan 
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MEGAN/megan_bio_emiss .
ln -sf $syspath/create_emiinp_megan.bash .
ln -sf $syspath/run_emi_megan.sh .

sh create_emiinp_megan.bash $rundir $sdate $edate
sh run_emi_megan.sh .
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of megan_bio_emiss." >> $logfile
  exit ${error}
fi

cd $rundir/wrf 
ln -sf $rundir/emi/megan/wrfbiochemi* .


## anth
mkdir $rundir/emi/anth
cd $rundir/emi/anth
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/ANTH/anthro_emis .
ln -sf $syspath/create_emiinp_anth.bash .
ln -sf $syspath/run_emi_anth.sh .

sh create_emiinp_anth.bash $rundir $sdate $edate
sh run_emi_anth.sh .
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of anth_emis." >> $logfile
  exit ${error}
fi


cd $rundir/wrf
ln -sf $rundir/emi/anth/wrfchemi* .


## fire
mkdir $rundir/emi/fire
cd $rundir/emi/fire
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/FIRE/fire_emis .
ln -sf $syspath/create_emiinp_fire.bash .
ln -sf $syspath/run_emi_fire.sh .

sh create_emiinp_fire.bash $rundir $sdate $edate
sh run_emi_fire.sh .

error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of fire_emis." >> $logfile
  exit ${error}
fi


cd $rundir/wrf
ln -sf $rundir/emi/fire/wrffirechemi* .


## mozart input files by mozcart_precessor
mkdir $rundir/emi/mozcart
cd $rundir/emi/mozcart
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZCART_processor/* .
ln -sf $syspath/create_emiinp_mozcart.bash .
ln -sf $syspath/run_emi_exo_coldens.sh .
ln -sf $syspath/run_emi_wesely.sh .

sh create_emiinp_mozcart.bash $rundir
sh run_emi_exo_coldens.sh .
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of exo_coldens." >> $logfile
  exit ${error}
fi

sh run_emi_wesely.sh .
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of wesely." >> $logfile
  exit ${error}
fi

cd $rundir/wrf
ln -sf $rundir/emi/mozcart/exo_coldens_d* .
ln -sf $rundir/emi/mozcart/wrf_season_wes_usgs_d* .


## run real w chem on
sh $syspath/create_namelist.input.bash $rundir $sdate $edate $num_metgrid_levels $chem_opt

cd $rundir/wrf
sh run_real.sh $rundir/wrf
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of real.exe with chem on." >> $logfile
  exit ${error}
fi


## mozbc to prepapre BC if using MOZART chem option

mkdir $rundir/mozbc
cd $rundir/mozbc
mozbcdir="$rundir/mozbc"

# temp data for LISTOS test
ln -sf /network/rit/lab/lulab/chinan/WRF/DATA/BCIC/CHEM_IC/h0001.nc h0001.nc
#cp $rundir/wps/met_em* .
#cp $rundir/wrf/wrfin* .
#cp $rundir/wrf/wrfbdy* .
ln -sf $rundir/wps/met_em* .
ln -sf $rundir/wrf/wrfin* .
ln -sf $rundir/wrf/wrfbdy* .

ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZBC/* .
ln -sf $syspath/create_emiinp_mozbc.bash .
ln -sf $syspath/run_emi_mozbc.sh .

echo"mozbc for Domain 2:"
do_bc=.false.
domain=2
sh create_emiinp_mozbc.bash $mozbcdir $do_bc $domain
sh run_emi_mozbc.sh .
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of mozbc for Domain 2." >> $logfile
  exit ${error}
fi

echo"mozbc for Domain 1:"
do_bc=.true.
domain=1
sh create_emiinp_mozbc.bash $mozbcdir $do_bc $domain
sh run_emi_mozbc.sh .

error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of mozbc for Domain 1." >> $logfile
  exit ${error}
fi

