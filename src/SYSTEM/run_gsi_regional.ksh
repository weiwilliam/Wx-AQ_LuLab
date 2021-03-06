#!/bin/bash
set -x
ulimit -s unlimited
#####################################################
# case set up (users should change this part)
#####################################################
#
# ANAL_TIME= analysis time  (YYYYMMDDHH)
# WORK_ROOT= working directory, where GSI runs
# PREPBURF = path of PreBUFR conventional obs
# BK_FILE  = path and name of background file
# OBS_ROOT = path of observations files
# FIX_ROOT = path of fix files
# GSI_EXE  = path and name of the gsi executable 
# ENS_ROOT = path where ensemble background files exist
  ANAL_TIME=${1}
  GRID_ID=${2}
  WORK_ROOT=${3}/gsi
  OBS_ROOT=${3}/dat
  BK_ROOT=${4}
  SYSPATH=${5}
  GSIPATH=${6}  # Default path for GSI of wrf-gsi system on Kratos
  PBFRFILE=${7}
  INCONVF=${8}
  
  JOBNAME="GSI_d0${GRID_ID}"
  case $GRID_ID in
  1) nnodes=1; nprocs=24 ;;
  2) nnodes=4; nprocs=24 ;;
  esac
     
  GSI_ROOT=/network/rit/lab/josephlab/LIN/GSI/comGSIv3.7_EnKFv1.3
  CRTM_ROOT=/network/rit/lab/josephlab/LIN/GSI/CRTM_v2.3.0
  #ENS_ROOT=/network/rit/lab/josephlab/LIN/WORK/GSI/input/gfsens
      #ENS_ROOT is not required if not running hybrid EnVAR 
  YYYY=`echo $ANAL_TIME | cut -c1-4`
  MM=`echo $ANAL_TIME | cut -c5-6`
  DD=`echo $ANAL_TIME | cut -c7-8`
  HH=`echo $ANAL_TIME | cut -c9-10`
  GSI_EXE=${WORK_ROOT}/gsi.x  #assume you have a copy of gsi.x here
  CATEXEC=${WORK_ROOT}/nc_diag_cat.x
  FIX_ROOT=${GSI_ROOT}/fix
  GSI_NAMELIST=${SYSPATH}/create_gsiparm.anl.bash
  #PREPBUFR=${OBS_ROOT}/prepbufr.gdas.${YYYY}${MM}${DD}.t${HH}z.nr
  PREPBUFR=${OBS_ROOT}/${PBFRFILE}
  BK_FILE=${BK_ROOT}/wrfout_d0${GRID_ID}_${YYYY}-${MM}-${DD}_${HH}:00:00
     

  #Job checking tools
  JOBSQUEUE="`which squeue` -u ${USER}"
  SQFORMAT="%.10i %.9P %.25j %.8u %.8T %.10M %.10L %.3D %R"
#
#------------------------------------------------
# bk_core= which WRF core is used as background (NMM or ARW or NMMB)
# bkcv_option= which background error covariance and parameter will be used 
#              (GLOBAL or NAM)
# if_clean = clean  : delete temperal files in working directory (default)
#            no     : leave running directory as is (this is for debug only)
# if_observer = Yes  : only used as observation operater for enkf
# if_hybrid   = Yes  : Run GSI as 3D/4D EnVar
# if_4DEnVar  = Yes  : Run GSI as 4D EnVar
# if_nemsio = Yes    : The GFS background files are in NEMSIO format
# if_oneob  = Yes    : Do single observation test
  if_hybrid=No     # Yes, or, No -- case sensitive !
  if_4DEnVar=No    # Yes, or, No -- case sensitive (set if_hybrid=Yes first)!
  if_observer=No   # Yes, or, No -- case sensitive !
  if_nemsio=No     # Yes, or, No -- case sensitive !
  if_oneob=No      # Yes, or, No -- case sensitive !
  if_ncdiag=Yes

  bk_core=ARW
  bkcv_option=NAM
  if_clean=clean
#
# setup whether to do single obs test
  if [ ${if_oneob} = Yes ]; then
    if_oneobtest='.true.'
  else
    if_oneobtest='.false.'
  fi

#
  if [ ${if_ncdiag} = Yes ]; then
     binary_diag='.false.'
     netcdf_diag='.true.'
     DIAG_SUFFIX='.nc4'
  else
     binary_diag='.true.'
     netcdf_diag='.false.'
     DIAG_SUFFIX=''
  fi

#
# setup for GSI 3D/4D EnVar hybrid
  if [ ${if_hybrid} = Yes ] ; then
    PDYa=`echo $ANAL_TIME | cut -c1-8`
    cyca=`echo $ANAL_TIME | cut -c9-10`
    gdate=`date -u -d "$PDYa $cyca -6 hour" +%Y%m%d%H` #guess date is 6hr ago
    gHH=`echo $gdate |cut -c9-10`
    datem1=`date -u -d "$PDYa $cyca -1 hour" +%Y-%m-%d_%H:%M:%S` #1hr ago
    datep1=`date -u -d "$PDYa $cyca 1 hour"  +%Y-%m-%d_%H:%M:%S`  #1hr later
    if [ ${if_nemsio} = Yes ]; then
      if_gfs_nemsio='.true.'
      ENSEMBLE_FILE_mem=${ENS_ROOT}/gdas.t${gHH}z.atmf006s.mem
    else
      if_gfs_nemsio='.false.'
      ENSEMBLE_FILE_mem=${ENS_ROOT}/sfg_${gdate}_fhr06s_mem
    fi

    if [ ${if_4DEnVar} = Yes ] ; then
      BK_FILE_P1=${BK_ROOT}/wrfout_d01_${datep1}
      BK_FILE_M1=${BK_ROOT}/wrfout_d01_${datem1}

      if [ ${if_nemsio} = Yes ]; then
        ENSEMBLE_FILE_mem_p1=${ENS_ROOT}/gdas.t${gHH}z.atmf009s.mem
        ENSEMBLE_FILE_mem_m1=${ENS_ROOT}/gdas.t${gHH}z.atmf003s.mem
      else
        ENSEMBLE_FILE_mem_p1=${ENS_ROOT}/sfg_${gdate}_fhr09s_mem
        ENSEMBLE_FILE_mem_m1=${ENS_ROOT}/sfg_${gdate}_fhr03s_mem
      fi
    fi
  fi

# The following two only apply when if_observer = Yes, i.e. run observation operator for EnKF
# no_member     number of ensemble members
# BK_FILE_mem   path and base for ensemble members
  no_member=20
  BK_FILE_mem=${BK_ROOT}/wrfarw.mem
#
#
#####################################################
# Users should NOT make changes after this point
#####################################################
#
BYTE_ORDER=Big_Endian
# BYTE_ORDER=Little_Endian

##################################################################################
# Check GSI needed environment variables are defined and exist
#
 
# Make sure ANAL_TIME is defined and in the correct format
if [ ! "${ANAL_TIME}" ]; then
  echo "ERROR: \$ANAL_TIME is not defined!"
  exit 1
fi

# Make sure WORK_ROOT is defined and exists
if [ ! "${WORK_ROOT}" ]; then
  echo "ERROR: \$WORK_ROOT is not defined!"
  exit 1
fi

# Make sure the background file exists
if [ ! -r "${BK_FILE}" ]; then
  echo "ERROR: ${BK_FILE} does not exist!"
  exit 1
fi

# Make sure OBS_ROOT is defined and exists
if [ ! "${OBS_ROOT}" ]; then
  echo "ERROR: \$OBS_ROOT is not defined!"
  exit 1
fi
if [ ! -d "${OBS_ROOT}" ]; then
  echo "ERROR: OBS_ROOT directory '${OBS_ROOT}' does not exist!"
  exit 1
fi

# Set the path to the GSI static files
if [ ! "${FIX_ROOT}" ]; then
  echo "ERROR: \$FIX_ROOT is not defined!"
  exit 1
fi
if [ ! -d "${FIX_ROOT}" ]; then
  echo "ERROR: fix directory '${FIX_ROOT}' does not exist!"
  exit 1
fi

# Set the path to the CRTM coefficients 
if [ ! "${CRTM_ROOT}" ]; then
  echo "ERROR: \$CRTM_ROOT is not defined!"
  exit 1
fi
if [ ! -d "${CRTM_ROOT}" ]; then
  echo "ERROR: fix directory '${CRTM_ROOT}' does not exist!"
  exit 1
fi

# Make sure the GSI executable exists
if [ ! -x "${GSI_EXE}" ]; then
  echo "ERROR: ${GSI_EXE} does not exist!"
  exit 1
fi
#
##################################################################################
# Create the ram work directory and cd into it
workdir=${WORK_ROOT}/d0${GRID_ID}
if [ ! -s $workdir ]; then
   mkdir -p $workdir
fi
cd ${workdir}
mkdir crtm_coeffs
cp $GSI_EXE .
cp $CATEXEC .

#
##################################################################################
# Bring over background field (it's modified by GSI so we can't link to it)
cp ${BK_FILE} ./wrf_inout
if [ ${if_4DEnVar} = Yes ] ; then
  cp ${BK_FILE_P1} ./wrf_inou3
  cp ${BK_FILE_M1} ./wrf_inou1
fi

# Link to the prepbufr data
ln -s ${PREPBUFR} ./prepbufr

# ln -s ${OBS_ROOT}/gdas1.t${HH}z.sptrmm.tm00.bufr_d tmirrbufr
# Link to the radiance data
srcobsfile[1]=${OBS_ROOT}/gdas1.t${HH}z.satwnd.tm00.bufr_d
gsiobsfile[1]=satwnd
srcobsfile[2]=${OBS_ROOT}/gdas1.t${HH}z.1bamua.tm00.bufr_d
gsiobsfile[2]=amsuabufr
srcobsfile[3]=${OBS_ROOT}/gdas1.t${HH}z.1bhrs4.tm00.bufr_d
gsiobsfile[3]=hirs4bufr
srcobsfile[4]=${OBS_ROOT}/gdas1.t${HH}z.1bmhs.tm00.bufr_d
gsiobsfile[4]=mhsbufr
srcobsfile[5]=${OBS_ROOT}/gdas1.t${HH}z.1bamub.tm00.bufr_d
gsiobsfile[5]=amsubbufr
srcobsfile[6]=${OBS_ROOT}/gdas1.t${HH}z.ssmisu.tm00.bufr_d
gsiobsfile[6]=ssmirrbufr
# srcobsfile[7]=${OBS_ROOT}/gdas1.t${HH}z.airsev.tm00.bufr_d
gsiobsfile[7]=airsbufr
srcobsfile[8]=${OBS_ROOT}/gdas1.t${HH}z.sevcsr.tm00.bufr_d
gsiobsfile[8]=seviribufr
srcobsfile[9]=${OBS_ROOT}/gdas1.t${HH}z.iasidb.tm00.bufr_d
gsiobsfile[9]=iasibufr
srcobsfile[10]=${OBS_ROOT}/gdas1.t${HH}z.gpsro.tm00.bufr_d
gsiobsfile[10]=gpsrobufr
srcobsfile[11]=${OBS_ROOT}/gdas1.t${HH}z.amsr2.tm00.bufr_d
gsiobsfile[11]=amsrebufr
srcobsfile[12]=${OBS_ROOT}/gdas1.t${HH}z.atms.tm00.bufr_d
gsiobsfile[12]=atmsbufr
srcobsfile[13]=${OBS_ROOT}/gdas1.t${HH}z.geoimr.tm00.bufr_d
gsiobsfile[13]=gimgrbufr
srcobsfile[14]=${OBS_ROOT}/gdas1.t${HH}z.gome.tm00.bufr_d
gsiobsfile[14]=gomebufr
srcobsfile[15]=${OBS_ROOT}/gdas1.t${HH}z.omi.tm00.bufr_d
gsiobsfile[15]=omibufr
srcobsfile[16]=${OBS_ROOT}/gdas1.t${HH}z.osbuv8.tm00.bufr_d
gsiobsfile[16]=sbuvbufr
srcobsfile[17]=${OBS_ROOT}/gdas1.t${HH}z.eshrs3.tm00.bufr_d
gsiobsfile[17]=hirs3bufrears
srcobsfile[18]=${OBS_ROOT}/gdas1.t${HH}z.esamua.tm00.bufr_d
gsiobsfile[18]=amsuabufrears
srcobsfile[19]=${OBS_ROOT}/gdas1.t${HH}z.esmhs.tm00.bufr_d
gsiobsfile[19]=mhsbufrears
srcobsfile[20]=${OBS_ROOT}/rap.t${HH}z.nexrad.tm00.bufr_d
gsiobsfile[20]=l2rwbufr
srcobsfile[21]=${OBS_ROOT}/rap.t${HH}z.lgycld.tm00.bufr_d
gsiobsfile[21]=larcglb
srcobsfile[22]=${OBS_ROOT}/gdas1.t${HH}z.glm.tm00.bufr_d
gsiobsfile[22]=
ii=1
while [[ $ii -le 21 ]]; do
   if [ -r "${srcobsfile[$ii]}" ]; then
#      ln -s ${srcobsfile[$ii]}  ${gsiobsfile[$ii]}
      echo "link source obs file ${srcobsfile[$ii]}"
   fi
   (( ii = $ii + 1 ))
done

#
##################################################################################

ifhyb=.false.
if [ ${if_hybrid} = Yes ] ; then
  ls ${ENSEMBLE_FILE_mem}* > filelist02
  if [ ${if_4DEnVar} = Yes ] ; then
    ls ${ENSEMBLE_FILE_mem_p1}* > filelist03
    ls ${ENSEMBLE_FILE_mem_m1}* > filelist01
  fi
  
  nummem=`more filelist02 | wc -l`
  nummem=$((nummem -3 ))

  if [[ ${nummem} -ge 5 ]]; then
    ifhyb=.true.
    ${ECHO} " GSI hybrid uses ${ENSEMBLE_FILE_mem} with n_ens=${nummem}"
  fi
fi
if4d=.false.
if [[ ${ifhyb} = .true. && ${if_4DEnVar} = Yes ]] ; then
  if4d=.true.
fi
#
##################################################################################

echo " Copy fixed files and link CRTM coefficient files to working directory"

# Set fixed files
#   berror   = forecast model background error statistics
#   specoef  = CRTM spectral coefficients
#   trncoef  = CRTM transmittance coefficients
#   emiscoef = CRTM coefficients for IR sea surface emissivity model
#   aerocoef = CRTM coefficients for aerosol effects
#   cldcoef  = CRTM coefficients for cloud effects
#   satinfo  = text file with information about assimilation of brightness temperatures
#   satangl  = angle dependent bias correction file (fixed in time)
#   pcpinfo  = text file with information about assimilation of prepcipitation rates
#   ozinfo   = text file with information about assimilation of ozone data
#   errtable = text file with obs error for conventional data (regional only)
#   convinfo = text file with information about assimilation of conventional data
#   lightinfo= text file with information about assimilation of GLM lightning data
#   bufrtable= text file ONLY needed for single obs test (oneobstest=.true.)
#   bftab_sst= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)

if [ ${bkcv_option} = GLOBAL ] ; then
  echo ' Use global background error covariance'
  BERROR=${FIX_ROOT}/${BYTE_ORDER}/nam_glb_berror.f77.gcv
  OBERROR=${FIX_ROOT}/prepobs_errtable.global
  if [ ${bk_core} = NMM ] ; then
     ANAVINFO=${FIX_ROOT}/anavinfo_ndas_netcdf_glbe
  fi
  if [ ${bk_core} = ARW ] ; then
    ANAVINFO=${FIX_ROOT}/anavinfo_arw_netcdf_glbe
  fi
  if [ ${bk_core} = NMMB ] ; then
    ANAVINFO=${FIX_ROOT}/anavinfo_nems_nmmb_glb
  fi
else
  echo ' Use NAM background error covariance'
  BERROR=${FIX_ROOT}/${BYTE_ORDER}/nam_nmmstat_na.gcv
  OBERROR=${FIX_ROOT}/nam_errtable.r3dv
  if [ ${bk_core} = NMM ] ; then
     ANAVINFO=${FIX_ROOT}/anavinfo_ndas_netcdf
  fi
  if [ ${bk_core} = ARW ] ; then
     ANAVINFO=${FIX_ROOT}/anavinfo_arw_netcdf
  fi
  if [ ${bk_core} = NMMB ] ; then
     ANAVINFO=${FIX_ROOT}/anavinfo_nems_nmmb
  fi
fi

# Setup the needed info table for GSI
#CONVINFO=${GSIPATH}/global_convinfo_nysmsfc.txt
CONVINFO=${GSIPATH}/${INCONVF}
SATANGL=${FIX_ROOT}/global_satangbias.txt
SATINFO=${FIX_ROOT}/global_satinfo.txt
OZINFO=${FIX_ROOT}/global_ozinfo.txt
PCPINFO=${FIX_ROOT}/global_pcpinfo.txt
LIGHTINFO=${FIX_ROOT}/global_lightinfo.txt
mesonetuselist=${FIX_ROOT}/nam_mesonet_uselist.txt
mesonet_stnuselist=${FIX_ROOT}/nam_mesonet_stnuselist.txt

#  copy Fixed fields to working directory
 cp $ANAVINFO anavinfo
 cp $BERROR   berror_stats
 cp $SATANGL  satbias_angle
 cp $SATINFO  satinfo
 cp $CONVINFO convinfo
 cp $OZINFO   ozinfo
 cp $PCPINFO  pcpinfo
 cp $LIGHTINFO lightinfo
 cp $OBERROR  errtable
 cp $mesonetuselist mesonetuselist
 cp $mesonet_stnuselist mesonet_stnuselist

#
#    # CRTM Spectral and Transmittance coefficients
CRTM_ROOT_ORDER=${CRTM_ROOT}/${BYTE_ORDER}
emiscoef_IRwater=${CRTM_ROOT_ORDER}/Nalli.IRwater.EmisCoeff.bin
emiscoef_IRice=${CRTM_ROOT_ORDER}/NPOESS.IRice.EmisCoeff.bin
emiscoef_IRland=${CRTM_ROOT_ORDER}/NPOESS.IRland.EmisCoeff.bin
emiscoef_IRsnow=${CRTM_ROOT_ORDER}/NPOESS.IRsnow.EmisCoeff.bin
emiscoef_VISice=${CRTM_ROOT_ORDER}/NPOESS.VISice.EmisCoeff.bin
emiscoef_VISland=${CRTM_ROOT_ORDER}/NPOESS.VISland.EmisCoeff.bin
emiscoef_VISsnow=${CRTM_ROOT_ORDER}/NPOESS.VISsnow.EmisCoeff.bin
emiscoef_VISwater=${CRTM_ROOT_ORDER}/NPOESS.VISwater.EmisCoeff.bin
emiscoef_MWwater=${CRTM_ROOT_ORDER}/FASTEM6.MWwater.EmisCoeff.bin
aercoef=${CRTM_ROOT_ORDER}/AerosolCoeff.bin
cldcoef=${CRTM_ROOT_ORDER}/CloudCoeff.bin

ln -s $emiscoef_IRwater  ./crtm_coeffs/Nalli.IRwater.EmisCoeff.bin
ln -s $emiscoef_IRice    ./crtm_coeffs/NPOESS.IRice.EmisCoeff.bin
ln -s $emiscoef_IRsnow   ./crtm_coeffs/NPOESS.IRsnow.EmisCoeff.bin
ln -s $emiscoef_IRland   ./crtm_coeffs/NPOESS.IRland.EmisCoeff.bin
ln -s $emiscoef_VISice   ./crtm_coeffs/NPOESS.VISice.EmisCoeff.bin
ln -s $emiscoef_VISland  ./crtm_coeffs/NPOESS.VISland.EmisCoeff.bin
ln -s $emiscoef_VISsnow  ./crtm_coeffs/NPOESS.VISsnow.EmisCoeff.bin
ln -s $emiscoef_VISwater ./crtm_coeffs/NPOESS.VISwater.EmisCoeff.bin
ln -s $emiscoef_MWwater  ./crtm_coeffs/FASTEM6.MWwater.EmisCoeff.bin
ln -s $aercoef           ./crtm_coeffs/AerosolCoeff.bin
ln -s $cldcoef           ./crtm_coeffs/CloudCoeff.bin
# Copy CRTM coefficient files based on entries in satinfo file
for file in `awk '{if($1!~"!"){print $1}}' ./satinfo | sort | uniq` ;do
   ln -s ${CRTM_ROOT_ORDER}/${file}.SpcCoeff.bin ./crtm_coeffs/.
   ln -s ${CRTM_ROOT_ORDER}/${file}.TauCoeff.bin ./crtm_coeffs/.
done

# Only need this file for single obs test
 bufrtable=${FIX_ROOT}/prepobs_prep.bufrtable
 cp $bufrtable ./prepobs_prep.bufrtable

# for satellite bias correction
# Users may need to use their own satbias files for correct bias correction
cp ${GSI_ROOT}/fix/comgsi_satbias_in ./satbias_in
cp ${GSI_ROOT}/fix/comgsi_satbias_pc_in ./satbias_pc_in 

#
##################################################################################
# Set some parameters for use by the GSI executable and to build the namelist
echo " Build the namelist "

# default is NAM
#   as_op='1.0,1.0,0.5 ,0.7,0.7,0.5,1.0,1.0,'
vs_op='1.0,'
hzscl_op='0.373,0.746,1.50,'
if [ ${bkcv_option} = GLOBAL ] ; then
#   as_op='0.6,0.6,0.75,0.75,0.75,0.75,1.0,1.0'
   vs_op='0.7,'
   hzscl_op='1.7,0.8,0.5,'
fi
if [ ${bk_core} = NMMB ] ; then
   vs_op='0.6,'
fi

# default is NMM
   bk_core_arw='.false.'
   bk_core_nmm='.true.'
   bk_core_nmmb='.false.'
   bk_if_netcdf='.true.'
if [ ${bk_core} = ARW ] ; then
   bk_core_arw='.true.'
   bk_core_nmm='.false.'
   bk_core_nmmb='.false.'
   bk_if_netcdf='.true.'
fi
if [ ${bk_core} = NMMB ] ; then
   bk_core_arw='.false.'
   bk_core_nmm='.false.'
   bk_core_nmmb='.true.'
   bk_if_netcdf='.false.'
fi

if [ ${if_observer} = Yes ] ; then
  nummiter=0
  if_read_obs_save='.true.'
  if_read_obs_skip='.false.'
else
  nummiter=2
  if_read_obs_save='.false.'
  if_read_obs_skip='.false.'
fi

# Build the GSI namelist on-the-fly
. $GSI_NAMELIST

# modify the anavinfo vertical levels based on wrf_inout for WRF ARW and NMM
if [ ${bk_core} = ARW ] || [ ${bk_core} = NMM ] ; then
bklevels=`ncdump -h wrf_inout | grep "bottom_top =" | awk '{print $3}' `
bklevels_stag=`ncdump -h wrf_inout | grep "bottom_top_stag =" | awk '{print $3}' `
anavlevels=`cat anavinfo | grep ' sf ' | tail -1 | awk '{print $2}' `  # levels of sf, vp, u, v, t, etc
anavlevels_stag=`cat anavinfo | grep ' prse ' | tail -1 | awk '{print $2}' `  # levels of prse
sed -i 's/ '$anavlevels'/ '$bklevels'/g' anavinfo
sed -i 's/ '$anavlevels_stag'/ '$bklevels_stag'/g' anavinfo
fi

#
###################################################
#  run  GSI
###################################################
echo ' Run GSI with' ${bk_core} 'background'

MPIRUN=`which mpirun`
APRUN="/usr/bin/time $MPIRUN"
cat > ./gsirunscript << EOF
#!/bin/bash
#SBATCH --partition=kratos
#SBATCH --job-name=${JOBNAME}
#SBATCH --nodes=${nnodes}
#SBATCH --ntasks-per-node=${nprocs}
#SBATCH --mem=96000
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --output=${workdir}/gsirun.log

ulimit -s unlimited
$APRUN ${workdir}/gsi.x > stdout 2>&1
EOF

sbatch $workdir/gsirunscript

sqrc=0 
until [ $sqrc -ne 0 ] 
do   
    $JOBSQUEUE -o "${SQFORMAT}" | grep "$JOBNAME"
    sqrc=$?   
    sleep 30 
done
##################################################################
#  run time error check
##################################################################

error=0
if [ ! -s ./stdout ]; then
   error=1
else
   grep "GSI_ANL HAS ENDED" ./stdout
   error=$?
fi

if [ ${error} -ne 0 ]; then
  echo "ERROR: GSI crashed  Exit status=${error}"
  exit ${error}
fi

#
##################################################################
#
# GSI updating satbias_in (only for cycling assimilation)

# Copy the output to more understandable names
ln -s stdout      stdout.anl.${ANAL_TIME}
ln -s wrf_inout   wrfanl.${ANAL_TIME}
ln -s fort.201    fit_p1.${ANAL_TIME}
ln -s fort.202    fit_w1.${ANAL_TIME}
ln -s fort.203    fit_t1.${ANAL_TIME}
ln -s fort.204    fit_q1.${ANAL_TIME}
ln -s fort.207    fit_rad1.${ANAL_TIME}

# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#
cat > ./gsidiag_runscript << EOF
#!/bin/bash
#SBATCH --partition=kratos
#SBATCH --job-name=${JOBNAME}_diag
#SBATCH --output=${workdir}/gsidiag.log
#SBATCH --ntasks=4
#SBATCH --mem=6000
#SBATCH --time=00:15:00

set -x
ulimit -s unlimited

ntype=0

diagtype[0]="conv conv_gps conv_ps conv_pw conv_q conv_sst conv_t conv_tcp conv_uv conv_spd"
diagtype[1]="pcp_ssmi_dmsp pcp_tmi_trmm"
diagtype[2]="sbuv2_n16 sbuv2_n17 sbuv2_n18 sbuv2_n19 gome_metop-a gome_metop-b omi_aura mls30_aura ompsnp_npp ompstc8_npp gome_metop-c"
diagtype[3]="hirs2_n14 msu_n14 sndr_g08 sndr_g11 sndr_g12 sndr_g13 sndr_g08_prep sndr_g11_prep sndr_g12_prep sndr_g13_prep sndrd1_g11 sndrd2_g11 sndrd3_g11 sndrd4_g11 sndrd1_g12 sndrd2_g12 sndrd3_g12 sndrd4_g12 sndrd1_g13 sndrd2_g13 sndrd3_g13 sndrd4_g13 sndrd1_g14 sndrd2_g14 sndrd3_g14 sndrd4_g14 sndrd1_g15 sndrd2_g15 sndrd3_g15 sndrd4_g15 hirs3_n15 hirs3_n16 hirs3_n17 amsua_n15 amsua_n16 amsua_n17 amsub_n15 amsub_n16 amsub_n17 hsb_aqua airs_aqua amsua_aqua imgr_g08 imgr_g11 imgr_g12 imgr_g14 imgr_g15 ssmi_f13 ssmi_f15 hirs4_n18 hirs4_metop-a amsua_n18 amsua_metop-a mhs_n18 mhs_metop-a amsre_low_aqua amsre_mid_aqua amsre_hig_aqua ssmis_f16 ssmis_f17 ssmis_f18 ssmis_f19 ssmis_f20 iasi_metop-a hirs4_n19 amsua_n19 mhs_n19 seviri_m08 seviri_m09 seviri_m10 seviri_m11 cris_npp cris-fsr_npp cris-fsr_n20 atms_npp atms_n20 hirs4_metop-b amsua_metop-b mhs_metop-b iasi_metop-b avhrr_metop-b avhrr_n18 avhrr_n19 avhrr_metop-a amsr2_gcom-w1 gmi_gpm saphir_meghat ahi_himawari8 abi_g16 abi_g17 amsua_metop-c mhs_metop-c iasi_metop-c avhrr_metop-c"

numfile[0]=0
numfile[1]=0
numfile[2]=0
numfile[3]=0

prefix="pe*"

error=0
loops="01 03"
for loop in \$loops; do
   case \$loop in
     01) string=ges;;
     03) string=anl;;
      *) string=\$loop;;
   esac
   echo \$(date) START loop \$string >&2
   n=-1
   while [ \$((n+=1)) -le \$ntype ] ;do
      for type in \$(echo \${diagtype[n]}); do
         count=\$(ls \${prefix}\${type}_\${loop}* 2>/dev/null | wc -l)
         if [ \$count -gt 1 ]; then
            if [ $binary_diag = ".true." ]; then
               cat \${prefix}\${type}_\${loop}* > diag_\${type}_\${string}.d0${GRID_ID}.${ANAL_TIME}${DIAG_SUFFIX}
               error=\$?
            else
               $MPIRUN $CATEXEC -o diag_\${type}_\${string}.d0${GRID_ID}.${ANAL_TIME}${DIAG_SUFFIX} \${prefix}\${type}_\${loop}*
               error=\$?
            fi
            numfile[n]=\$(expr \${numfile[n]} + 1)
         elif [ \$count -eq 1 ]; then
            if [ $binary_diag = ".true." ]; then
               cat \${prefix}\${type}_\${loop}* > diag_\${type}_\${string}.d0${GRID_ID}.${ANAL_TIME}${DIAG_SUFFIX}
            else
               mv \${prefix}\${type}_\${loop}* diag_\${type}_\${string}.d0${GRID_ID}.${ANAL_TIME}${DIAG_SUFFIX}
            fi
            numfile[n]=\$(expr \${numfile[n]} + 1)
         fi
         if [ \$count -eq 0 ]; then
            eroor=1
         elif [ ! -s diag_\${type}_\${string}.d0${GRID_ID}.${ANAL_TIME}${DIAG_SUFFIX} ]; then
            error=2
         fi
      done
   done
   echo \$(date) END loop \$string >&2
done
if [ \$error -ne 0 ]; then
   echo 'cat_gsi_diag fail'
else
   echo 'cat_gsi_diag succeed'
fi 
EOF

sbatch $workdir/gsidiag_runscript

sqrc=0 
until [ $sqrc -ne 0 ] 
do   
    $JOBSQUEUE -o "${SQFORMAT}" | grep "${JOBNAME}_diag"
    sqrc=$?   
    sleep 10 
done

if [ -s ./gsidiag.log ]; then
   grep "cat_gsi_diag succeed" ./gsidiag.log
   error=$?
   if [ $error -ne 0 ]; then
      echo "cat_gsi_diag encountered problem, please check $workdir/gsidiag.log"
      exit $error
   fi
else
   error=1
   echo "$workdir/gsidiag.log doesn't exist"
   exit $error 
fi

#  Clean working directory to save only important files 
#ls -l * > list_run_directory
if [[ ${if_clean} = clean  &&  ${if_observer} != Yes ]]; then
  echo ' Clean working directory after GSI run'
  #rm -f *Coeff.bin     # all CRTM coefficient files
  rm -f pe0*           # diag files on each processor
  rm -f obs_input.*    # observation middle files
  rm -f siganl sigf0?  # background middle files
  rm -f fsize_*        # delete temperal file for bufr size
fi
#
#
#################################################
# start to calculate diag files for each member
#################################################
#
#if [ ${if_observer} = Yes ] ; then
#  string=ges
#  for type in $listall; do
#    count=0
#    if [[ -f diag_${type}_${string}.${ANAL_TIME} ]]; then
#       mv diag_${type}_${string}.${ANAL_TIME} diag_${type}_${string}.ensmean
#    fi
#  done
#  mv wrf_inout wrf_inout_ensmean
#
## Build the GSI namelist on-the-fly for each member
#  nummiter=0
#  if_read_obs_save='.false.'
#  if_read_obs_skip='.true.'
#. $GSI_NAMELIST
#
## Loop through each member
#  loop="01"
#  ensmem=1
#  while [[ $ensmem -le $no_member ]];do
#
#     rm pe0*
#
#     print "\$ensmem is $ensmem"
#     ensmemid=`printf %3.3i $ensmem`
#
## get new background for each member
#     if [[ -f wrf_inout ]]; then
#       rm wrf_inout
#     fi
#
#     BK_FILE=${BK_FILE_mem}${ensmemid}
#     echo $BK_FILE
#     ln -s $BK_FILE wrf_inout
#
##  run  GSI
#     echo ' Run GSI with' ${bk_core} 'for member ', ${ensmemid}
#
#     case $ARCH in
#        'IBM_LSF')
#           ${RUN_COMMAND} ./gsi.x < gsiparm.anl > stdout_mem${ensmemid} 2>&1  ;;
#
#        * )
##          ${RUN_COMMAND} ./gsi.x > stdout_mem${ensmemid} 2>&1 ;;
##      sbatch --reservation root_1 -p kratos -N1 --exclusive --mem=96000 --wrap="/usr/bin/time mpirun -np 8 /network/rit/lab/asrclab/GSI/run/gsi.x > stdout 2>&1" ;;
#       sbatch -p kratos -N1 --exclusive --mem=96000 --wrap="/usr/bin/time mpirun -np 8 ${JOB_DIR}/gsi.x > stdout 2>&1" ;;
#     esac
#
#
##  run time error check and save run time file status
#     error=$?
#
#     if [ ${error} -ne 0 ]; then
#       echo "ERROR: ${GSI} crashed for member ${ensmemid} Exit status=${error}"
#       exit ${error}
#     fi
#
#     ls -l * > list_run_directory_mem${ensmemid}
#
## generate diag files
#
#     for type in $listall; do
#           count=`ls pe*${type}_${loop}* | wc -l`
#        if [[ $count -gt 0 ]]; then
#           cat pe*${type}_${loop}* > diag_${type}_${string}.mem${ensmemid}
#        fi
#     done
#
## next member
#     (( ensmem += 1 ))
#      
#  done
#
#fi

exit 0
