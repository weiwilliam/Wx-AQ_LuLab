export PS1="\w->"
export INTEL_LICENSE_FILE=/network/rit/lab/asrclab/opt/intel/licenses
export ASRC_SOFTWARE="/network/rit/lab/asrclab/soft"
export ASRC_VIZ="/network/rit/lab/asrclab/viz"
export INTEL_BASE="/network/rit/lab/asrclab/opt/intel/install/compilers_and_libraries_2016.3.210"
#export PATH=".:/~/perl5:${ASRC_SOFTWARE}/bin:/network/rit/lab/asrclab/soft/python2/bin:${ASRC_VIZ}/ncl/bin:$PATH"
export PATH=".:/~/perl5:${ASRC_SOFTWARE}/bin:/network/rit/lab/asrclab/soft/python3/bin:${ASRC_VIZ}/ncl/bin:$PATH"
export NETCDF=${ASRC_SOFTWARE}
export LAPACK_PATH=/network/rit/lab/asrclab/opt/intel/install/compilers_and_libraries_2016.3.210/linux/mkl/lib/intel64
export JASPERLIB=${ASRC_SOFTWARE}/lib
export JASPERINC=${ASRC_SOFTWARE}/include
export PYTHONPATH="/network/rit/lab/asrclab/soft/python3/lib/python3.6/site-packages"
#export PYTHONPATH="/network/rit/lab/asrclab/soft/python2/lib/python2.7/site-packages"
source /network/rit/lab/asrclab/opt/intel/install/parallel_studio_xe_2016.3.067/bin/psxevars.sh > /dev/null
source ${I_MPI_ROOT}/intel64/bin/mpivars.sh release
# For Intel Math Kernel Library (MKL)
# To utilize built in libraries like LAPACK and BLAS
source ${INTEL_BASE}/linux/mkl/bin/mklvars.sh intel64
##$MKLROOT/lib/intel64_lin
export I_MPI_CC=icc
export LD_LIBRARY_PATH="${ASRC_SOFTWARE}/lib:${ASRC_SOFTWARE}/ESMF/lib:${ASRC_SOFTWARE}/NCEP/lib:$LD_LIBRARY_PATH"
export NCARG_ROOT=/network/rit/lab/asrclab/viz/ncl
export PROJ_LIB=/network/rit/lab/asrclab/soft/python3/share/proj

wpsdir = "/network/rit/home/dg771199/WRF-GSI/src/WPS"
wrfdir = "/network/rit/home/dg771199/WRF-GSI/src/WRF"
gsidir = "/network/rit/home/dg771199/WRF-GSI/src/GSI"
datdir = "/network/rit/home/dg771199/WRF-GSI/dat"

sh $wpddir/run_megrid.sh # works!

.$wpsdir/link_grib.csh $datdir/
sh $wpsdir/run_ungrib.sh

sh $wpsdir/run_metgrid.sh
ls -sf $wpsdir/met_em* $wrdir/


