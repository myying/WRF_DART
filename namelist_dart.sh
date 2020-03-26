#!/bin/bash
. $CONFIG_FILE
#domain_id=$1
#dx=`echo ${DX[$domain_id-1]}/1000 |bc -l`
domlist=`seq 1 $MAX_DOM`

cat << EOF
&filter_nml
   ens_size                 =  ${NUM_ENS},
   obs_sequence_in_name     = "obs_seq.out",
   obs_sequence_out_name    = "obs_seq.final",
   input_state_file_list    = $(for i in $domlist; do printf \"input_list_d0${i}.txt\",\ ; done)
   output_state_file_list   = $(for i in $domlist; do printf \"output_list_d0${i}.txt\",\ ; done)
   init_time_days           = -1,
   init_time_seconds        = -1,
   first_obs_days           = -1,
   first_obs_seconds        = -1,
   last_obs_days            = -1,
   last_obs_seconds         = -1,
   num_output_state_members = $NUM_ENS,
   num_output_obs_members   = $NUM_ENS,
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

   inf_flavor                  = 2,                    0,
   inf_initial_from_restart    = .true.,              .false.,
   inf_sd_initial_from_restart = .true.,              .false.,
   inf_initial                 = 1.0,                  1.12,
   inf_sd_initial              = 0.60,                 0.50,
   inf_damping                 = 0.9,                  1.00,
   inf_lower_bound             = 1.0,                  1.0,
   inf_upper_bound             = 10000.0,              10000.0,
   inf_sd_lower_bound          = 0.60,                 0.10,
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
   cutoff                          = 0.03,
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
   ens_size               = $NUM_ENS,
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

   num_domains = $MAX_DOM,
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

EOF

echo "&obs_kind_nml"
if $INCLUDE_LITTLE_R; then
  cat << EOF
   assimilate_these_obs_types = 'RADIOSONDE_U_WIND_COMPONENT',
                                'RADIOSONDE_V_WIND_COMPONENT',
                                'RADIOSONDE_TEMPERATURE',
                                'SAT_U_WIND_COMPONENT',
                                'SAT_V_WIND_COMPONENT',
                                'SYNOP_U_WIND_COMPONENT',
                                'SYNOP_V_WIND_COMPONENT',
                                'SYNOP_SURFACE_PRESSURE',
                                'SYNOP_TEMPERATURE',
                                'AIREP_U_WIND_COMPONENT',
                                'AIREP_V_WIND_COMPONENT',
                                'AIREP_TEMPERATURE',
                                'PILOT_U_WIND_COMPONENT',
                                'PILOT_V_WIND_COMPONENT',
                                'PROFILER_U_WIND_COMPONENT',
                                'PROFILER_V_WIND_COMPONENT',
                                'METAR_U_10_METER_WIND',
                                'METAR_V_10_METER_WIND',
                                'METAR_TEMPERATURE_2_METER',
                                'SYNOP_DEWPOINT',
                                'AIREP_DEWPOINT',
                                'METAR_DEWPOINT_2_METER',
                                'RADIOSONDE_DEWPOINT',
EOF
fi
if $INCLUDE_MPD; then
  echo "   assimilate_these_obs_types = 'MPD_ABSOLUTE_HUMIDITY',"
fi
echo "/"

cat << EOF

&obs_diag_nml
   obs_sequence_name = 'obs_seq.final',
   obs_sequence_list = '',
   first_bin_center =  2019, 06, 14, 0, 0, 0 ,
   last_bin_center  =  2019, 06, 14, 12, 0, 0 ,
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
   obs_sequence_list = '',
   lonlim1 = 0.
   lonlim2 = 360.
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

&fill_inflation_restart_nml
   write_prior_inf       = .TRUE.
   prior_inf_mean        = 1.0
   prior_inf_sd          = 0.6
   input_state_files     = $(for i in $domlist; do printf \"wrfinput_d0${i}\",\ ; done)
/
EOF

