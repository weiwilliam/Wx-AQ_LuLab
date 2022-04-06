#!/bin/bash

datpath=${1}
rundir=${2}
runpath=${3}
syspath=${4}
wpspath=${5}
wrfpath=${6}
lbcpath=${7}
gsipath=${8}
sdate=${9}
geo=${10} # should be firstrun

if [ -d $rundir ] 
then
 echo "Error: $rundir already exists."
 exit 1
else
  mkdir $rundir
fi 

mkdir $rundir/wps
mkdir $rundir/wrf
mkdir $rundir/gsi
mkdir $rundir/lbc
mkdir $rundir/dat

#Link Data
cd $rundir/dat
gdasdir="$datpath/gdas/gdas.${sdate:0:8}/${sdate:8:2}"
#gdasln="prepbufr.gdas.${sdate:0:8}.t${sdate:8:2}z.nr"
gfsdir="$datpath/gfs/gfs.${sdate:0:8}/${sdate:8:2}"
ln -sf $gdasdir/* .
mkdir gfs
cd gfs
#ln -sf $gfsdir/gfs.t${sdate:8:2}z.pgrb2.0p25* .
ln -sf $gfsdir/* .


#WPS
cd $rundir/wps
ln -sf $wpspath/Vtable .
ln -sf $wpspath/link_grib.csh .
ln -sf $wpspath/ungrib.exe .
ln -sf $wpspath/metgrid.exe .
if [ $geo -eq 1 ] # geo output includes data for the whole year
then
  ln -sf $wpspath/geogrid.exe .
  ln -sf $syspath/run_geogrid.sh run_geogrid.sh
else
  pdate=`sh ${syspath}/get_pdate.bash $sdate`
  cp -f $runpath/wrfgsi.run.$pdate/wps/geo_em.* . 
fi
ln -sf $syspath/run_ungrib.sh run_ungrib.sh
ln -sf $syspath/run_metgrid.sh run_metgrid.sh

#WRF
cd $rundir/wrf
ln -sf $wrfpath/* .
ln -sf $syspath/run_real.sh run_real.sh
ln -sf $syspath/run_wrf.sh run_wrf.sh

#GSI
cd $rundir/gsi
cp $gsipath/gsi.x .
cp $gsipath/nc_diag_cat.x .

#LBC
cd $rundir/lbc
ln -sf $lbcpath/da_update_bc.exe .
ln -sf $lbcpath/parame.in.LBC parame.in
ln -sf $syspath/run_lbc.sh .

