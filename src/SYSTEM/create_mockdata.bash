#!/bin/bash
#
# Create mock data folder for LISTOS period
#
#$gfssource $gdassource $datdir $obsdir#logs
set -x

gfssource=${1}
gdassource=${2}
datdir=${3}
logdir=${4}
sdate=${5}
edate=${6}
syspath=${7}

mkdir -p $datdir/gfs
mkdir -p $datdir/gdas
ndate=`sh ${syspath}/get_ndate.bash 6 $sdate`

# GFS Data
gfsdir=$datdir/gfs/gfs.${sdate:0:8}/${sdate:8:2}
mkdir -p $gfsdir
cd $gfsdir
ln -sf $gfssource/gfs.0p25.${sdate}.f000.grib2 gfs.t${sdate:8:2}z.pgrb2.0p25.f000

h=6
until [ $ndate -gt $edate ]
do
    if [ "$h" -lt "10" ]
    then
        ln -sf $gfssource/gfs.0p25.${ndate}.f000.grib2 gfs.t${sdate:8:2}z.pgrb2.0p25.f00"${h}"
    else    
        ln -sf $gfssource/gfs.0p25.${ndate}.f000.grib2 gfs.t${sdate:8:2}z.pgrb2.0p25.f0"${h}"
    fi

    ndate=`sh ${syspath}/get_ndate.bash 6 $ndate`
    h=$(($h + 6))
done


# Gdas
gdasdir="$datdir/gdas/gdas.${sdate:0:8}/${sdate:8:2}"
mkdir -p $gdasdir
cd $gdasdir
ln -sf $gdassource/prepbufr.gdas.${sdate:0:8}.t${sdate:8:2}z.nr* .

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



