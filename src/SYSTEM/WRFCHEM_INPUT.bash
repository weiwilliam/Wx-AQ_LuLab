#!/bin/bash
set -x

rundir=${1}
syspath=${2}
sdate=${3}
edate=${4}
num_metgrid_levels=${5}
chem_opt=${6}
datpath=${7}
syear=${3:0:4}
smon=${3:4:2}
sday=${3:6:2}

eyear=${4:0:4}
emon=${4:4:2}
eday=${4:6:2}



mkdir $rundir/emi

###################################################################### fire
# Using previous day fire emi
dateval=${3:0:8}

yday=$(date +%F -d "$dateval -1 days")
doym1=$(date -d $yday +%j)

doy=$(date -d $dateval +%j)

yyday=$(date +%F -d "$dateval +1 days")
doya1=$(date -d $yyday +%j)

mkdir $rundir/emi/fire
cd $rundir/emi/fire
ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doym1}.txt .
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/FIRE/* .
ln -sf $syspath/create_emiinp_fire.bash .
ln -sf $syspath/run_emi_fire.sh .

#if [ -f "/network/asrc/scratch/lulab/sw651133/nomads/chem/finn/GLOB_MOZ4_2022${dof}.txt" ] ; then
# change previous doy to current
# write header
head -1 GLOB_MOZ4_${syear}${doym1}.txt > GLOB_MOZ4_previousday.txt
# ignore first line and replace doy
awk -F, 'NR>1 {$1='$doy'; print}' OFS=, GLOB_MOZ4_${syear}${doym1}.txt >> GLOB_MOZ4_previousday.txt
if [ $sday -ne $eday ]; then
  ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doy}.txt .
  awk -F, 'NR>1 {$1='$doya1'; print}' OFS=, GLOB_MOZ4_${syear}${doy}.txt >> GLOB_MOZ4_previousday.txt
fi

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


###################################################################### megan
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


###################################################################### anth
mkdir $rundir/emi/anth
cd $rundir/emi/anth
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/ANTH/anthro_emis .
cp $syspath/anth_change_year.ncl .
cp $syspath/anth_rename.sh .
ln -sf $syspath/create_emiinp_anth.bash .
ln -sf $syspath/run_emi_anth.sh .

sh create_emiinp_anth.bash $rundir $sdate $edate
sh run_emi_anth.sh .

# change emission year of 2018 to simulation year
# possible problems for simulation across 2 different years
if [ ${syear} -ne 2018 ]; then
# rename file
  sed -i "s/year/$syear/g" anth_rename.sh
  sh anth_rename.sh

# change year in file
  for file in `ls wrfchem*`;
     do
        domain=${file:10:2}
        yy=${file:13:4}
        mm=${file:18:2}
        dd=${file:21:2}
        hh=${file:24:2}
        ncl domain=$domain yy=$yy mm=$mm dd=$dd hh=$hh anth_change_year.ncl;
  done;
fi

error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of anth_emis." >> $logfile
  exit ${error}
fi


cd $rundir/wrf
ln -sf $rundir/emi/anth/wrfchemi* .


###################################### mozart input files by mozcart_precessor
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


################################################################ run real w chem on
sh $syspath/create_namelist.input.bash $rundir $sdate $edate $num_metgrid_levels $chem_opt

cd $rundir/wrf
sh run_real.sh $rundir/wrf
cp rsl.error.0000 rsl.error.0000.realchem
cp rsl.out.0000 rsl.out.0000.realchem
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of real.exe with chem on." >> $logfile
  exit ${error}
fi


######################################### mozbc to prepapre BC if using MOZART chem option

mkdir $rundir/mozbc
cd $rundir/mozbc
mozbcdir="$rundir/mozbc"
#if [ -f "/network/asrc/scratch/lulab/sw651133/nomads/chem/finn/GLOB_MOZ4_2022${dof}.txt" ] ; then
# temp data for LISTOS test
ln -sf $datpath/chem/waccm/f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3.$syear-$smon-$sday-00000.nc h0001.nc
if [ $sday -ne $eday ]; then
  ln -sf $datpath/chem/waccm/f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3.$eyear-$emon-$eday-00000.nc h0002.nc
fi
#cp $rundir/wps/met_em* .
#cp $rundir/wrf/wrfin* .
#cp $rundir/wrf/wrfbdy* .
ln -sf $rundir/wps/met_em* .
ln -sf $rundir/wrf/wrfin* .
ln -sf $rundir/wrf/wrfbdy* .

ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZBC/* .
ln -sf $syspath/create_emiinp_mozbc.bash .
ln -sf $syspath/run_emi_mozbc.sh .

echo "mozbc for Domain 2:"
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

echo "mozbc for Domain 1:"
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

