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

fileo=$rundir/emi/anth/anthro_emis_2018_4km_MOZCART_T1.inp
cat << EOF > $fileo
&CONTROL
 anthro_dir = '/network/rit/lab/lulab/chinan/WRF/Emission/Anthro/EPA_Anthro/EPA_2018/4km'
 wrf_dir    = '$rundir/wrf'
 src_lon_dim_name = 'COL'
 src_lat_dim_name = 'ROW'
 domains = 2
 cat_var_prefix = ' '
 output_interval = 3600
 diag_level = 100

 sec_file_prefix = 'emis_mole_'
 sec_file_suffix = '_4LISTOS1_nobeis_withrwc_2018ff_18j_WR401_fine.ncf'

 stk_file_prefix = 'inln_mole_'
 stk_file_suffix = '_4LISTOS1_cmaq_cb6_2018ff_18j_WR401_fine.ncf'
 stk_grp_file_suffix = '_4LISTOS1_2018ff_18j_WR401_fine.ncf'

 src_names(1:6) = 'all:epa-sector','cmv_c3_4:epa-stack','cmv_c1c2_4:epa-stack','othpt_solv:epa-stack','othpt_nosolv:epa-stack','ptegu:epa-stack'
 src_names(7:8) = 'ptnonipm_solv:epa-stack','ptnonipm_nosolv:epa-stack'
 src_names(9:10) = 'pt_oilgas_solv:epa-stack','pt_oilgas_nosolv:epa-stack'

 sub_categories(1:10)   = 'CO','NO','NO2','SO2','NH3','ETOH','PAR','IOLE','ETH','ETHA'
 sub_categories(11:20)  = 'OLE','PRPA','FORM','ALD2','ALDX','ACET','MEOH','KET','TOL','BENZ'
 sub_categories(21:27)  = 'XYLMN','ISOP','TERP','SULF','ETHY','HONO','ACROLEIN'
 sub_categories(28:34)  = 'PMOTHR','PEC','POC','PMC','PSO4','PNO3','PNH4'

 start_output_time = '2018-${smon}-${sday}_${shr}:00:00'
 stop_output_time  = '2018-${emon}-${eday}_${ehr}:00:00'
 emissions_zdim_stag = 10


 emis_map(1) = 'CO->all(CO)+cmv_c3_4(CO)+cmv_c1c2_4(CO)+othpt_solv(CO)+othpt_nosolv(CO)+ptegu(CO)+ptnonipm_solv(CO)+ptnonipm_nosolv(CO)+pt_oilgas_solv(CO)+pt_oilgas_nosolv(CO)'
 emis_map(2) = 'NO->all(NO)+cmv_c3_4(NO)+cmv_c1c2_4(NO)+othpt_solv(NO)+othpt_nosolv(NO)+ptegu(NO)+ptnonipm_solv(NO)+ptnonipm_nosolv(NO)+pt_oilgas_solv(NO)+pt_oilgas_nosolv(NO)'
 emis_map(3) = 'NO2->all(NO2)+cmv_c3_4(NO2)+cmv_c1c2_4(NO2)+othpt_solv(NO2)+othpt_nosolv(NO2)+ptegu(NO2)+ptnonipm_solv(NO2)+ptnonipm_nosolv(NO2)+pt_oilgas_solv(NO2)+pt_oilgas_nosolv(NO2)'
 emis_map(4) = 'SO2->all(SO2)+cmv_c3_4(SO2)+cmv_c1c2_4(SO2)+othpt_solv(SO2)+othpt_nosolv(SO2)+ptegu(SO2)+ptnonipm_solv(SO2)+ptnonipm_nosolv(SO2)+pt_oilgas_solv(SO2)+pt_oilgas_nosolv(SO2)'
 emis_map(5) = 'NH3->all(NH3)+cmv_c3_4(NH3)+cmv_c1c2_4(NH3)+othpt_solv(NH3)+othpt_nosolv(NH3)+ptegu(NH3)+ptnonipm_solv(NH3)+ptnonipm_nosolv(NH3)+pt_oilgas_nosolv(NH3)'
 emis_map(6) = 'C2H5OH->all(ETOH)+cmv_c3_4(ETOH)+cmv_c1c2_4(ETOH)+othpt_solv(ETOH)+othpt_nosolv(ETOH)+ptegu(ETOH)+ptnonipm_solv(ETOH)+ptnonipm_nosolv(ETOH)+pt_oilgas_solv(ETOH)+pt_oilgas_nosolv(ETOH)'
 emis_map(7) = 'BIGALK->.2*all(PAR)+.2*cmv_c3_4(PAR)+.2*cmv_c1c2_4(PAR)+.2*othpt_solv(PAR)+.2*othpt_nosolv(PAR)+.2*ptegu(PAR)+.2*ptnonipm_solv(PAR)+.2*ptnonipm_nosolv(PAR)+.2*pt_oilgas_solv(PAR)+.2*pt_oilgas_nosolv(PAR)'
 emis_map(8) = 'BIGENE->all(IOLE)+cmv_c3_4(IOLE)+cmv_c1c2_4(IOLE)+othpt_solv(IOLE)+othpt_nosolv(IOLE)+ptegu(IOLE)+ptnonipm_solv(IOLE)+ptnonipm_nosolv(IOLE)+pt_oilgas_solv(IOLE)+pt_oilgas_nosolv(IOLE)'
 emis_map(9) = 'C2H4->all(ETH)+cmv_c3_4(ETH)+cmv_c1c2_4(ETH)+othpt_solv(ETH)+othpt_nosolv(ETH)+ptegu(ETH)+ptnonipm_solv(ETH)+ptnonipm_nosolv(ETH)+pt_oilgas_solv(ETH)+pt_oilgas_nosolv(ETH)'
 emis_map(10) = 'C2H6->all(ETHA)+cmv_c3_4(ETHA)+cmv_c1c2_4(ETHA)+othpt_solv(ETHA)+othpt_nosolv(ETHA)+ptegu(ETHA)+ptnonipm_solv(ETHA)+ptnonipm_nosolv(ETHA)+pt_oilgas_solv(ETHA)+pt_oilgas_nosolv(ETHA)'
 emis_map(11) = 'C3H6->all(OLE)+cmv_c3_4(OLE)+cmv_c1c2_4(OLE)+othpt_solv(OLE)+othpt_nosolv(OLE)+ptegu(OLE)+ptnonipm_solv(OLE)+ptnonipm_nosolv(OLE)+pt_oilgas_solv(OLE)+pt_oilgas_nosolv(OLE)'
 emis_map(12) = 'C3H8->all(PRPA)+cmv_c3_4(PRPA)+cmv_c1c2_4(PRPA)+othpt_solv(PRPA)+othpt_nosolv(PRPA)+ptegu(PRPA)+ptnonipm_solv(PRPA)+ptnonipm_nosolv(PRPA)+pt_oilgas_solv(PRPA)+pt_oilgas_nosolv(PRPA)'
 emis_map(13) = 'CH2O->all(FORM)+cmv_c3_4(FORM)+cmv_c1c2_4(FORM)+othpt_solv(FORM)+othpt_nosolv(FORM)+ptegu(FORM)+ptnonipm_solv(FORM)+ptnonipm_nosolv(FORM)+pt_oilgas_solv(FORM)+pt_oilgas_nosolv(FORM)'
 emis_map(14) = 'CH3CHO->all(ALD2+ALDX)+cmv_c3_4(ALD2+ALDX)+cmv_c1c2_4(ALD2+ALDX)+othpt_solv(ALD2+ALDX)+othpt_nosolv(ALD2+ALDX)+ptegu(ALD2+ALDX)+ptnonipm_solv(ALD2+ALDX)+ptnonipm_nosolv(ALD2+ALDX)+pt_oilgas_solv(ALD2+ALDX)+pt_oilgas_nosolv(ALD2+ALDX)'
 emis_map(15) = 'CH3COCH3->all(ACET)+cmv_c3_4(ACET)+cmv_c1c2_4(ACET)+othpt_solv(ACET)+othpt_nosolv(ACET)+ptegu(ACET)+ptnonipm_solv(ACET)+ptnonipm_nosolv(ACET)+pt_oilgas_solv(ACET)+pt_oilgas_nosolv(ACET)'
 emis_map(16) = 'CH3OH->all(MEOH)+cmv_c3_4(MEOH)+cmv_c1c2_4(MEOH)+othpt_solv(MEOH)+othpt_nosolv(MEOH)+ptegu(MEOH)+ptnonipm_solv(MEOH)+ptnonipm_nosolv(MEOH)+pt_oilgas_solv(MEOH)+pt_oilgas_nosolv(MEOH)'
 emis_map(17) = 'MEK->all(KET)+cmv_c3_4(KET)+cmv_c1c2_4(KET)+othpt_solv(KET)+othpt_nosolv(KET)+ptegu(KET)+ptnonipm_solv(KET)+ptnonipm_nosolv(KET)+pt_oilgas_solv(KET)+pt_oilgas_nosolv(KET)'
 emis_map(18) = 'TOLUENE->all(TOL)+cmv_c3_4(TOL)+cmv_c1c2_4(TOL)+othpt_solv(TOL)+othpt_nosolv(TOL)+ptegu(TOL)+ptnonipm_solv(TOL)+ptnonipm_nosolv(TOL)+pt_oilgas_solv(TOL)+pt_oilgas_nosolv(TOL)'
 emis_map(19) = 'BENZENE->all(BENZ)+cmv_c3_4(BENZ)+cmv_c1c2_4(BENZ)+othpt_solv(BENZ)+othpt_nosolv(BENZ)+ptegu(BENZ)+ptnonipm_solv(BENZ)+ptnonipm_nosolv(BENZ)+pt_oilgas_solv(BENZ)+pt_oilgas_nosolv(BENZ)'
 emis_map(20) = 'XYLENE->all(XYLMN)+cmv_c3_4(XYLMN)+cmv_c1c2_4(XYLMN)+othpt_solv(XYLMN)+othpt_nosolv(XYLMN)+ptegu(XYLMN)+ptnonipm_solv(XYLMN)+ptnonipm_nosolv(XYLMN)+pt_oilgas_solv(XYLMN)+pt_oilgas_nosolv(XYLMN)'
 emis_map(21) = 'ISOP->all(ISOP)+cmv_c3_4(ISOP)+cmv_c1c2_4(ISOP)+othpt_solv(ISOP)+othpt_nosolv(ISOP)+ptegu(ISOP)+ptnonipm_solv(ISOP)+ptnonipm_nosolv(ISOP)+pt_oilgas_solv(ISOP)+pt_oilgas_nosolv(ISOP)'
 emis_map(22) = 'APIN->all(TERP)+cmv_c3_4(TERP)+cmv_c1c2_4(TERP)+othpt_solv(TERP)+othpt_nosolv(TERP)+ptegu(TERP)+ptnonipm_solv(TERP)+ptnonipm_nosolv(TERP)+pt_oilgas_solv(TERP)+pt_oilgas_nosolv(TERP)'
 emis_map(23) = 'sulf->all(SULF)+cmv_c3_4(SULF)+cmv_c1c2_4(SULF)+othpt_solv(SULF)+othpt_nosolv(SULF)+ptegu(SULF)+ptnonipm_solv(SULF)+ptnonipm_nosolv(SULF)+pt_oilgas_solv(SULF)+pt_oilgas_nosolv(SULF)'
 emis_map(24) = 'C2H2->all(ETHY)+cmv_c3_4(ETHY)+cmv_c1c2_4(ETHY)+othpt_solv(ETHY)+othpt_nosolv(ETHY)+ptegu(ETHY)+ptnonipm_solv(ETHY)+ptnonipm_nosolv(ETHY)+pt_oilgas_solv(ETHY)+pt_oilgas_nosolv(ETHY)'
 emis_map(25) = 'PM_25(A)->all(PMOTHR)+cmv_c3_4(PMOTHR)+cmv_c1c2_4(PMOTHR)+othpt_solv(PMOTHR)+othpt_nosolv(PMOTHR)+ptegu(PMOTHR)+ptnonipm_solv(PMOTHR)+ptnonipm_nosolv(PMOTHR)+pt_oilgas_solv(PMOTHR)+pt_oilgas_nosolv(PMOTHR)'
 emis_map(26) = 'BC(A)->all(PEC)+cmv_c3_4(PEC)+cmv_c1c2_4(PEC)+othpt_solv(PEC)+othpt_nosolv(PEC)+ptegu(PEC)+ptnonipm_solv(PEC)+ptnonipm_nosolv(PEC)+pt_oilgas_solv(PEC)+pt_oilgas_nosolv(PEC)'
 emis_map(27) = 'OC(A)->all(POC)+cmv_c3_4(POC)+cmv_c1c2_4(POC)+othpt_solv(POC)+othpt_nosolv(POC)+ptegu(POC)+ptnonipm_solv(POC)+ptnonipm_nosolv(POC)+pt_oilgas_solv(POC)+pt_oilgas_nosolv(POC)'
 emis_map(28) = 'PM_10(A)->all(PMC)+cmv_c3_4(PMC)+cmv_c1c2_4(PMC)+othpt_solv(PMC)+othpt_nosolv(PMC)+ptegu(PMC)+ptnonipm_solv(PMC)+ptnonipm_nosolv(PMC)+pt_oilgas_solv(PMC)+pt_oilgas_nosolv(PMC)'
 emis_map(29) = 'SO4I(A)->.15*all(PSO4)+.15*cmv_c3_4(PSO4)+.15*cmv_c1c2_4(PSO4)+.15*othpt_solv(PSO4)+.15*othpt_nosolv(PSO4)+.15*ptegu(PSO4)+.15*ptnonipm_solv(PSO4)+.15*ptnonipm_nosolv(PSO4)+.15*pt_oilgas_solv(PSO4)+.15*pt_oilgas_nosolv(PSO4)'
 emis_map(30) = 'SO4J(A)->.85*all(PSO4)+.85*cmv_c3_4(PSO4)+.85*cmv_c1c2_4(PSO4)+.85*othpt_solv(PSO4)+.85*othpt_nosolv(PSO4)+.85*ptegu(PSO4)+.85*ptnonipm_solv(PSO4)+.85*ptnonipm_nosolv(PSO4)+.85*pt_oilgas_solv(PSO4)+.85*pt_oilgas_nosolv(PSO4)'
 emis_map(31) = 'ECI(A)->.15*all(PEC)+.15*cmv_c3_4(PEC)+.15*cmv_c1c2_4(PEC)+.15*othpt_solv(PEC)+.15*othpt_nosolv(PEC)+.15*ptegu(PEC)+.15*ptnonipm_solv(PEC)+.15*ptnonipm_nosolv(PEC)+.15*pt_oilgas_solv(PEC)+.15*pt_oilgas_nosolv(PEC)'
 emis_map(32) = 'ECJ(A)->.85*all(PEC)+.85*cmv_c3_4(PEC)+.85*cmv_c1c2_4(PEC)+.85*othpt_solv(PEC)+.85*othpt_nosolv(PEC)+.85*ptegu(PEC)+.85*ptnonipm_solv(PEC)+.85*ptnonipm_nosolv(PEC)+.85*pt_oilgas_solv(PEC)+.85*pt_oilgas_nosolv(PEC)'
 emis_map(33) = 'ORGI(A)->.15*all(POC)+.15*cmv_c3_4(POC)+.15*cmv_c1c2_4(POC)+.15*othpt_solv(POC)+.15*othpt_nosolv(POC)+.15*ptegu(POC)+.15*ptnonipm_solv(POC)+.15*ptnonipm_nosolv(POC)+.15*pt_oilgas_solv(POC)+.15*pt_oilgas_nosolv(POC)'
 emis_map(34) = 'ORGJ(A)->.85*all(POC)+.85*cmv_c3_4(POC)+.85*cmv_c1c2_4(POC)+.85*othpt_solv(POC)+.85*othpt_nosolv(POC)+.85*ptegu(POC)+.85*ptnonipm_solv(POC)+.85*ptnonipm_nosolv(POC)+.85*pt_oilgas_solv(POC)+.85*pt_oilgas_nosolv(POC)'
 emis_map(35) = 'NO3I(A)->.15*all(PNO3)+.15*cmv_c3_4(PNO3)+.15*cmv_c1c2_4(PNO3)+.15*othpt_solv(PNO3)+.15*othpt_nosolv(PNO3)+.15*ptegu(PNO3)+.15*ptnonipm_solv(PNO3)+.15*ptnonipm_nosolv(PNO3)+.15*pt_oilgas_solv(PNO3)+.15*pt_oilgas_nosolv(PNO3)'
 emis_map(36) = 'NO3J(A)->.85*all(PNO3)+.85*cmv_c3_4(PNO3)+.85*cmv_c1c2_4(PNO3)+.85*othpt_solv(PNO3)+.85*othpt_nosolv(PNO3)+.85*ptegu(PNO3)+.85*ptnonipm_solv(PNO3)+.85*ptnonipm_nosolv(PNO3)+.85*pt_oilgas_solv(PNO3)+.85*pt_oilgas_nosolv(PNO3)'
 emis_map(37) = 'NH4I(A)->.15*all(PNH4)+.15*cmv_c3_4(PNH4)+.15*cmv_c1c2_4(PNH4)+.15*othpt_solv(PNH4)+.15*othpt_nosolv(PNH4)+.15*ptegu(PNH4)+.15*ptnonipm_solv(PNH4)+.15*ptnonipm_nosolv(PNH4)+.15*pt_oilgas_solv(PNH4)+.15*pt_oilgas_nosolv(PNH4)'
 emis_map(38) = 'NH4J(A)->.85*all(PNH4)+.85*cmv_c3_4(PNH4)+.85*cmv_c1c2_4(PNH4)+.85*othpt_solv(PNH4)+.85*othpt_nosolv(PNH4)+.85*ptegu(PNH4)+.85*ptnonipm_solv(PNH4)+.85*ptnonipm_nosolv(PNH4)+.85*pt_oilgas_solv(PNH4)+.85*pt_oilgas_nosolv(PNH4)'
 emis_map(39) = 'HONO->all(HONO)+cmv_c3_4(HONO)+cmv_c1c2_4(HONO)+othpt_solv(HONO)+othpt_nosolv(HONO)+ptegu(HONO)+ptnonipm_solv(HONO)+ptnonipm_nosolv(HONO)+pt_oilgas_solv(HONO)+pt_oilgas_nosolv(HONO)'
 emis_map(40) = 'MACR->all(ACROLEIN)+ptegu(ACROLEIN)+ptnonipm_solv(ACROLEIN)+ptnonipm_nosolv(ACROLEIN)+pt_oilgas_solv(ACROLEIN)+pt_oilgas_nosolv(ACROLEIN)'
/

EOF
