#!/bin/bash
JOBNAME="LBC"
EXE="da_update_bc.exe"
SCRIPTNAME="${JOBNAME}_runscript"
NP=1
JOBSQUEUE="`which squeue` -u ${USER}"
SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN -np ${NP}"

CKFILE="lateralBC.log"

rundir=${1}

cd $rundir/lbc
mv $rundir/wrf/wrfbdy_d01 .
cp -f wrfbdy_d01 wrfbdy_d01.bu
cp -f $rundir/gsi/d01/wrf_inout .


cat > ./${SCRIPTNAME} << EOF
#!/bin/bash
#SBATCH --partition=kratos
#SBATCH --job-name=${JOBNAME}
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=96000
#SBATCH --exclusive
#SBATCH --time=01:00:00
ulimit -s unlimited
$APRUN ${1}/lbc/${EXE} > ${CKFILE} 2>&1
EOF

sbatch ${1}/lbc/${SCRIPTNAME}

#CHECKPOINT
sqrc=0
until [ $sqrc -ne 0 ]
do
    $JOBSQUEUE -o "${SQFORMAT}" | grep "$JOBNAME"
    sqrc=$?
    sleep 30
done

grep -i "Successful" $CKFILE >> ${JOBNAME}.log
ckrc=$?
if [ $ckrc -eq 1 ]
then
    echo Error: Unsuccessfuly run of ${JOBNAME}.
    exit 7
fi

cp wrfbdy_d01 $rundir/wrf/.


#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
