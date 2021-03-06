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
rhr=${4}
num_metgrid_levels=${5}
chemopt=${6}

#if [ $shr -eq 00 ]
#then
#   # Update the rhr with other variables in run_wrfgsi.bash
#   rhr=6
#else
#   rhr=6
#fi

case $chemopt in
114)
  time_control="auxinput5_inname                    = 'wrfchemi_d<domain>_<date>',
 io_form_auxinput5                   = 2,
 frames_per_auxinput5                = 1, 1,
 auxinput5_interval_m                = 60, 60,
 auxinput6_inname                    = 'wrfbiochemi_d<domain>',
 io_form_auxinput6                   = 2,
 frames_per_auxinput6                = 1, 1,
 auxinput6_interval_d                = 90, 90,
 auxinput7_inname                    = 'wrffirechemi_d<domain>_<date>',
 io_form_auxinput7                   = 2,
 frames_per_auxinput7                = 1, 1,
 auxinput7_interval_m                = 60, 60,
 force_use_old_data                  = .True.,
!iofields_filename                   = 'iofield_list.txt','iofield_list.txt', !add output variables for process analysis"
  chem="kemit                               = 10,
 bioemdt                             = 2,      2,    2,
 photdt                              = 30,     30,   30,
 chemdt                              = 2,     1,   0.5,
 emiss_inpt_opt                      = 102,    102,  111, ! from T1-MOZCART user guide
 emiss_opt                           = 11,     11,    11,
 io_style_emissions                  = 2,
 chem_in_opt                         = 0,     0,    0,
 phot_opt                            = 3,      3,    3,
 gas_drydep_opt                      = 1,      1,    1,
 aer_drydep_opt                      = 1,      1,    1,
 bio_emiss_opt                       = 3,      3,    3,
 gas_bc_opt                          = 1,    1,   1,
 gas_ic_opt                          = 1,    1,   1,
 aer_bc_opt                          = 1,    1,   1,
 aer_ic_opt                          = 1,    1,   1,
 gaschem_onoff                       = 1,      1,     1,
 aerchem_onoff                       = 1,      1,     1,
 wetscav_onoff                       = 1,      1,     1,
 cldchem_onoff                       = 0,      0,     0,
 vertmix_onoff                       = 1,      1,     1,
 chem_conv_tr                        = 1,      1,     0,
 conv_tr_wetscav                     = 1,      1,     1,
 conv_tr_aqchem                      = 1,      1,     1,
 seas_opt                            = 2,
 dust_opt                            = 3,
 dmsemis_opt                         = 1,
 biomass_burn_opt                    = 4,      4,     4,
 plumerisefire_frq                   = 60,     60,    60,
 have_bcs_chem                       = .true., .true., .true.,
 have_bcs_upper                      = .false., .false., .false.,
 aer_ra_feedback                     = 1,       1,   1,
 aer_op_opt                          = 1,       1,
 ne_area                             = 500,
 opt_pars_out                        = 1,
 scale_fire_emiss                    = .true.,  .true.,
 chemdiag                            = 1, 1,  1,"
  ;;
0)
  time_control=""
  chem=""
  ;; 
*)
  echo "Not supported chem_opt: $chemopt"
  exit 31
esac

fileo=$rundir/wrf/namelist.input
if [ -s $fileo ]; then
   rm $fileo
fi

cat << EOF > $fileo
 &time_control
 run_days                            = 0,
 run_hours                           = $rhr,
 run_minutes                         = 0,
 run_seconds                         = 0,
 start_year                          = $syear,  $syear, 2018,
 start_month                         = $smon,   $smon,   03,
 start_day                           = $sday,   $sday,   01,
 start_hour                          = $shr,    $shr,   00,
 end_year                            = $eyear,  $eyear, 2018,
 end_month                           = $emon,   $emon,   03,
 end_day                             = $eday,   $eday,   04,
 end_hour                            = $ehr,    $ehr,   00,
 interval_seconds                    = 21600
 input_from_file                     = .true.,.true.,.true.,
 history_interval                    =   60,   60,   60,
 frames_per_outfile                  =    1,    1,   1,
 restart                             = .false.,
 restart_interval                    = 7200,
 io_form_history                     = 2,
 io_form_restart                     = 2,
 io_form_input                       = 2,
 io_form_boundary                    = 2,
 debug_level                         = 0,
 ${time_control}
 /

 &domains
 time_step                           = 60,
 time_step_fract_num                 = 0,
 time_step_fract_den                 = 1,
 max_dom                             = 2,
 e_we                                = 240,   265,   319,
 e_sn                                = 220,   223,   349,
 e_vert                              = 50,     50,    50,
 p_top_requested                     = 5000,
 num_metgrid_levels                  = ${num_metgrid_levels},
 num_metgrid_soil_levels             = 4,
 dx                                  = 12000, 4000,  1333.33,
 dy                                  = 12000, 4000,  1333.33,
 grid_id                             = 1,     2,     3,
 parent_id                           = 1,     1,     2,
 i_parent_start                      = 1,   111,   168,
 j_parent_start                      = 1,   94,   162,
 parent_grid_ratio                   = 1,     3,     3,
 parent_time_step_ratio              = 1,     3,     3,
 feedback                            = 1,
 smooth_option                       = 0
 /

 &physics
 mp_physics                          =  8,     8,    8,
 progn                               =  0,     0,    0,
 ra_lw_physics                       =  4,     4,    4,
 ra_sw_physics                       =  4,     4,    4,
 radt                                = 12,    12,   12,
 sf_sfclay_physics                   =  1,     1,    2,
 sf_surface_physics                  =  2,     2,    2,
 bl_pbl_physics                      =  1,     1,    1,
 bldt                                =  0,     0,     0,
 cu_physics                          =  3,     3,     0,
 cudt                                =  0,     0,     0,
 cu_diag                             =  0,
 isfflx                              =  1,
 ifsnow                              =  1,
 icloud                              =  1,
 surface_input_source                =  3,
 num_soil_layers                     =  4,
 num_land_cat                        = 20,
 do_radar_ref                        =  1,
 sf_urban_physics                    =  0,     0,     0,
 maxiens                             = 1,
 maxens                              = 3,
 maxens2                             = 3,
 maxens3                             = 16,
 ensdim                              = 144,
 cu_rad_feedback                     = .true.,
 /

 &fdda
 /

 &dynamics
 rk_ord                              = 3,
 hybrid_opt                          = 0,
 use_theta_m                         = 0,
 w_damping                           = 1,
 diff_opt                            = 1,      1,      1,
 km_opt                              = 4,      4,      4,
 diff_6th_opt                        = 0,      0,      0,
 diff_6th_factor                     = 0.12,   0.12,   0.12,
 base_temp                           = 290.
 damp_opt                            = 3,
 zdamp                               = 5000.,  5000.,  5000.,
 dampcoef                            = 0.2,    0.2,    0.2
 khdif                               = 0,      0,      0,
 kvdif                               = 0,      0,      0,
 smdiv                               = 0.1,
 non_hydrostatic                     = .true., .true., .true.,
 moist_adv_opt                       = 2,      2, 2,
 scalar_adv_opt                      = 2,      2, 2,
 chem_adv_opt                        = 2,      2, 2,
 tke_adv_opt                         = 2,      2, 2,
 h_mom_adv_order                     = 5,      5, 5,
 v_mom_adv_order                     = 3,      3, 3,
 h_sca_adv_order                     = 5,      5, 5,
 v_sca_adv_order                     = 3,      3, 3,
 gwd_opt                             = 1,
 /

 &bdy_control
 spec_bdy_width                      = 5,
 spec_zone                           = 1,
 relax_zone                          = 4,
 specified                           = .true.,.false.,.false.,
 nested                              = .false.,.true.,.true.,
 /

 &grib2
 /

 &namelist_quilt
 nio_tasks_per_group = 0,
 nio_groups = 1,
 /

 
 & chem
 chem_opt                            = $chemopt, $chemopt,   112,
 $chem
 / 

EOF

exit 0
