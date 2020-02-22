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

###prepare adaptive inflation priors
if $ADAPTIVE_INFLATION; then
  if [[ $DATE == $DATE_CYCLE_START ]]; then
    $DART_DIR/models/wrf/work/fill_inflation_restart >& fill_inflation_restart.log
    for n in `seq 1 $MAX_DOM`; do
      dm=d`expr $n + 100 |cut -c2-`
      for name in prior post; do
        mv ${name}_inflation_mean_${dm}.nc $WORK_DIR/fc/$DATE/input_${name}inf_mean_${dm}.nc
        mv ${name}_inflation_sd_${dm}.nc $WORK_DIR/fc/$DATE/input_${name}inf_sd_${dm}.nc
        ln -fs $WORK_DIR/fc/$DATE/input_${name}inf_mean_${dm}.nc .
        ln -fs $WORK_DIR/fc/$DATE/input_${name}inf_sd_${dm}.nc .
      done
    done
  else
    for n in `seq 1 $MAX_DOM`; do
      dm=d`expr $n + 100 |cut -c2-`
      for name in prior post; do
        ln -fs $WORK_DIR/fc/$PREVDATE/output_${name}inf_mean_${dm}.nc input_${name}inf_mean_${dm}.nc
        ln -fs $WORK_DIR/fc/$PREVDATE/output_${name}inf_sd_${dm}.nc input_${name}inf_sd_${dm}.nc
      done
    done
  fi
fi

echo "    filter started"
rm -f dart_log.out
if [ ! -f obs_seq.final ]; then
  $SCRIPT_DIR/job_submit.sh $dart_ntasks 0 $dart_ppn ./filter
fi
watch_log dart_log.out Finished 15 $rundir

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

if $ADAPTIVE_INFLATION; then
  for n in `seq 1 $MAX_DOM`; do
    dm=d`expr $n + 100 |cut -c2-`
    for name in prior post; do
      mv output_${name}inf_mean_${dm}.nc $WORK_DIR/fc/$DATE/.
      mv output_${name}inf_sd_${dm}.nc $WORK_DIR/fc/$DATE/.
    done
  done
fi

if $CLEAN; then
  rm -f filter_restart* input*nc output*nc preassim*nc postassim*nc
fi

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

##analysis ensemble mean
for n in `seq 1 $MAX_DOM`; do
  dm=d`expr $n + 100 |cut -c2-`
  rm -f $WORK_DIR/fc/$DATE/wrfinput_${dm}_mean
  ncea $WORK_DIR/fc/$DATE/wrfinput_${dm}_??? $WORK_DIR/fc/$DATE/wrfinput_${dm}_mean
done

echo complete > stat

