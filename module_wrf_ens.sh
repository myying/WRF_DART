#!/bin/bash
. $CONFIG_FILE

rundir=$WORK_DIR/run/$DATE/wrf_ens
if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi

#Check dependency
wait_for_module ../icbc
if [ $DATE == $DATE_START ]; then wait_for_module ../perturb_ic; fi
if [ $DATE -gt $DATE_START ]; then
  if $RUN_DART; then wait_for_module ../dart; fi
fi
echo running > stat

export start_date=$DATE
export run_minutes=$run_minutes_cycle
export inputout_interval=$run_minutes
export inputout_begin=0
export inputout_end=$run_minutes

echo "  Running WRF ensemble forecast..."
tid=0
nt=$((total_ntasks/$wrf_ntasks))
for r in 1; do
  export time_step_ratio=$r
  for NE in `seq 1 $NUM_ENS`; do
    id=`expr $NE + 1000 |cut -c2-`
    if [[ ! -d $id ]]; then mkdir $id; fi
    touch $id/rsl.error.0000
    if [[ `tail -n5 $id/rsl.error.0000 |grep SUCCESS` ]]; then continue; fi
    cd $id

    ####Update and perturb BC
    #if [ $DATE == $LBDATE ] && [ $r == 1 ]; then
      #dd=`diff_time $DATE_START $LBDATE`
      #n_1=$((dd/$LBC_INTERVAL+1))
      #cat > parame.in << EOF
#&control_param
 #wrf_3dvar_output_file = 'wrfinput_d01_update'
 #wrf_bdy_file          = 'wrfbdy_d01_update'
 #wrf_bdy_file_real     = 'wrfbdy_d01_real'
 #wrf_input_from_si     = 'wrfinput_d01_real'
 #wrf_input_from_si_randmean = 'random_mean'
 #wrf_3dvar_random_draw = 'random_draw'
 #cycling = .true.
 #low_bdy_only = .false.
 #perturb_bdy = .true.
 #n_1 = $n_1
#/
#EOF
      #ln -fs $WRF_BC_DIR/update_wrf_bc.exe .

      #ln -fs ../../../../fc/wrfbdy_d01_$id wrfbdy_d01_real
      #cp -L wrfbdy_d01_real wrfbdy_d01_update
      #ln -fs ../../../../rc/$DATE_START/wrfinput_d01_`wrf_time_string $DATE` wrfinput_d01_real
      #ln -fs ../../../../fc/$DATE/wrfinput_d01_$id wrfinput_d01_update

      #randnum=`expr $((RANDOM%99+1)) + 1000 |cut -c2-`
      #ln -fs ../../../../fc/$DATE_START/wrfinput_d01_$randnum random_draw
      #ln -fs ../../../../fc/$DATE_START/wrfinput_d01 random_mean
      #echo $n_1 $randnum >> ../../../../fc/rand_$id

      #./update_wrf_bc.exe >& update_wrf_bc.log
      #watch_log update_wrf_bc.log successfully 1 $rundir
      #mv wrfbdy_d01_update $WORK_DIR/fc/wrfbdy_d01_$id
    #fi

    ##????
    #if [ $DATE == $LBDATE ]; then
      #export sst_update=1
    #else
      #export sst_update=0
    #fi

    ####Running model
    ln -fs $WRF_DIR/run/* .
    rm -f namelist.*

    for n in `seq 1 $MAX_DOM`; do
      dm=d`expr $n + 100 |cut -c2-`
      if $RUN_DART || [[ $DATE == $DATE_START ]]; then
        ln -fs ../../../../fc/$DATE/wrfinput_${dm}_$id wrfinput_$dm
      else
        ln -fs ../../../../fc/$PREVDATE/wrfinput_${dm}_`wrf_time_string $DATE`_$id wrfinput_$dm
      fi
    done
		ln -fs ../../../../fc/wrfbdy_d01 wrfbdy_d01

    $SCRIPT_DIR/namelist_wrf.sh wrf > namelist.input
    $SCRIPT_DIR/job_submit.sh $wrf_ntasks $((tid*$wrf_ntasks)) $HOSTPPN ./wrf.exe >& wrf.log &

    tid=$((tid+1))
    if [[ $tid == $nt ]]; then
      tid=0
      wait
    fi
    cd ..
  done
  wait
done

#Check outputs
for NE in `seq 1 $NUM_ENS`; do
  id=`expr $NE + 1000 |cut -c2-`
  watch_log $id/rsl.error.0000 SUCCESS 1 $rundir
  for i in 0; do
    outdate=`advance_time $NEXTDATE $i`
    outfile=$id/wrfinput_d01_`wrf_time_string $outdate`
    mv $outfile $WORK_DIR/fc/$DATE/wrfinput_d01_`wrf_time_string $outdate`_$id
    if [ $MAX_DOM -gt 1 ]; then
      for n in `seq 1 $MAX_DOM`; do
        dm=d`expr $n + 100 |cut -c2-`
        outfile=$id/wrfout_${dm}_`wrf_time_string $outdate`
        mv $outfile $WORK_DIR/fc/$DATE/wrfinput_${dm}_`wrf_time_string $outdate`_$id
      done
    fi
  done
done

#Calculate ensemble mean for prior (next cycle)
echo "  Calculating ensemble mean..."
cd $rundir
for n in `seq 1 $MAX_DOM`; do
  dm=d`expr $n + 100 |cut -c2-`
  rm -f $WORK_DIR/fc/$DATE/wrfinput_${dm}_`wrf_time_string $NEXTDATE`_mean
  ncea $WORK_DIR/fc/$DATE/wrfinput_${dm}_`wrf_time_string $NEXTDATE`_??? $WORK_DIR/fc/$DATE/wrfinput_${dm}_`wrf_time_string $NEXTDATE`_mean
done

if $CLEAN; then
  for NE in `seq 1 $NUM_ENS`; do
    id=`expr $NE + 1000 |cut -c2-`
    rm -f $rundir/$id/wrfout* &
    rm $id/rsl.* &
  done
fi

echo complete > stat

