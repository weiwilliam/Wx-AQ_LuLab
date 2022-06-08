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

#fire_directory = '/network/rit/lab/lulab/share_lib/WRF/Prep_EM/FINN/data_files/',
#fire_filename  = 'GLOBAL_FINNv15_2018_MOZART_01022019.txt',



fileo=$rundir/emi/fire/fire_emis_MOZCART_T1.inp
cat << EOF > $fileo 

&control
domains        = 2,
fire_directory = '$rundir/emi/fire/',
fire_filename  = 'GLOB_MOZ4_previousday.txt',
wrf_directory  = '$rundir/wrf/'
start_date     = '${syear}-${smon}-${sday}',
end_date       = '${eyear}-${emon}-${eday}',
diag_level     = 400,

wrf2fire_map = 'co -> CO',
               'no -> NO',
               'so2 -> SO2',
               'bigalk -> BIGALK',
               'bigene -> BIGENE',
               'c2h4 -> C2H4',
               'c2h5oh -> C2H5OH',
                   'c2h6 -> C2H6',
               'c3h8 -> C3H8',
               'c3h6 -> C3H6',
               'ch2o -> CH2O',
               'ch3cho -> CH3CHO',
                   'ch3coch3 -> CH3COCH3',
               'ch3oh -> CH3OH',
               'mek -> MEK',
               'toluene ->0.33* TOLUENE',
               'benzene ->0.33* TOLUENE',
               'xylenes-> 0.33*TOLUENE','xylene->0.33*TOLUENE',
                   'nh3 -> NH3','no2 -> NO2','open -> BIGALD','c10h16 -> C10H16',
               'ch3cooh -> CH3COOH','cres -> CRESOL','glyald -> GLYALD','mgly -> CH3COCHO',
               'acetol -> HYAC','isop -> ISOP','macr -> MACR'
               'mvk -> MVK','apin -> C10H16','ch3cn -> CH3CN','hcn -> HCN','hcooh -> HCOOH','c2h2 -> C2H2',
               'sulf -> -0.01*PM25 + 0.02*PM10;aerosol',
               'oc->1.4*OC;aerosol',
               'bc->BC;aerosol',
               'pm25->PM25 + -1.*OC + -1.*BC;aerosol'
               'pm10->PM10 + -1.*PM25;aerosol'


/
EOF
