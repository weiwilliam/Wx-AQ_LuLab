#!/bin/bash
# clean up the run and archive folder when it's realtime run
p_rundir=${1}
p_outdir=${2}

if [ -d $p_rundir ]; then
 echo "Removing $p_rundir"
 rm -rf $p_rundir
else
 echo "$p_rundir not exist"
fi
if [ -d $p_outdir ]; then
 echo "Removing $p_outdir"
 rm -rf $p_outdir
else
 echo "$p_outdir not exist"
fi

exit 0
