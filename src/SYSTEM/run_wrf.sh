#!/bin/bash
partition=$2
JOBNAME="WRF"
EXE="wrf.exe"
SCRIPTNAME="${JOBNAME}_runscript"
JOBSQUEUE="`which squeue` -u ${USER}"
SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN"
CKFILE="rsl.error.0000"
case $partition in
'batch') NP=32 ;;
'kratos') NP=28 ;;
esac
export WRFIO_NCD_LARGE_FILE_SUPPORT=1

cat > ./${SCRIPTNAME} << EOF
#!/bin/bash
#SBATCH --partition=$partition
#SBATCH --job-name=${JOBNAME}
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=${NP}
#SBATCH --mem=96000
#SBATCH --exclusive
#SBATCH --time=10:00:00
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
    sleep 60
done

grep -i "SUCCESS" $CKFILE >> ${JOBNAME}.log
ckrc=$?
if [ $ckrc -ne 0 ]
then
    echo Error: Unsuccessfuly run of ${JOBNAME}.
    exit 8
fi

#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 /network/rit/home/dg771199/WRF-GSI/src/WPS/geogrid.exe"
#sbatch -p kratos -N1 --exclusive --mem=28000 --wrap="/usr/bin/time mpirun -np 14 ${1}/geogrid.exe"
