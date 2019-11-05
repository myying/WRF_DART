#!/bin/bash
. $CONFIG_FILE

rundir=$WORK_DIR/run/$DATE/obsproc

if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi
echo running > stat
echo "  Processing observations..."

ln -fs $WRFDA_DIR/var/obsproc/obsproc.exe .
ln -fs $WRFDA_DIR/var/obsproc/obserr.txt .
echo > obs.raw

echo "    gathering raw data"
##### include NCAR_LITTLE_R (3-hourly) #####
if $INCLUDE_LITTLE_R; then
  rm -f datelist
  time_lag=1
  obs_interval=1
  for offset in `seq $((OBS_WIN_MIN/60-$time_lag)) $obs_interval $((OBS_WIN_MAX/60+$time_lag))`; do
    obsdate=`advance_time $DATE $((offset*60))`
    hh=`echo $obsdate |cut -c9-10`
    inc=`echo $hh%$obs_interval*60 |bc`
    if [[ $inc -lt $((obs_interval*60/2)) ]]; then
      obsdate=`advance_time $obsdate -$inc`
    else
      obsdate=`advance_time $obsdate $((obs_interval*60-inc))`
    fi
    echo $obsdate >> datelist
  done
  for d in `cat datelist |sort |uniq`; do
    #NCAR_LITTLE_R
    if [ -f $DATA_DIR/ncar_littler/${d:0:6}/obs.${d:0:10}.gz ]; then
      cp $DATA_DIR/ncar_littler/${d:0:6}/obs.${d:0:10}.gz .
      gunzip obs.${d:0:10}.gz
      cat obs.${d:0:10} >> obs.raw
      rm obs.${d:0:10}
    fi

    #AMV
    #if [ -f $DATA_DIR/amv/${d:0:6}/amv.${d:0:10} ]; then
      #cat $DATA_DIR/amv/${d:0:6}/amv.${d:0:10} >> obs.raw
    #fi
  done
fi

echo "    running obsproc.exe"
for var_type in 3DVAR 4DVAR; do
  case $var_type in
    3DVAR)
      if ! $RUN_DART; then continue; fi
    ;;
    4DVAR)
      if ! $RUN_4DVAR; then continue; fi
    ;;
  esac
  echo > obsproc.log
  export use_for=$var_type
  $SCRIPT_DIR/namelist_obsproc.sh > namelist.obsproc
  ./obsproc.exe >& obsproc.log
  watch_log obsproc.log 99999 1 $rundir
  cp obs_gts_*.$var_type $WORK_DIR/obs/$DATE/.
done

echo "    running gts_to_dart"
$SCRIPT_DIR/namelist_dart.sh > input.nml
ln -fs obs_gts_`wrf_time_string $DATE`.3DVAR gts_obsout.dat
ln -fs $DART_DIR/observations/obs_converters/var/work/gts_to_dart .
./gts_to_dart >& gts_to_dart.log
watch_log gts_to_dart.log successfully 1 $rundir
cp obs_seq.out $WORK_DIR/obs/$DATE/.

if $CLEAN; then rm obs.raw; fi

echo complete > stat

