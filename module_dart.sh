#!/bin/bash
. $CONFIG_FILE
rundir=$WORK_DIR/run/$DATE/dart
if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi

wait_for_module ../../$PREVDATE/wrf_ens ../obsproc
if [[ $JOB_SUBMIT_MODE == 1 ]]; then
  wait_for_module ../icbc
  if $RUN_4DVAR; then  wait_for_module ../4dvar ../wrf_window; fi
fi

#Run DART ensemble filter
echo running > stat


#echo complete > stat

