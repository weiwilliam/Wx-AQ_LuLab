#!/bin/bash

rundir=${1}
syear=${2:0:4}
smon=${2:4:2}
sday=${2:6:2}
shr=${2:8:2}
eyear=${3:0:4}
emon=${3:4:2}
eday=${3:6:2}
ehr=${3:8:2}
wpspath=${4}
chem_bc=$5

case $chem_bc in
1) max_dom=2 ;;
2) max_dom=1 ;;
*) ;;
esac

fileo=$rundir/wps/namelist.wps
if [ -s $fileo ]; then
   rm $fileo
fi
cat << EOF > $fileo 
&share
 wrf_core = 'ARW',
 max_dom = ${max_dom},
 start_date = '${syear}-${smon}-${sday}_${shr}:00:00','${syear}-${smon}-${sday}_${shr}:00:00',
 end_date   = '${eyear}-${emon}-${eday}_${ehr}:00:00','${eyear}-${emon}-${eday}_${ehr}:00:00',
 interval_seconds = 21600,
 io_form_geogrid = 2,
/


&geogrid
 parent_id         =   1,   1,    2,
 parent_grid_ratio =   1,   3,    3,
 i_parent_start    =   1,  111,  111,
 j_parent_start    =   1,  94,  54,
 e_we              =  240, 265, 319,
 e_sn              =  220, 223, 319,
 !
 !!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!
 ! The default datasets used to produce the MAXSNOALB and ALBEDO12M
 ! fields have changed in WPS v4.0. These fields are now interpolated
 ! from MODIS-based datasets.
 !
 ! To match the output given by the default namelist.wps in WPS v3.9.1,
 ! the following setting for geog_data_res may be used:
 !
 ! geog_data_res = 'maxsnowalb_ncep+albedo_ncep+default', 'maxsnowalb_ncep+albedo_ncep+default',
 !
 !!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!
 !
 geog_data_res = 'modis_30s+30s', 'modis_30s+30s',  'modis_30s+30s',
 dx = 12000,
 dy = 12000,
 map_proj = 'lambert',
 ref_lat   =  40.00,
 ref_lon   =  -80.00,
 truelat1  =  33.0,
 truelat2  =  45.0,
 stand_lon =  -97.0,
 geog_data_path = '/network/rit/lab/lulab/WRF-GSI/geog/',
 OPT_GEOGRID_TBL_PATH = '$wpspath/geogrid/'
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE',
 io_form_metgrid = 2,
 OPT_METGRID_TBL_PATH = '$wpspath/metgrid/'
/
EOF
