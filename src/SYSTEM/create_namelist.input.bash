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
num_metgrid_levels=$4

if [ $shr -eq 00 ]
then
   rhr=36
else
   rhr=6
fi

fileo=$rundir/wrf/namelist.input
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
 frames_per_outfile                  =    6,    6, 1000,
 restart                             = .false.,
 restart_interval                    = 7200,
 io_form_history                     = 2
 io_form_restart                     = 2
 io_form_input                       = 2
 io_form_boundary                    = 2
 /

 &domains
 time_step                           = 30,
 time_step_fract_num                 = 0,
 time_step_fract_den                 = 1,
 max_dom                             = 2,
 e_we                                = 200,    351,   271,
 e_sn                                = 200,    281,   229,
 e_vert                              = 50,     50,    43,
 p_top_requested                     = 5000,
 num_metgrid_levels                  = ${num_metgrid_levels},
 num_metgrid_soil_levels             = 4,
 dx                                  = 15000, 3000,  3000,
 dy                                  = 15000, 3000,  3000,
 grid_id                             = 1,     2,     3,
 parent_id                           = 0,     1,     2,
 i_parent_start                      = 1,     76,    30,
 j_parent_start                      = 1,     78,    30,
 parent_grid_ratio                   = 1,     5,     3,
 parent_time_step_ratio              = 1,     5,     3,
 feedback                            = 1,
 smooth_option                       = 0
 /

 &physics
 mp_physics                          =  8,     8,    -1,
 ra_lw_physics                       =  4,     4,    -1,
 ra_sw_physics                       =  4,     4,    -1,
 radt                                = 15,    15,    27,
 sf_sfclay_physics                   =  2,     2,    -1,
 sf_surface_physics                  =  2,     2,    -1,
 bl_pbl_physics                      =  2,     2,    -1,
 bldt                                =  0,     0,     0,
 cu_physics                          =  3,     0,     0,
 cudt                                =  0,     5,     0,
 isfflx                              =  1,
 ifsnow                              =  1,
 icloud                              =  1,
 surface_input_source                =  1,
 num_soil_layers                     =  4,
 num_land_cat                        = 20,
 do_radar_ref                        =  1,
 sf_urban_physics                    =  0,     0,     0,
 /

 &fdda
 /

 &dynamics
 hybrid_opt                          = 2,
 w_damping                           = 0,
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
 non_hydrostatic                     = .true., .true., .true.,
 moist_adv_opt                       = 1,      1,      1,
 scalar_adv_opt                      = 1,      1,      1,
 gwd_opt                             = 1,
 /

 &bdy_control
 spec_bdy_width                      = 5,
 spec_zone                           = 1,
 relax_zone                          = 4,
 specified                           = .true.,.false.,
 nested                              = .false.,.true.,
 /

 &namelist_quilt
 nio_tasks_per_group = 0,
 nio_groups = 1, 

 &grib2
 /
EOF