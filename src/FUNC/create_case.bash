#!/bin/bash

datpath=${1}
rundir=${2}
#outpath=${3}
runpath=${3}
srcpath=${4}
sdate=${5}
geo=${6}

if [ -d $rundir ] 
then
 echo "create_case.bash: $rundir already created. Leaving function."
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
gdasln="prepbufr.gdas.${sdate:0:8}.t${sdate:8:2}z.nr"
gfsdir="$datpath/gfs/gfs.${sdate:0:8}/${sdate:8:2}"
ln -sf $gfsdir/gfs.t${sdate:8:2}z.pgrb2.0p25* .
ln -sf $gdasdir/gdas.* $gdasln

#WPS
cd $rundir/wps
ln -sf $srcpath/WPS/Vtable .
cp -f $srcpath/WPS/link_grib.csh .
cp -f $srcpath/WPS/ungrib.exe .
cp -f $srcpath/WPS/metgrid.exe .
if [ $geo -eq 1 ] #frequency running geogrid. turn it on indefinintely? (seasonal land surface change).
then
  cp -f $srcpath/WPS/geogrid.exe .
  cp -f $srcpath/SCRIPTS/run_geogrid.p.sh run_geogrid.sh
else
  pdate=`sh ${srcpath}/FUNC/get_pdate.bash $sdate`
  #cp -f $outpath/wrfgsi.out.$pdate/geo_em.* . #for now but should go to outdir
  cp -f $runpath/wrfgsi.run.$pdate/wps/geo_em.* . #for now but should go to outdir
fi
cp -f $srcpath/SCRIPTS/run_ungrib.p.sh run_ungrib.sh
cp -f $srcpath/SCRIPTS/run_metgrid.p.sh run_metgrid.sh

#WRF
cd $rundir/wrf
ln -sf $srcpath/WRF/* .
cp -f $srcpath/SCRIPTS/run_real.p.sh run_real.sh
cp -f $srcpath/SCRIPTS/run_wrf.p.sh run_wrf.sh

#GSI
cd $rundir/gsi
mkdir realtime
cp -f $srcpath/GSI/gsi.x .
cp -f $srcpath/GSI/comgsi_namelist.sh.soilTQ .
cp -f $srcpath/GSI/global_convinfo.txt .
cp -f $srcpath/SCRIPTS/run_gsi_regional.ksh.swei run_gsi_regional.ksh
cp -f $srcpath/SCRIPTS/run_gsicheck.p.sh run_gsicheck.sh

#LBC
cd $rundir/lbc
cp -f $srcpath/LBC/da_update_bc.exe .
#cp -f $srcpath/LBC/lateralBC_update.csh .
cp -f $srcpath/LBC/parame.in.LBC parame.in
cp -f $srcpath/SCRIPTS/run_lbc.p.sh run_lbc.sh

