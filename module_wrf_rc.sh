#!/bin/bash
. $CONFIG_FILE

rundir=$WORK_DIR/run/$DATE/wrf
if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi

#Check dependency
wait_for_module ../icbc 

echo running > stat

export start_date=$DATE
#if [ $DATE == $DATE_START ]; then
#  export run_minutes=`diff_time $DATE_START $DATE_END`
#else
#  export run_minutes=$run_minutes_forecast
#fi
  export run_minutes=$run_minutes_forecast

for i in 1; do
  touch rsl.error.0000
  if [[ `tail -n5 rsl.error.0000 |grep SUCCESS` ]]; then continue; fi

  ln -fs $WRF_DIR/run/* .
  rm -f namelist.*

  for n in `seq 1 $MAX_DOM`; do
    dm=d`expr $n + 100 |cut -c2-`
    ln -fs ../../../rc/$DATE/wrfinput_$dm .
  done
  ln -fs ../../../rc/$DATE_START/wrfbdy_d01 .
  if [[ $SST_UPDATE == 1 ]]; then
    ln -fs ../../../rc/$DATE_START/wrflowinp_d?? .
  fi

  if $FOLLOW_STORM; then
    cp $WORK_DIR/rc/$DATE/ij_parent_start_4dvar ij_parent_start
    cp $WORK_DIR/rc/$DATE/domain_moves_4dvar domain_moves
  fi
  if $MULTI_PHYS_ENS; then
    $SCRIPT_DIR/multi_physics_reset.sh >& multi_physics_reset.log
  fi
  $SCRIPT_DIR/namelist_wrf.sh wrf > namelist.input

  $SCRIPT_DIR/job_submit.sh $wrf_single_ntasks 0 $HOSTPPN ./wrf.exe >& wrf.log
done

#Check output
watch_log rsl.error.0000 SUCCESS 1 $rundir

mv wrfout* $WORK_DIR/output/$DATE

echo complete > stat

