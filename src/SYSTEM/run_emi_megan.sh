#!/bin/bash
partition=$2
JOBNAME="MEGAN"
EXE="megan_bio_emiss"
SCRIPTNAME="${JOBNAME}_runscript"
NP=1
JOBSQUEUE="`which squeue` -u ${USER}"
SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN -np ${NP}"
CKFILE="megan_bio_emiss.out"
INP="megan_bio_emiss.inp"
cat > ./${SCRIPTNAME} << EOF
#!/bin/bash
#SBATCH --partition=$partition
#SBATCH --job-name=${JOBNAME}
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=96000
#SBATCH --exclusive
#SBATCH --time=01:00:00
ulimit -s unlimited
$APRUN ${1}/${EXE} < ${INP} > ${JOBNAME}.log 2>&1
rc=\$?
echo \$rc > ./return_code
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

CKFILE="filelist"
sqrc=1
count=0
stopcount=10
until [ $sqrc -ne 1 ]
do
    #ls ./ > ${CKFILE}
    #grep -qi "wrfbiochemi_d02" ${CKFILE} 
    sqrc=`cat ./return_code`
    sleep 20
    count=$((count+1))
    if [ $count -eq $stopcount ]
    then
       echo Error: Timeout ${JOBNAME}.
       exit 20 #use different nonzero number for each script
    fi
done

