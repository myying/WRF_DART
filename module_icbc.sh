#!/bin/bash
. $CONFIG_FILE

rundir=$WORK_DIR/run/$DATE/icbc
if [[ ! -d $rundir ]]; then mkdir -p $rundir; echo waiting > $rundir/stat; fi

cd $rundir
if [[ `cat stat` == "complete" ]]; then exit; fi

#no dependency
if [[ $DATE -gt $DATE_START ]]; then
  wait_for_module ../../$DATE_START/icbc
fi

echo "  Preparing IC BC..."
echo running > stat

#if CP < LBC_INTERVAL, cannot generate wrfinput and wrfbdy from LBC data
#instead, we will fetch wrfbdy from the previous cycle where LBC is available
#and wrfinput will be from the previous cycle wrf run.
if [[ $LBDATE != $DATE ]]; then echo complete > stat; exit; fi

export start_date=$DATE
if [ $DATE == $DATE_START ]; then
  export run_minutes=`diff_time $DATE_START $DATE_END`
else
  export run_minutes=$((LBC_INTERVAL*2))
fi

$SCRIPT_DIR/namelist_wps.sh > namelist.wps
#1. geogrid.exe --------------------------------------------------------------------
if [[ $DATE == $DATE_START ]]; then
  echo "    running geogrid.exe"
  ln -sf $WPS_DIR/geogrid/src/geogrid.exe .
  $SCRIPT_DIR/job_submit.sh $wps_ntasks 0 $HOSTPPN ./geogrid.exe >& geogrid.log
  watch_log geogrid.log Successful 10 $rundir
  mv geo_em.d??.nc $WORK_DIR/rc/$DATE/.
fi
ln -fs $WORK_DIR/rc/$DATE_START/geo_em.d??.nc .

#2. ungrib.exe --------------------------------------------------------------------
echo "    running ungrib.exe"
if [[ $DATE == $DATE_START ]]; then
  #Link first guess files (FNL, GFS or ECWMF-interim)
  $WPS_DIR/link_grib.csh $FG_DIR/*
  ln -sf $WPS_DIR/ungrib/Variable_Tables/Vtable.GFS Vtable
  ln -fs $WPS_DIR/ungrib/src/ungrib.exe .
  ./ungrib.exe >& ungrib.log
  watch_log ungrib.log Successful 10 $rundir
else
  rm -f FILE*
  ln -fs $WORK_DIR/run/$DATE_START/icbc/FILE* .
fi

#3. metgrid.exe --------------------------------------------------------------------
echo "    running metgrid.exe"
ln -fs $WPS_DIR/metgrid/METGRID.TBL.ARW METGRID.TBL
ln -fs $WPS_DIR/metgrid/src/metgrid.exe .
$SCRIPT_DIR/job_submit.sh $wps_ntasks 0 $HOSTPPN ./metgrid.exe >& metgrid.log
watch_log metgrid.log Successful 10 $rundir

#4. real.exe ----------------------------------------------------------------------
echo "    running real.exe"
$SCRIPT_DIR/namelist_wrf.sh real > namelist.input
ln -fs $WRF_DIR/main/real.exe .
$SCRIPT_DIR/job_submit.sh $wps_ntasks 0 $HOSTPPN ./real.exe >& real.log
watch_log rsl.error.0000 SUCCESS 10 $rundir

cp wrfinput_d?? $WORK_DIR/rc/$DATE/.
cp wrfbdy_d01 $WORK_DIR/rc/$DATE/.
if [[ $DATE == $DATE_START ]]; then
  cp wrfinput_d?? $WORK_DIR/fc/$DATE/.
  cp wrfbdy_d01 $WORK_DIR/fc/.
fi

if $CLEAN; then rm -f *log.???? GRIB* rsl.*; fi
echo complete > stat
