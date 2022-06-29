#!/bin/bash

#syspath="$topdir/src/SYSTEM"
#source $syspath/env.sh
sdate=${1}
img_path=${2}
out_path=${3}
export QT_QPA_PLATFORM='offscreen'
export SDATE=$sdate
export IMG_PATH=${IMG_PATH:-${img_path}/wrfgsi.plot.$sdate}
if [ ! -d $IMG_PATH ]; then
   mkdir -p $IMG_PATH
fi
export OUT_PATH=${OUT_PATH:-$out_path/wrfgsi.out.$sdate}
#which python
python3 spa_O3_PM25_NYS_hr.py 
