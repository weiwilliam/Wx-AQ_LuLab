#!/bin/bash
JOBNAME="GEOGRID"
EXE="geogrid.exe"
SCRIPTNAME="${JOBNAME}_runscript"
NP=8
JOBSQUEUE="`which squeue` -u ${USER}"
SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN -np ${NP}"
CKFILE="geogrid.log.0000"

cat > ./${SCRIPTNAME} << EOF
#!/bin/bash
#SBATCH --partition=kratos
#SBATCH --job-name=${JOBNAME}
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=96000
#SBATCH --exclusive
#SBATCH --time=00:15:00
ulimit -s unlimited
$APRUN ${1}/${EXE} > ${JOBNAME}.log 2>&1
EOF

sbatch ${1}/${SCRIPTNAME}

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
   exit 2
fi

#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
