#!/bin/bash

rundir=${1}
outdir=${2}
sdate=${3}
pdate=${4}
firstrun=${5}
da_doms=${6}
da_doms=`echo $da_doms | sed -e 's/_/ /g'`

if [ -d $outdir ]
then
 echo "Warning: $outdir already exists, overwriting... "
else
  mkdir $outdir
fi

#WPS
cp -f $rundir/wps/geo_em.* $outdir/.
cp -f $rundir/wps/met_em.* $outdir/.
cp -f $rundir/wps/metgrid.log.0000 $outdir/.
cp -f $rundir/wps/UNGRIB.log $outdir/.
cp -f $rundir/wps/namelist.wps $outdir/.
#WRF
cp -f $rundir/wrf/wrfout_* $outdir/.
cp -f $rundir/wrf/wrfinput_* $outdir/.
cp -f $rundir/wrf/wrfbdy_* $outdir/.
cp -f $rundir/wrf/namelist.input $outdir/.
if [ $firstrun -eq 0 ]
then
  for dom in $da_doms
  do
     #GSI
     #cp -f $rundir/gsi/GSI.log $outdir/.
     cp -f $rundir/gsi/d0$dom/wrf_inout $outdir/wrf_inout_d0${dom}
     cp -f $rundir/gsi/d0$dom/stdout $outdir/stdout_d0${dom}
     cp -f $rundir/gsi/d0$dom/diag_* $outdir/.
     cp -f $rundir/gsi/d0$dom/gsiparm.anl $outdir/gsiparm_d0${dom}.anl
     cp -f $rundir/gsi/d0$dom/gsistat.d0${dom}.$sdate $outdir/gsistat.d0${dom}.$sdate
  done
  #LBC
  cp -f $rundir/lbc/parame.in $outdir/.
  cp -f $rundir/lbc/wrfbdy_d01.bu $outdir/.
  cp -f $rundir/lbc/lateralBC.log $outdir/.
fi
