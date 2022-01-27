#! /bin/csh -f

#####   Set Variable  #####
set casename       = "summer"
set expname        = "conv"
set anal_time      = "18a_mma_dda_hr"
set bkg_time       = "18b_mmb_ddb_hr"
#set lastname       = ".nysmsfc"
set lastname       = ""

set YY=`echo $anal_time | cut -c1-2`
set MM=`echo $anal_time | cut -c3-4`
set DD=`echo $anal_time | cut -c5-6`
set HH=`echo $anal_time | cut -c7-8`

set work_path      = "/network/rit/lab/josephlab/LIN/GSI-WRF_v1/"
set code_path      = ${work_path}"CODE/"$expname"/"
set input_path     = $work_path"GSI/output/"$casename"/"$expname"_"$anal_time"/"
set out_path       = $work_path"WRF/output/"$casename"/"$expname"_"$anal_time"/"
set run_path       = $work_path"WRF/WRF_"$expname"/"
set lbc_path       = ${work_path}"UPDATE_LBC/"

## copy and link files
set wrf_inout   = "wrf_inout"
set wrfbdy_file = "wrfbdy_d01"

cd $lbc_path

cp $input_path$wrf_inout $lbc_path$wrf_inout
cp $run_path$wrfbdy_file $lbc_path$wrfbdy_file

cp $lbc_path"parame.in.LBC" $lbc_path"parame.in"

./da_update_bc.exe > lateralBC.log

##### Check if successfully run #####

CHECK:
  echo "lateralBC.log"
  set ans = `grep -i "Update_bc completed successfully" lateralBC.log`
  set RESULT=$?
  if ($RESULT == 0) then
    echo "SUCCESS: Run Update Lateral BC"
    mkdir $out_path
    mv $lbc_path$wrf_inout $out_path"wrfinput_d01"
    mv $lbc_path$wrfbdy_file $out_path$wrfbdy_file
    rm fort.*
    rm $run_path"wrfbdy_d01"
    goto SUCCESS
  else
    echo "NOT YET"
    sleep 10s
    goto CHECK
  endif

SUCCESS:
  echo "END RUN Update Lateral BC"
  cd $code_path
