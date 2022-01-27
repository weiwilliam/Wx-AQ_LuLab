#!/bin/bash

rundir=${1}
outdir=${2}
sdate=${3}
firstrun=${4}

mkdir $outdir
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
  #GSI
  cp -f $rundir/gsi/run_gsi_regional.ksh $outdir/.
  cp -f $rundir/gsi/GSI.log $outdir/.
  cp -f $rundir/gsi/comgsi_namelist.sh.soilTQ $outdir/.
  cp -f $rundir/gsi/realtime/wrf_inout $outdir/.
  cp -f $rundir/gsi/realtime/stdout $outdir/.
  cp -f $rundir/gsi/realtime/diag_* $outdir/.
  cp -f $rundir/gsi/realtime/gsiparm.anl $outdir/.
  cp -f $rundir/gsi/realtime/fort.201 $outdir/.
  cp -f $rundir/gsi/realtime/fort.202 $outdir/.
  cp -f $rundir/gsi/realtime/fort.203 $outdir/.
  cp -f $rundir/gsi/realtime/fort.213 $outdir/.
  cp -f $rundir/gsi/realtime/fort.220 $outdir/.
  #LBC
  cp -f $rundir/lbc/parame.in $outdir/.
  cp -f $rundir/lbc/wrfbdy_d01.bu $outdir/.
  cp -f $rundir/lbc/lateralBC.log $outdir/.
fi
