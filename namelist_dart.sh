#!/bin/bash
. $CONFIG_FILE
domain_id=$1
dx=`echo ${DX[$domain_id-1]}/1000 |bc -l`

##switch certain obs type off if OBSINT (obs interval) is set less frequent than CYCLE_PERIOD
#offset=`echo "(${DATE:8:2}*60+${DATE:10:2})%${OBSINT_ATOVS:-$CYCLE_PERIOD}" |bc`
#if [ $offset != 0 ]; then USE_ATOVS=false; fi

##This if statement swiths the radar rv data off for parent domains
##  the radar data is only assimilated for d03
#if [[ $domain_id != 3 ]]; then USE_RADAR_RV=false; fi

#enkfvar      = 'U         ', 'V         ', 'W         ', 'T         ', 'QVAPOR    ', 'QCLOUD    ', 'QRAIN     ', 'QSNOW     ', 'QICE      ', 'QGRAUP    ', 'QHAIL     ', 'PH        ', 'MU        ', 'PSFC      ', 'P         ', 'PHB       ', 'PB        ', 'MUB       ',
#EOF

#if [ $minute_off == 0 ] || [ $minute_off == 180 ]; then
#  echo "updatevar    = 'U         ', 'V         ', 'W         ', 'T         ', 'QVAPOR    ', 'QCLOUD    ', 'QRAIN     ', 'QSNOW     ', 'QICE      ', 'QGRAUP    ', 'QHAIL     ', 'PH        ', 'MU        ', 'PSFC      ', 'P         ',"
#else
#  echo "updatevar    = 'U         ', 'V         ', 'W         ', 'T         ', 'QVAPOR    ', 'QCLOUD    ', 'QRAIN     ', 'QSNOW     ', 'QICE      ', 'QGRAUP    ', 'QHAIL     ', 'PH        ', 'MU        ', 'PSFC      ', 'P         ',"
#  #echo "updatevar    = 'QCLOUD    ', 'QRAIN     ', 'QSNOW     ', 'QICE      ', 'QGRAUP    ',"
#fi

#buffer=4 #buffer=0 if update_bc, buffer=spec_bdy_width-1 if bc is fixed as in perfect model case

#inflate      = $INFLATION_COEF,
#relax_opt    = $RELAX_OPT,
#relax_adaptive = .$RELAX_ADAPTIVE.,
#mixing       = $RELAXATION_COEF,
#random_order = .false.,
#print_detail = 0,
#/

cat << EOF
&filter_nml
   ens_size                 =  ${NUM_ENS},
   obs_sequence_in_name     = "obs_seq.out",
   obs_sequence_out_name    = "obs_seq.final",
   input_state_file_list    = "input_list_d01.txt", "input_list_d02.txt"
   output_state_file_list   = "output_list_d01.txt", "output_list_d02.txt"
   init_time_days           = -1,
   init_time_seconds        = -1,
   first_obs_days           = -1,
   first_obs_seconds        = -1,
   last_obs_days            = -1,
   last_obs_seconds         = -1,
   num_output_state_members = 20,
   num_output_obs_members   = 20,
   output_interval          = 1,
   num_groups               = 1,
   output_forward_op_errors = .false.,
   output_timestamps        = .false.,
   trace_execution          = .false.,

   stages_to_write          = 'preassim', 'postassim', 'output'
   output_members           = .true.
   output_mean              = .true.
   output_sd                = .true.
   write_all_stages_at_end  = .true.

   inf_flavor                  = 0,                      0,
   inf_initial_from_restart    = .false.,                 .false.,
   inf_sd_initial_from_restart = .false.,                 .false.,
   inf_initial                 = 1.0,                   1.12,
   inf_sd_initial              = 0.60,                   0.50,
   inf_damping                 = 0.9,                   1.00,
   inf_lower_bound             = 1.0,                    1.0,
   inf_upper_bound             = 10000.0,              10000.0,
   inf_sd_lower_bound          = 0.60,                   0.10
/

&quality_control_nml
   input_qc_threshold       = 4.0,
   outlier_threshold        = 3.0,
   enable_special_outlier_code = .false.
/

&ensemble_manager_nml
   layout = 2,
   tasks_per_node = 32
/

&smoother_nml
   num_lags              = 0
   start_from_restart    = .false.
   output_restart        = .false.
   restart_in_file_name  = 'smoother_ics'
   restart_out_file_name = 'smoother_restart'
/

&assim_tools_nml
   filter_kind                     = 1,
   cutoff                          = 0.10,
   sort_obs_inc                    = .false.,
   spread_restoration              = .true.,
   sampling_error_correction       = .true.,
   print_every_nth_obs             = 1000,
   adaptive_localization_threshold = 2000,
   output_localization_diagnostics = .false.,
   localization_diagnostics_file   = 'localization_diagnostics',
   convert_all_state_verticals_first = .true.
   convert_all_obs_verticals_first   = .true.
/

&cov_cutoff_nml
   select_localization = 1
/

&closest_member_tool_nml
   input_file_name        = 'filter_ic_new',
   output_file_name       = 'closest_restart',
   ens_size               = 50,
   single_restart_file_in = .false.,
   difference_method      = 4,
/

&assim_model_nml
   write_binary_restart_files = .true.
/

&location_nml
    horiz_dist_only                          = .true.
    vert_normalization_pressure              = 100000.0
    vert_normalization_height                = 10000.0
    vert_normalization_level                 = 20.0
    vert_normalization_scale_height          = 5.0
    approximate_distance                     = .false.
    nlon                                     = 71
    nlat                                     = 36
    output_box_info                          = .false.
    print_box_level                          = 0
    special_vert_normalization_obs_types     = 'null'
    special_vert_normalization_pressures     = -888888.0
    special_vert_normalization_heights       = -888888.0
    special_vert_normalization_levels        = -888888.0
    special_vert_normalization_scale_heights = -888888.0
/

&model_nml
   default_state_variables = .false.,
   wrf_state_variables     = 'U','QTY_U_WIND_COMPONENT','TYPE_U','UPDATE','999',
                             'V','QTY_V_WIND_COMPONENT','TYPE_V','UPDATE','999',
                             'W','QTY_VERTICAL_VELOCITY','TYPE_W','UPDATE','999',
                             'T','QTY_POTENTIAL_TEMPERATURE','TYPE_T','UPDATE','999',
                             'PH','QTY_GEOPOTENTIAL_HEIGHT','TYPE_GZ','UPDATE','999',
                             'MU','QTY_PRESSURE','TYPE_MU','UPDATE','999',
                             'QVAPOR','QTY_VAPOR_MIXING_RATIO','TYPE_QV','UPDATE','999',
                             'QCLOUD','QTY_CLOUD_LIQUID_WATER','TYPE_QC','UPDATE','999',
                             'QRAIN','QTY_RAINWATER_MIXING_RATIO','TYPE_QR','UPDATE','999',
                             'QSNOW','QTY_SNOW_MIXING_RATIO','TYPE_QS','UPDATE','999',
                             'QICE','QTY_CLOUD_ICE','TYPE_QI','UPDATE','999',
                             'QGRAUP','QTY_GRAUPEL_MIXING_RATIO','TYPE_QG','UPDATE','999',
                             'U10','QTY_U_WIND_COMPONENT','TYPE_U10','UPDATE','999',
                             'V10','QTY_V_WIND_COMPONENT','TYPE_V10','UPDATE','999',
                             'T2','QTY_TEMPERATURE','TYPE_T2','UPDATE','999',
                             'Q2','QTY_SPECIFIC_HUMIDITY','TYPE_Q2','UPDATE','999',
                             'PSFC','QTY_PRESSURE','TYPE_PS','UPDATE','999',

   wrf_state_bounds        = 'QVAPOR','0.0','NULL','CLAMP',
                             'QCLOUD','0.0','NULL','CLAMP',
                             'QRAIN','0.0','NULL','CLAMP',
                             'QSNOW','0.0','NULL','CLAMP',
                             'QICE','0.0','NULL','CLAMP',
                             'QGRAUP','0.0','NULL','CLAMP',

   num_domains = 1,
   calendar_type = 3,
   assimilation_period_seconds = 21600,
   vert_localization_coord = 4,
   center_search_half_length = 400000.0,
   circulation_pres_level = 80000.0,
   circulation_radius = 72000.0,
   center_spline_grid_scale = 4,
/

&utilities_nml
   TERMLEVEL = 2,
   nmlfilename = 'dart_log.nml',
   logfilename = 'dart_log.out',
   module_details = .false.,
   print_debug = .true.
/

&mpi_utilities_nml
/

&reg_factor_nml
   select_regression = 1,
   input_reg_file = "time_mean_reg",
   save_reg_diagnostics = .false.,
   reg_diagnostics_file = 'reg_diagnostics'
/

&obs_sequence_nml
   write_binary_obs_sequence = .false.
/

&state_vector_io_nml
   single_precision_output    = .true.,
/

&preprocess_nml
   overwrite_output        = .true.
   input_obs_kind_mod_file = '../../../obs_kind/DEFAULT_obs_kind_mod.F90',
   output_obs_kind_mod_file = '../../../obs_kind/obs_kind_mod.f90',
   input_obs_def_mod_file = '../../../obs_def/DEFAULT_obs_def_mod.F90',
   output_obs_def_mod_file = '../../../obs_def/obs_def_mod.f90',
   input_files              = '../../../obs_def/obs_def_reanalysis_bufr_mod.f90',
                              '../../../obs_def/obs_def_altimeter_mod.f90',
                              '../../../obs_def/obs_def_radar_mod.f90',
                              '../../../obs_def/obs_def_metar_mod.f90',
                              '../../../obs_def/obs_def_dew_point_mod.f90',
                              '../../../obs_def/obs_def_rel_humidity_mod.f90',
                              '../../../obs_def/obs_def_gps_mod.f90',
                              '../../../obs_def/obs_def_gts_mod.f90',
                              '../../../obs_def/obs_def_QuikSCAT_mod.f90',
                              '../../../obs_def/obs_def_vortex_mod.f90'
/

&obs_kind_nml
   assimilate_these_obs_types = 'RADIOSONDE_TEMPERATURE',
                                'RADIOSONDE_U_WIND_COMPONENT',
                                'RADIOSONDE_V_WIND_COMPONENT',
                                'RADIOSONDE_SPECIFIC_HUMIDITY',
                                'SAT_U_WIND_COMPONENT',
                                'SAT_V_WIND_COMPONENT',
                                'METAR_U_10_METER_WIND',
                                'METAR_V_10_METER_WIND',
                                'METAR_TEMPERATURE_2_METER',
                                'METAR_DEWPOINT_2_METER',
                                'MARINE_SFC_U_WIND_COMPONENT',
                                'MARINE_SFC_V_WIND_COMPONENT',
                                'MARINE_SFC_TEMPERATURE',
                                'MARINE_SFC_DEWPOINT',
    evaluate_these_obs_types = 'null',
/

&obs_diag_nml
   obs_sequence_name = 'obs_seq.out',
   obs_sequence_list = '',
   first_bin_center =  2015, 10, 21, 0, 0, 0 ,
   last_bin_center  =  2015, 10, 21, 12, 0, 0 ,
   bin_separation   =     0, 0, 0, 6, 0, 0 ,
   bin_width        =     0, 0, 0, 6, 0, 0 ,
   time_to_skip     =     0, 0, 0, 0, 0, 0 ,
   max_num_bins  = 1000,
   Nregions   = 1,
   lonlim1    =   0.0, 246.0, 255.4, 330.1,
   lonlim2    = 360.0, 265.0, 268.5, 334.6,
   latlim1    = 10.0,  30.0, 30.7,  21.3,
   latlim2    = 65.0,  46.0, 40.6,  23.4,
   reg_names  = 'Full Domain','central-plains','southern-plains'
   print_mismatched_locs = .false.,
   verbose = .true.
/


&obs_sequence_tool_nml
   filename_seq         = 'obs_seq.out',
   filename_seq_list    = 'obs_list',
   filename_out         = 'obs_seq.final',
   gregorian_cal        = .true.,
   first_obs_days       = -1,
   first_obs_seconds    = -1,
   last_obs_days        = -1,
   last_obs_seconds     = -1,
   edit_copies          = .true.,
   min_lat              = -90.0
   max_lat              = 90.0
   min_lon              = 0.0
   max_lon              = 360.0
   new_copy_index       = 1, 2, 3, 4, 5,
   obs_types            = ''
   keep_types           = .true.,
   synonymous_copy_list = '',
   synonymous_qc_list   = '',
/

&wrf_dart_to_fields_nml
   include_slp             = .true.,
   include_wind_components = .true.,
   include_height_on_pres  = .true.,
   include_temperature     = .true.,
   include_rel_humidity    = .true.,
   include_surface_fields  = .false.,
   include_sat_ir_temp     = .false.,
   pres_levels             = 70000.,
/


&schedule_nml
   calendar        = 'Gregorian',
   first_bin_start =  _FBS_YY_, _FBS_MM_, _FBS_DD_, _FBS_HH_, 0, 0,
   first_bin_end   =  _FBE_YY_, _FBE_MM_, _FBE_DD_, _FBE_HH_, 0, 0,
   last_bin_end    =  _LBE_YY_, _LBE_MM_, _LBE_DD_, _LBE_HH_, 0, 0,
   bin_interval_days    = 0,
   bin_interval_seconds = 21600,
   max_num_bins         = 1000,
   print_table          = .true.
/

&obs_seq_to_netcdf_nml
   obs_sequence_name = 'obs_seq.final'
   obs_sequence_list     = '',
   lonlim1 = 160.
   lonlim2 = 40.
   latlim1 = 10.
   latlim2 = 65.
/

&replace_wrf_fields_nml
   debug = .false.,
   fail_on_missing_field = .false.,
   fieldnames = "SNOWC",
                "ALBBCK",
                "TMN",
                "SEAICE",
                "SST",
                "SNOWH",
                "SNOW",
   fieldlist_file = '',
/

&obs_def_radar_mod_nml
   apply_ref_limit_to_obs      =   .false.,
   reflectivity_limit_obs      =     -10.0,
   lowest_reflectivity_obs     =     -10.0,
   apply_ref_limit_to_fwd_op   =   .false.,
   reflectivity_limit_fwd_op   =     -10.0,
   lowest_reflectivity_fwd_op  =     -10.0,
   max_radial_vel_obs          =   1000000,
   allow_wet_graupel           =   .false.,
   microphysics_type           =       3  ,
   allow_dbztowt_conv          =   .false.,
   dielectric_factor           =     0.224,
   n0_rain                     =     8.0e6,
   n0_graupel                  =     4.0e6,
   n0_snow                     =     3.0e6,
   rho_rain                    =    1000.0,
   rho_graupel                 =     400.0,
   rho_snow                    =     100.0,
/



&gts_to_dart_nml
   gts_file              = 'gts_obsout.dat'
   obs_seq_out_file_name = 'obs_seq.out'
   gts_qc_threshold      = -1
   Use_SynopObs          = .TRUE.
   Use_ShipsObs          = .TRUE.
   Use_MetarObs          = .TRUE.
   Use_BuoysObs          = .TRUE.
   Use_PilotObs          = .TRUE.
   Use_SoundObs          = .TRUE.
   Use_SatemObs          = .TRUE.
   Use_SatobObs          = .TRUE.
   Use_AirepObs          = .TRUE.
   Use_AmdarObs          = .TRUE.
   Use_GpspwObs          = .TRUE.
   Use_SsmiRetrievalObs  = .TRUE.
   Use_SsmiTbObs         = .TRUE.
   Use_Ssmt1Obs          = .TRUE.
   Use_Ssmt2Obs          = .TRUE.
   Use_ProflObs          = .TRUE.
   Use_QscatObs          = .TRUE.
   Use_BogusObs          = .TRUE.
   Use_gpsrefobs         = .TRUE.
   dropsonde_only        = .FALSE.
   num_thin_satob        = 50
   num_thin_qscat        = 100
/

EOF

#&osse
#use_ideal_obs    = .false.,
#gridobs_is   = 20,
#gridobs_ie   = `echo ${E_WE[$domain_id-1]}-20 |bc`,
#gridobs_js   = 20,
#gridobs_je   = `echo ${E_SN[$domain_id-1]}-20 |bc`,
#gridobs_ks   = 1,
#gridobs_ke   = `echo ${E_VERT[$domain_id-1]}-1 |bc`,
#gridobs_int_x= 40,
#gridobs_int_k= 1,
#use_simulated= .false.,
#/

#&hurricane_PI 
#use_hurricane_PI  = .false.,
#hroi_hurricane_PI = 60,
#vroi_hurricane_PI = 35,
#/

#&surface_obs
#use_surface      = .$USE_SURFOBS.,
#datathin_surface = ${THIN_SURFACE:-0},
#hroi_surface     = $(printf %.0f `echo $HROI_SFC/$dx |bc -l`),
#vroi_surface     = $VROI,
#/

#&sounding_obs
#use_sounding      = .$USE_SOUNDOBS.,
#datathin_sounding = ${THIN_SOUNDING:-0},
#datathin_sounding_vert = ${THIN_SOUNDING_VERT:-0},
#hroi_sounding     = $(printf %.0f `echo ${HROI_SOUNDING:-$HROI_UPPER}/$dx |bc -l`),
#vroi_sounding     = ${VROI_SOUNDING:-$VROI},
#/

#&profiler_obs
#use_profiler      = .$USE_PROFILEROBS.,
#datathin_profiler = ${THIN_PROFILER:-0},
#datathin_profiler_vert = ${THIN_PROFILER_VERT:-0},
#hroi_profiler     = $(printf %.0f `echo $HROI_PROFL/$dx |bc -l`),
#vroi_profiler     = $VROI_PROFL,
#/

#&aircft_obs
#use_aircft      = .$USE_AIREPOBS.,
#datathin_aircft = ${THIN_AIRCFT:-0},
#hroi_aircft     = $(printf %.0f `echo $HROI_UPPER/$dx |bc -l`),
#vroi_aircft     = $VROI,
#/

#&metar_obs
#use_metar      = .$USE_METAROBS.,
#datathin_metar = ${THIN_METAR:-0},
#hroi_metar     = $(printf %.0f `echo $HROI_SFC/$dx |bc -l`),
#vroi_metar     = $VROI,
#/

#&sfcshp_obs
#use_sfcshp      = .$USE_SHIPSOBS.,
#datathin_sfcshp = ${THIN_SFCSHP:-0},
#hroi_sfcshp     = $(printf %.0f `echo $HROI_SFC/$dx |bc -l`),
#vroi_sfcshp     = $VROI,
#/

#&spssmi_obs
#use_spssmi      = .$USE_SSMIOBS.,
#datathin_spssmi = ${THIN_SPSSMI:-0},
#hroi_spssmi     = $(printf %.0f `echo $HROI_UPPER/$dx |bc -l`),
#vroi_spssmi     = $VROI,
#/

#&atovs_obs
#use_atovs      = .$USE_ATOVS.,
#datathin_atovs = ${THIN_ATOVS:-0},
#datathin_atovs_vert = ${THIN_ATOVS_VERT:-0},
#hroi_atovs     = $(printf %.0f `echo ${HROI_ATOVS:-$HROI_UPPER}/$dx |bc -l`),
#vroi_atovs     = ${VROI_ATOVS:-$VROI},
#/

#&satwnd_obs
#use_satwnd      = .$USE_GEOAMVOBS.,
#datathin_satwnd = ${THIN_SATWND:-0},
#hroi_satwnd     = $(printf %.0f `echo ${HROI_SATWND:-$HROI_UPPER}/$dx |bc -l`),
#vroi_satwnd     = ${VROI_SATWND:-$VROI},
#/

#&seawind_obs
#use_seawind      = .$USE_SEAWIND.,
#datathin_seawind = ${THIN_SEAWIND:-0},
#hroi_seawind     = $(printf %.0f `echo ${HROI_SEAWIND:-$HROI_UPPER}/$dx |bc -l`),
#vroi_seawind     = ${VROI_SEAWIND:-$VROI},
#/

#&gpspw_obs
#use_gpspw      = .$USE_GPSPWOBS.,
#datathin_gpspw = ${THIN_GPSPW:-0},
#hroi_gpspw     = $(printf %.0f `echo $HROI_SFC/$dx |bc -l`),
#vroi_gpspw     = $VROI,
#/

#&radar_obs
#radar_number   = 1,
#use_radar_rf   = .$USE_RADAR_RF.,
#use_radar_rv   = .$USE_RADAR_RV.,
#datathin_radar = $THIN_RADAR,
#hroi_radar     = $(printf %.0f `echo $HROI_RADAR/$dx |bc -l`),
#vroi_radar     = $VROI_RADAR,
#/

#&airborne_radar
#use_airborne_rf   = .$USE_AIRBORNE_RF.,
#use_airborne_rv   = .$USE_AIRBORNE_RV.,
#datathin_airborne = $THIN_RADAR,
#hroi_airborne     = $(printf %.0f `echo $HROI_RADAR/$dx |bc -l`),
#vroi_airborne     = $VROI_RADAR,
#/

#&radiance
#use_radiance      = .${USE_RADIANCE:-false}.,
#datathin_radiance = ${THIN_RADIANCE:-0},
#hroi_radiance     = $(printf %.0f `echo ${HROI_RADIANCE:-$HROI_UPPER}/$dx |bc -l`),
#vroi_radiance     = ${VROI_RADIANCE:-$VROI},
#/
