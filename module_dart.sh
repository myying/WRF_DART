#!/bin/bash
. $CONFIG_FILE
rundir=$WORK_DIR/run/$DATE/dart
if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi

wait_for_module ../../$PREVDATE/wrf_ens ../obsproc
if [[ $JOB_SUBMIT_MODE == 1 ]]; then
  wait_for_module ../icbc
fi

echo "  Running DART..."
echo running > stat


###file lists (prior/post ensemble)
for n in `seq 1 $MAX_DOM`; do
  dm=d`expr $n + 100 |cut -c2-`
  rm -f input_list_${dm}.txt output_list_${dm}.txt
  for m in `seq 1 $NUM_ENS`; do
    id=`expr $m + 1000 |cut -c2-`
    echo $WORK_DIR/fc/$PREVDATE/wrfinput_${dm}_`wrf_time_string $DATE`_${id} >> input_list_${dm}.txt
    echo filter_restart_${dm}_${id} >> output_list_${dm}.txt
  done
  ln -fs $WORK_DIR/fc/$PREVDATE/wrfinput_${dm}_`wrf_time_string $DATE`_mean wrfinput_${dm}
done

###link observations
ln -fs $WORK_DIR/obs/$DATE/obs_seq.out

ln -fs $DART_DIR/models/wrf/work/filter .
ln -fs $DART_DIR/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc .
$SCRIPT_DIR/namelist_dart.sh > input.nml

#  ##  Copy the inflation files from the previous time, update for domains
#  if ( $ADAPTIVE_INFLATION == 1 ) then
#     mkdir -p ${RUN_DIR}/{Inflation_input,Output}   home for inflation and future state space diag files
#     ## Should try to check each file here, but shortcutting for prior (most common) and link them all
#     if ( $domains == 1) then
#       if ( -e ${OUTPUT_DIR}/${datep}/Inflation_input/input_priorinf_mean.nc ) then
#         ${LINK} ${OUTPUT_DIR}/${datep}/Inflation_input/input_priorinf*.nc ${RUN_DIR}/.
#         ${LINK} ${OUTPUT_DIR}/${datep}/Inflation_input/input_postinf*.nc ${RUN_DIR}/.
#       else
#         echo "${OUTPUT_DIR}/${datep}/Inflation_input/input_priorinf_mean.nc files do not exist.  Stopping"
#         touch ABORT_RETRO
#         exit
#       endif
#     else     multiple domains so multiple inflation files for each domain
#       echo "This script doesn't support multiple domains.  Stopping"
#       touch ABORT_RETRO
#       exit
#     endif  number of domains check
#  endif    ADAPTIVE_INFLATION file check

echo "    filter started"
if [ ! -f obs_seq.final ]; then
  $SCRIPT_DIR/job_submit.sh $dart_ntasks 0 $dart_ppn ./filter
fi

###Check if finished successfully
watch_log dart_log.out Finished 5 $rundir

###diagnose and move output files
echo "    adding analysis increment to members"
for n in `seq 1 $MAX_DOM`; do
  dm=d`expr $n + 100 |cut -c2-`
  for NE in `seq 1 $NUM_ENS`; do
    id=`expr $NE + 1000 |cut -c2-`
    cp -f $WORK_DIR/fc/$PREVDATE/wrfinput_${dm}_`wrf_time_string $DATE`_${id} $WORK_DIR/fc/$DATE/wrfinput_${dm}_${id}
    ncks -A -v `echo ${UPDATE_VAR[*]} |tr ' ' ','` filter_restart_${dm}_${id} $WORK_DIR/fc/$DATE/wrfinput_${dm}_${id}
  done
done

#if $CLEAN; then
#fi

  ## analysis increment
#  ncdiff -F -O -v $extract_str postassim_mean.nc preassim_mean.nc analysis_increment.nc
#  ncks -F -O -x -v ${extract_str} postassim_mean.nc static_data.nc
#  ncks -A static_data.nc analysis_increment.nc

#  foreach FILE ( postassim_mean.nc preassim_mean.nc postassim_sd.nc preassim_sd.nc obs_seq.final analysis_increment.nc output_mean.nc output_sd.nc )
#      ${MOVE} $FILE ${OUTPUT_DIR}/${datea}/.
#  end

#  ##  Compute Diagnostic Quantities
#  if ( -e obs_diag.log ) ${REMOVE} obs_diag.log
#  ${SHELL_SCRIPTS_DIR}/diagnostics_obs.csh $datea ${SHELL_SCRIPTS_DIR}/$paramfile >& ${RUN_DIR}/obs_diag.log &

#    Move inflation files to storage directories
#  cd ${RUN_DIR}
#   Different file names with multiple domains
#  if ( $ADAPTIVE_INFLATION == 1 ) then
#    set old_file = ( input_postinf_mean.nc  input_postinf_sd.nc  input_priorinf_mean.nc  input_priorinf_sd.nc )
#    set new_file = ( output_postinf_mean.nc output_postinf_sd.nc output_priorinf_mean.nc output_priorinf_sd.nc )
#    set i = 1
#    set nfiles = $new_file
#    while ($i <= $nfiles)
#      if ( -e ${new_file[$i]} && ! -z ${new_file[$i]} ) then
#        ${MOVE} ${new_file[$i]} ${OUTPUT_DIR}/${datea}/Inflation_input/${old_file[$i]}
#        if ( ! $status == 0 ) then
#           echo "failed moving ${RUN_DIR}/Output/${FILE}"
#           touch BOMBED
#        endif
#      endif
#      @ i++
#    end
#    echo "past the inflation file moves"

###Replace mean
#1. replacing mean with 4DVar analysis (recentering) if running hybrid DA

echo complete > stat

