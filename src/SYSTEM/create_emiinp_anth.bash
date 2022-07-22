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
run_dom=$4

fileo=$rundir/emi/anth/anthro_emis_2018_12km_MOZCART_T1.inp
cat << EOF > $fileo 
&CONTROL
 anthro_dir = '/network/rit/lab/lulab/chinan/WRF/Emission/Anthro/EPA_Anthro/EPA_2018/12km'
 wrf_dir = '$rundir/wrf'
 src_lon_dim_name = 'COL'
 src_lat_dim_name = 'ROW'
 domains = $run_dom
 cat_var_prefix = ' '
 output_interval = 3600
 diag_level=100

 sec_file_prefix = 'emis_mole_'
 sec_file_suffix = '_12US1_nobeis_2018ff_18j_WR401.ncf'

 stk_file_prefix = 'inln_mole_'
 stk_file_suffix = '_12US1_cmaq_cb6_2018ff_18j_WR401.ncf'
 stk_grp_file_suffix = '_12US1_2018ff_18j_WR401.ncf'

 src_names(1:6) = 'all:epa-sector','cmv_c3:epa-stack','othpt:epa-stack','ptegu:epa-stack','ptnonipm:epa-stack','pt_oilgas:epa-stack'

 sub_categories(1:10)   = 'CO','NO','NO2','SO2','NH3','ETOH','PAR','IOLE','ETH','ETHA'
 sub_categories(11:20)  = 'OLE','PRPA','FORM','ALD2','ALDX','ACET','MEOH','KET','TOL','BENZ'
 sub_categories(21:27)  = 'XYLMN','ISOP','TERP','SULF','ETHY','HONO','ACROLEIN'
 sub_categories(28:34)  = 'PMOTHR','PEC','POC','PMC','PSO4','PNO3','PNH4'


 start_output_time = '2018-${smon}-${sday}_${shr}:00:00'
 stop_output_time  = '2018-${emon}-${eday}_${ehr}:00:00'
 emissions_zdim_stag = 10


 emis_map(1) = 'CO->all(CO)+cmv_c3(CO)+othpt(CO)+ptegu(CO)+ptnonipm(CO)+pt_oilgas(CO)'
 emis_map(2) = 'NO->all(NO)+cmv_c3(NO)+othpt(NO)+ptegu(NO)+ptnonipm(NO)+pt_oilgas(NO)'
 emis_map(3) = 'NO2->all(NO2)+cmv_c3(NO2)+othpt(NO2)+ptegu(NO2)+ptnonipm(NO2)+pt_oilgas(NO2)'
 emis_map(4) = 'SO2->all(SO2)+cmv_c3(SO2)+othpt(SO2)+ptegu(SO2)+ptnonipm(SO2)+pt_oilgas(SO2)'
 emis_map(5) = 'NH3->all(NH3)+cmv_c3(NH3)+othpt(NH3)+ptegu(NH3)+ptnonipm(NH3)+pt_oilgas(NH3)'
 emis_map(6) = 'C2H5OH->all(ETOH)+cmv_c3(ETOH)+othpt(ETOH)+ptegu(ETOH)+ptnonipm(ETOH)+pt_oilgas(ETOH)'
 emis_map(7) = 'BIGALK->.2*all(PAR)+.2*cmv_c3(PAR)+.2*othpt(PAR)+.2*ptegu(PAR)+.2*ptnonipm(PAR)+.2*pt_oilgas(PAR)'
 emis_map(8) = 'BIGENE->all(IOLE)+cmv_c3(IOLE)+othpt(IOLE)+ptegu(IOLE)+ptnonipm(IOLE)+pt_oilgas(IOLE)'
 emis_map(9) = 'C2H4->all(ETH)+cmv_c3(ETH)+othpt(ETH)+ptegu(ETH)+ptnonipm(ETH)+pt_oilgas(ETH)'
 emis_map(10) = 'C2H6->all(ETHA)+cmv_c3(ETHA)+othpt(ETHA)+ptegu(ETHA)+ptnonipm(ETHA)+pt_oilgas(ETHA)'
 emis_map(11) = 'C3H6->all(OLE)+cmv_c3(OLE)+othpt(OLE)+ptegu(OLE)+ptnonipm(OLE)+pt_oilgas(OLE)'
 emis_map(12) = 'C3H8->all(PRPA)+cmv_c3(PRPA)+othpt(PRPA)+ptegu(PRPA)+ptnonipm(PRPA)+pt_oilgas(PRPA)'
 emis_map(13) = 'CH2O->all(FORM)+cmv_c3(FORM)+othpt(FORM)+ptegu(FORM)+ptnonipm(FORM)+pt_oilgas(FORM)'
 emis_map(14) = 'CH3CHO->all(ALD2+ALDX)+cmv_c3(ALD2+ALDX)+othpt(ALD2+ALDX)+ptegu(ALD2+ALDX)+ptnonipm(ALD2+ALDX)+pt_oilgas(ALD2+ALDX)'
 emis_map(15) = 'CH3COCH3->all(ACET)+cmv_c3(ACET)+othpt(ACET)+ptegu(ACET)+ptnonipm(ACET)+pt_oilgas(ACET)'
 emis_map(16) = 'CH3OH->all(MEOH)+cmv_c3(MEOH)+othpt(MEOH)+ptegu(MEOH)+ptnonipm(MEOH)+pt_oilgas(MEOH)'
 emis_map(17) = 'MEK->all(KET)+cmv_c3(KET)+othpt(KET)+ptegu(KET)+ptnonipm(KET)+pt_oilgas(KET)'
 emis_map(18) = 'TOLUENE->all(TOL)+cmv_c3(TOL)+othpt(TOL)+ptegu(TOL)+ptnonipm(TOL)+pt_oilgas(TOL)'
 emis_map(19) = 'BENZENE->all(BENZ)+cmv_c3(BENZ)+othpt(BENZ)+ptegu(BENZ)+ptnonipm(BENZ)+pt_oilgas(BENZ)'
 emis_map(20) = 'XYLENE->all(XYLMN)+cmv_c3(XYLMN)+othpt(XYLMN)+ptegu(XYLMN)+ptnonipm(XYLMN)+pt_oilgas(XYLMN)'
 emis_map(21) = 'ISOP->all(ISOP)+cmv_c3(ISOP)+othpt(ISOP)+ptegu(ISOP)+ptnonipm(ISOP)+pt_oilgas(ISOP)'
 emis_map(22) = 'C10H16->all(TERP)+cmv_c3(TERP)+othpt(TERP)+ptegu(TERP)+ptnonipm(TERP)+pt_oilgas(TERP)'
 emis_map(23) = 'sulf->all(SULF)+cmv_c3(SULF)+othpt(SULF)+ptegu(SULF)+ptnonipm(SULF)+pt_oilgas(SULF)'
 emis_map(24) = 'C2H2->all(ETHY)+cmv_c3(ETHY)+othpt(ETHY)+ptegu(ETHY)+ptnonipm(ETHY)+pt_oilgas(ETHY)'
 emis_map(25) = 'PM_25(A)->all(PMOTHR)+cmv_c3(PMOTHR)+othpt(PMOTHR)+ptegu(PMOTHR)+ptnonipm(PMOTHR)+pt_oilgas(PMOTHR)'
 emis_map(26) = 'BC(A)->all(PEC)+cmv_c3(PEC)+othpt(PEC)+ptegu(PEC)+ptnonipm(PEC)+pt_oilgas(PEC)'
 emis_map(27) = 'OC(A)->all(POC)+cmv_c3(POC)+othpt(POC)+ptegu(POC)+ptnonipm(POC)+pt_oilgas(POC)'
 emis_map(28) = 'PM_10(A)->all(PMC)+cmv_c3(PMC)+othpt(PMC)+ptegu(PMC)+ptnonipm(PMC)+pt_oilgas(PMC)'
 emis_map(29) = 'SO4I(A)->.15*all(PSO4)+.15*cmv_c3(PSO4)+.15*othpt(PSO4)+.15*ptegu(PSO4)+.15*ptnonipm(PSO4)+.15*pt_oilgas(PSO4)'
 emis_map(30) = 'SO4J(A)->.85*all(PSO4)+.85*cmv_c3(PSO4)+.85*othpt(PSO4)+.85*ptegu(PSO4)+.85*ptnonipm(PSO4)+.85*pt_oilgas(PSO4)'
 emis_map(31) = 'ECI(A)->.15*all(PEC)+.15*cmv_c3(PEC)+.15*othpt(PEC)+.15*ptegu(PEC)+.15*ptnonipm(PEC)+.15*pt_oilgas(PEC)'
 emis_map(32) = 'ECJ(A)->.85*all(PEC)+.85*cmv_c3(PEC)+.85*othpt(PEC)+.85*ptegu(PEC)+.85*ptnonipm(PEC)+.85*pt_oilgas(PEC)'
 emis_map(33) = 'ORGI(A)->.15*all(POC)+.15*cmv_c3(POC)+.15*othpt(POC)+.15*ptegu(POC)+.15*ptnonipm(POC)+.15*pt_oilgas(POC)'
 emis_map(34) = 'ORGJ(A)->.85*all(POC)+.85*cmv_c3(POC)+.85*othpt(POC)+.85*ptegu(POC)+.85*ptnonipm(POC)+.85*pt_oilgas(POC)'
 emis_map(35) = 'NO3I(A)->.15*all(PNO3)+.15*cmv_c3(PNO3)+.15*othpt(PNO3)+.15*ptegu(PNO3)+.15*ptnonipm(PNO3)+.15*pt_oilgas(PNO3)'
 emis_map(36) = 'NO3J(A)->.85*all(PNO3)+.85*cmv_c3(PNO3)+.85*othpt(PNO3)+.85*ptegu(PNO3)+.85*ptnonipm(PNO3)+.85*pt_oilgas(PNO3)'
 emis_map(37) = 'NH4I(A)->.15*all(PNH4)+.15*cmv_c3(PNH4)+.15*othpt(PNH4)+.15*ptegu(PNH4)+.15*ptnonipm(PNH4)+.15*pt_oilgas(PNH4)'
 emis_map(38) = 'NH4J(A)->.85*all(PNH4)+.85*cmv_c3(PNH4)+.85*othpt(PNH4)+.85*ptegu(PNH4)+.85*ptnonipm(PNH4)+.85*pt_oilgas(PNH4)'
 emis_map(39) = 'HONO->all(HONO)+cmv_c3(HONO)+othpt(HONO)+ptegu(HONO)+ptnonipm(HONO)+pt_oilgas(HONO)'
 emis_map(40) = 'MACR->all(ACROLEIN)+ptegu(ACROLEIN)+ptnonipm(ACROLEIN)+pt_oilgas(ACROLEIN)'
/


EOF
