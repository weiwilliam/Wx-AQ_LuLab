#!/bin/bash

rundir=${1}
syspath=${2}
sdate=${3}
edate=${4}

mkdir $rundir/emi

## megan
mkdir $rundir/emi/megan
cd $rundir/emi/megan 
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MEGAN/megan_bio_emiss .
ln -sf $syspath/create_emiinp_megan.bash .
ln -sf $syspath/run_emi_megan.sh .

sh create_emiinp_megan.bash $rundir $sdate $edate
sh run_emi_megan.sh .

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
sh run_emi_wesely.sh .

cd $rundir/wrf
ln -sf $rundir/emi/mozcart/exo_coldens_d* .
ln -sf $rundir/emi/mozcart/wrf_season_wes_usgs_d* .


## run real w chem on
sh $syspath/create_namelist.inputchem114.bash $rundir $sdate $edate
echo "WRF/CHEM chem on"
cd $rundir/wrf
sh run_real.sh $rundir/wrf


## mozbc to prepapre BC if using MOZART chem option
mkdir /network/asrc/scratch/lulab/temp/mozbc
cd /network/asrc/scratch/lulab/temp/mozbc


#mkdir $rundir/emi/mozbc
#cd $rundir/emi/mozbc

# temp data for LISTOS test
ln -sf /network/rit/lab/lulab/chinan/WRF/DATA/BCIC/CHEM_IC/h0001.nc h0001.nc
cp $rundir/wps/met_em* .
cp $rundir/wrf/wrfin* .
cp $rundir/wrf/wrfbdy* .

ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZBC/* .
ln -sf $syspath/create_emiinp_mozbc.bash .
ln -sf $syspath/run_emi_mozbc.sh .

do_bc=.false.
domain=2
sh create_emiinp_mozbc.bash $rundir $do_bc $domain
sh run_emi_mozbc.sh .

do_bc=.true.
domain=1
sh create_emiinp_mozbc.bash $rundir $do_bc $domain
sh run_emi_mozbc.sh .

