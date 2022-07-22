#!/bin/bash
set -x

rundir=${1}
syspath=${2}
sdate=${3}
edate=${4}
num_metgrid_levels=${5}
chem_bc=${6}
chem_opt=${7}
rhr=${8}
datpath=${9}
logfile=${10}
run_dom=${11}
partition=${12}

syear=${3:0:4}
smon=${3:4:2}
sday=${3:6:2}

eyear=${4:0:4}
emon=${4:4:2}
eday=${4:6:2}

mkdir $rundir/emi

###################################################################### fire
# Using most recent day fire emi for all fcst hours, by hour
dateval=${3:0:8}

yday=$(date +%F -d "$dateval -1 days")
doym1=$(date -d $yday +%j)

yday=$(date +%F -d "$dateval -2 days")
doym2=$(date -d $yday +%j)

yday=$(date +%F -d "$dateval -3 days")
doym3=$(date -d $yday +%j)

doy=$(date -d $dateval +%j)

yyday=$(date +%F -d "$dateval +1 days")
doya1=$(date -d $yyday +%j)

mkdir $rundir/emi/fire
cd $rundir/emi/fire
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/FIRE/* .
ln -sf $syspath/create_emiinp_fire.bash .
ln -sf $syspath/run_emi_fire.sh .

if [ -f "$datpath/chem/finn/GLOB_MOZ4_${syear}${doym1}.txt" ] ; then
  ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doym1}.txt FINNdata.txt
  echo "FINN used -1 day data" >> $logfile 
elif [ -f "$datpath/chem/finn/GLOB_MOZ4_${syear}${doym2}.txt" ] ; then
  ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doym2}.txt FINNdata.txt
  echo "FINN used -2 day data" >> $logfile
elif [ -f "$datpath/chem/finn/GLOB_MOZ4_${syear}${doym3}.txt" ] ; then
  ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doym3}.txt FINNdata.txt
  echo "FINN used -3 day data" >> $logfile
else
  echo "No suitable FINN data!" >> $logfile
  exit 14
fi

# change previous doy to current
# write header
head -1 FINNdata.txt > GLOB_MOZ4_previousday.txt
# ignore first line and replace 1st col w doy 
awk -F, 'NR>1 {$1='$doy'; print}' OFS=, FINNdata.txt >> GLOB_MOZ4_previousday.txt
if [ $sday -ne $eday ]; then
  #ln -sf  $datpath/chem/finn/GLOB_MOZ4_${syear}${doy}.txt .
  # ignore first line and replace 1st col w doya1
  awk -F, 'NR>1 {$1='$doya1'; print}' OFS=, FINNdata.txt >> GLOB_MOZ4_previousday.txt
fi

sh create_emiinp_fire.bash $rundir $sdate $edate $run_dom
sh run_emi_fire.sh . $partition

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

sh create_emiinp_megan.bash $rundir $sdate $edate $run_dom
sh run_emi_megan.sh . $partition
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
ln -sf $syspath/create_emiinp_anth4km.bash .
ln -sf $syspath/run_emi_anth.sh .

### 12km NEI for Domain 1
idom=1
while [ $idom -le $run_dom ]
do
  cd $rundir/emi/anth
  if [ $idom -eq 1 -a $idom -lt $run_dom ]; then
     # Coarse domain run with 12 km inventory
     res_km=12
     sh create_emiinp_anth.bash $rundir $sdate $edate $run_dom
  else
     # Inner domain or single domain: run with 4 km inventory
     res_km=4
     sh create_emiinp_anth4km.bash $rundir $sdate $edate $run_dom
  fi
  sh run_emi_anth.sh . anthro_emis_2018_${res_km}km_MOZCART_T1.inp $partition
#
  error=$?
  if [ ${error} -ne 0 ]; then
    echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
    echo "Unsuccessfuly run of ${res_km}km anth_emis for Domain ${idom}." >> $logfile
    exit ${error}
  fi
#
## change emission year of 2018 to simulation year
## possible problems for simulation across 2 different years
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
  cd $rundir/wrf
  cp $rundir/emi/anth/wrfchemi_d0${idom}* .
  
  idom=$((idom+1))
done
cd $rundir/emi/anth 
rm wrfchemi_*
###################################### mozart input files by mozcart_precessor
mkdir $rundir/emi/mozcart
cd $rundir/emi/mozcart
ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZCART_processor/* .
ln -sf $syspath/create_emiinp_mozcart.bash .
ln -sf $syspath/run_emi_exo_coldens.sh .
ln -sf $syspath/run_emi_wesely.sh .

sh create_emiinp_mozcart.bash $rundir
sh run_emi_exo_coldens.sh . $partition
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of exo_coldens." >> $logfile
  exit ${error}
fi

sh run_emi_wesely.sh . $partition
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
# real for chem always not ndown
lndown=0
sh $syspath/create_namelist.input.bash $rundir $sdate $edate $rhr $num_metgrid_levels $chem_opt $chem_bc $lndown

cd $rundir/wrf
sh run_real.sh $rundir/wrf $partition
error=$?
if [ ${error} -ne 0 ]; then
  echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
  echo "Unsuccessfuly run of real.exe with chem on." >> $logfile
  exit ${error}
fi
cp rsl.error.0000 rsl.error.0000.realchem
cp rsl.out.0000 rsl.out.0000.realchem
cp namelist.input namelist.input.realchem


######################################### mozbc to prepapre BC if using MOZART chem option

mkdir $rundir/mozbc
cd $rundir/mozbc
mozbcdir="$rundir/mozbc"

case $chem_bc in
1) chem_bc_path=$datpath/chem/acom
   chem_file_prefix="" 
   chem_interval=1
   chk_date=${sdate}
   ;;
2) chem_bc_path=$datpath/chem/waccm
   chem_file_prefix="f.e22.beta02.FWSD.f09_f09_mg17.cesm2_2_beta02.forecast.001.cam.h3"
   chem_interval=24
   chk_date=${sdate:0:4}${sdate:4:2}${sdate:6:2}00
   ;;
esac

#chk_date=$sdate
fidx=0
while [ $chk_date -le $edate ]
do
  chk_yy=${chk_date:0:4}; chk_mm=${chk_date:4:2}
  chk_dd=${chk_date:6:2}; chk_hh=${chk_date:8:2}
  chem_file=$chem_bc_path/${chem_file_prefix}.${chk_yy}-${chk_mm}-${chk_dd}-00000.nc
  if [ -s $chem_file ]; then
     fidx=$((fidx+1))
     ln -sf $chem_file h000${fidx}.nc  
  else
     echo "Chemistry file unavailable for ${chk_yy}-${chk_mm}-${chk_dd} !" >> $logfile
     exit 15
  fi
  chk_date=`sh ${syspath}/get_ndate.bash $chem_interval $chk_date`
done

ln -sf $rundir/wps/met_em* .
ln -sf $rundir/wrf/wrfin* .
ln -sf $rundir/wrf/wrfbdy* .

##BACKUP MOZBC that address Issue 36
ln -sf /network/rit/lab/lulab/sw651133/mozbc/mozbc .
#ln -sf /network/rit/lab/lulab/WRF-GSI/src/EMI/MOZBC/* .
ln -sf $syspath/create_emiinp_mozbc.bash .
ln -sf $syspath/run_emi_mozbc.sh .

idom=1
while [ $idom -le $run_dom ]
do
  echo "mozbc for Domain ${idom}:"
  if [ $idom -eq 1 ]; then
     do_bc=.true.
  else
     do_bc=.false.
  fi
  sh create_emiinp_mozbc.bash $mozbcdir $do_bc $idom
  sh run_emi_mozbc.sh . $partition

  error=$?
  if [ ${error} -ne 0 ]; then
    echo "ERROR: WRF-GSI crashed Exit status=${error}." >> $logfile
    echo "Unsuccessfuly run of mozbc for Domain ${idom}." >> $logfile
    exit ${error}
  fi
  idom=$((idom+1))
done
