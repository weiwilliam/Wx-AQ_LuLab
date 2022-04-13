#!/bin/bash

mozdir=${1}
do_bc=${2}
domain=${3}

fileo=$mozdir/MOZCART_T1_LISTOS.inp
#fileo=$rundir/emi/mozbc/MOZCART_T1_LISTOS.inp
cat << EOF > $fileo 


&control
do_bc     = $do_bc
do_ic     = .true.
domain    = $domain
dir_wrf = '$mozdir/'
dir_moz = '$mozdir/'
fn_moz  = 'h0001.nc'
def_missing_var = .true.
moz_var_suffix = ''

spc_map = 'o3 -> O3',  'n2o -> N2O', 'no -> NO',
          'no2 -> NO2', 'no3 -> NO3', 'nh3 -> NH3', 'hno3 -> HNO3', 'hno4 -> HO2NO2',
          'n2o5 -> N2O5',  'ho -> OH', 'ho2 -> HO2', 'h2o2 -> H2O2',
          'ch4 -> CH4', 'co -> CO',  'ch3ooh -> CH3OOH',
          'hcho -> CH2O', 'ch3oh -> CH3OH', 'c2h4 -> C2H4',
          'ald -> CH3CHO', 'ch3cooh -> CH3COOH', 'acet -> CH3COCH3', 'mgly -> CH3COCHO',
          'gly -> GLYOXAL',
          'pan -> PAN', 'mpan -> MPAN', 'macr -> MACR',
          'mvk -> MVK', 'c2h6 -> C2H6', 'c3h6 -> C3H6', 'c3h8 -> C3H8',
          'c2h5oh -> C2H5OH',  'c10h16 -> MTERP',
          'onitr -> ONITR', 'isopr -> ISOP',
          'acetol -> HYAC', 'mek -> MEK',
          'bigene -> BIGENE', 'open -> BIGALD', 'bigalk -> BIGALK',
          'tol -> TOLUENE', 'benzene -> BENZENE ', 'xylenes -> XYLENES',
          'cres -> CRESOL', 'dms -> DMS', 'so2 -> SO2',
          'BC1 -> 1.0*bc_a4;1.e9', 'BC2 -> 1.0*bc_a1;1.e9',
          'OC1 -> 1.0*pom_a4;1.e9','OC2 -> 1.0*pom_a1;1.e9',
          'SEAS_1 -> 1.0*ncl_a1+1.0*ncl_a2;1.e9',
          'SEAS_2 -> 0.5*ncl_a3;1.e9',
          'SEAS_3 -> 0.5*ncl_a3;1.e9',
          'SEAS_4 -> 0.0*ncl_a3;1.e9'
          'DUST_1 -> 0.02*dst_a3;1.e9',
          'DUST_2 -> 0.93*dst_a3;1.e9',
          'DUST_3 -> 0.05*dst_a3;1.e9',
          'DUST_4 -> 0.0*dst_a3;1.e9',
          'DUST_5 -> 0.0*dst_a3;1.e9'
/

EOF
