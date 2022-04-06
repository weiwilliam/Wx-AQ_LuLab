#!/bin/bash

#$gfssource $gdassource $datdir $obsdir#logs

gfssource=${1}
gdassource=${2}
datdir=${3}
logdir=${4}
sdate=${5}
syspath=${6}

mkdir -p $datdir/gfs
mkdir -p $datdir/gdas
ndate=`sh ${syspath}/get_ndate.bash $sdate`
edate=`sh ${syspath}/get_edate.bash $sdate`

# GFS Data
gfsdir=$datdir/gfs/gfs.${sdate:0:8}/${sdate:8:2}
mkdir -p $gfsdir
cd $gfsdir
ln -sf $gfssource/gfs.0p25.*.f000.grib2 .
#ln -sf $gfssource/gfs.0p25.${sdate}.f000.grib2 gfs.t${sdate:8:2}z.pgrb2.0p25.f000

#until [ $ndate -gt $edate ]
#do
 #   ln -sf $gfssource/gfs.0p25.${ndate}.f000.grib2 gfs.t${ndate:8:2}z.pgrb2.0p25.f000
  #  ndate=`sh ${syspath}/get_ndate.bash $ndate`
#done


# Gdas
gdasdir="$datdir/gdas/gdas.${sdate:0:8}/${sdate:8:2}"
mkdir -p $gdasdir
cd $gdasdir
ln -sf $gdassource/*.${sdate:0:8}.t${sdate:8:2}z.nr gdas.t${sdate:8:2}z.prepbufr.nr


# Fake Logs
gdasobsscript="cyclelist.gdas_obs.out"
gfsobsscript="cyclelist.gfs_grib2.out"

fileo=$logdir/$gfsobsscript
cat << EOF > $fileo
$sdate Succeed
EOF

fileo=$logdir/$gdasobsscript
cat << EOF > $fileo
$sdate Succeed
EOF



