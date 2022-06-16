#!/bin/bash
JOBNAME="ANTH"
EXE="anthro_emis"
SCRIPTNAME="${JOBNAME}_runscript"
NP=1
JOBSQUEUE="`which squeue` -u ${USER}"
SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN -np ${NP}"
CKFILE="anthro_emis.out"
#INP="anthro_emis_2018_12km_MOZCART_T1.inp"
INP=${2}

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
export WRFIO_NCD_LARGE_FILE_SUPPORT=1

$APRUN ${1}/${EXE} < ${INP} > ${CKFILE} 2>&1
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


grep -i "successful" $CKFILE >> ${JOBNAME}.log
ckrc=$?
if [ $ckrc -eq 1 ]
then
   echo Error: Unsuccessfuly run of ${JOBNAME}.
   exit 21
fi

