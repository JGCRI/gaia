# Testing scripts
library(gaia); library(dplyr);library(tibble)

# Test Script

output_dir <- 'C:/WorkSpace/github/test_scripts/gaia/output_test'
gaia::weighted_climate(pr_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       tas_ncdf = NULL,
                       # tas_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       timestep = 'monthly',
                       climate_model = 'canesm5',
                       climate_scenario = 'gcam-ref',
                       time_periods = seq(2015, 2020, 1),
                       output_dir = output_dir,
                       name_append = NULL)

# for historical climate
gaia::weighted_climate(pr_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/CanESM5_r1i1p1f1_W5E5v2_historical_pr_global_monthly_1950_2014.nc',
                       tas_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/CanESM5_r1i1p1f1_W5E5v2_historical_tas_global_monthly_1950_2014.nc',
                       timestep = 'monthly',
                       climate_model = 'canesm5',
                       climate_scenario = 'historical',
                       time_periods = seq(1950, 2014, 1),
                       output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_test',
                       name_append = '_hist')

# test watch data
gaia::weighted_climate(pr_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/pr_watch_monthly_1960_2001.nc4',
                       tas_ncdf = NULL,
                       timestep = 'daily',
                       climate_model = 'watch',
                       climate_scenario = 'historical',
                       time_periods = seq(1960, 2001, 1),
                       output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_test/climate_watch',
                       name_append = '_hist')

if(T){

  # pr_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'
  # tas_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'

  # pr_hist_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/pr_monthly_canesm5_w5e5_rcp7_1950_2014.nc'
  # tas_hist_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/tas_monthly_canesm5_w5e5_rcp7_1950_2014.nc'

  pr_hist_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/pr_watch_monthly_1960_2001.nc4'
  tas_hist_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/tas_watch_monthly_1960_2001.nc4'

  pr_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/pr_monthly_canesm5_w5e5_rcp7_2015_2100.nc'
  tas_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/gaia_example_climate/tas_monthly_canesm5_w5e5_rcp7_2015_2100.nc'
  timestep = 'monthly'
  climate_model = 'canesm5'
  climate_scenario = 'gcam-ref'
  member = 'r1i1p1f1'
  bias_adj = 'W5E5v2'
  cfe = 'no-cfe'
  gcam_version = 'gcam7'
  use_default_coeff = TRUE
  climate_hist_dir = NULL
  climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaia/output/climate/canesm5'
  historical_periods = seq(2015, 2020, 1)
  start_year = 2015
  end_year = 2100
  base_year = 2015
  smooth_window = 20
  co2_hist = NULL
  co2_proj = NULL
  diagnostics <- TRUE
  output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test'

}


# crops <- tibble::tibble(
#   crop_mirca = c('wheat', 'sorghum', 'maize', 'rice', 'soybean', 'sugarcane', 'sugarbeet', 'cotton', 'cassava', 'root_tuber', 'sunflower'),
#   crop_sage = c('wheat', 'sorghum', 'maize', 'rice', 'soybeans', 'sugarcane', 'sugarbeets', 'cotton', 'cassava', 'potatoes', 'sunflower')
# )


# ------------------------------------------------------------------------------
# 1 of 10: 1_master_script.R (Loads libraries, defines variables, parameters, etc., sources files)
# 2 of 10: 2_yield_impact_functions.R: (Defines all specific functions used in these scripts)
# 3 of 10: 3_format_co2_concentration.R: create CO2 concentration pathways based on the GCAM scenario and version
# 4 of 10: 4_crop_calendars.R (Processes crop calendar data to get a single planting season for each country-crop)
# 5 of 10: 5_data_aggregation.R  (Combine data sources, process historical and future data for analysis)
# 6 of 10: 6_regression_figures.R (Run regressions, plot figures)
# 7 of 10: 7_yield_projections.R (Project future yield impacts using regression results, output csv files with annual and smoothed yield impacts, figures)
# 8 of 10: 8_impacts_maps.R (Generate maps of impacts by model, crop, year, and scenario)
# 9 of 10: 9_data_formatting.R (format data by cropmodel, climatemodel, crop, scenario, iso, irrtype, harvested.area, X2015, X2020, X2030, ..., X2090)
# 10 of 10: 10_gcam_agprodchange_xml.R (map yield shocks from country to region-basin level for latest GCAM and calculate AgProdChange)

# Step 4:
crop_cal <- gaia::crop_calendars(output_dir = output_dir)


# Step 5:
# test data_aggregation
# climate_hist_dir <- file.path(output_dir, 'weighted_climate', 'country_climate_hist')

climate_hist_dir <- file.path('C:/WorkSpace/github/test_scripts/gaia/output_joss_test/weighted_climate/country_climate_txt')
# climate_hist_dir <- file.path(output_dir, 'weighted_climate', 'canesm5_hist')
climate_impact_dir <- file.path(output_dir, 'weighted_climate', 'canesm5')

crop <- gaia::data_aggregation(climate_hist_dir = climate_hist_dir,
                               climate_impact_dir = climate_impact_dir,
                               climate_model = climate_model,
                               climate_scenario = climate_scenario,
                               output_dir = output_dir)

# Step 6:
# test yield_regression
gaia::yield_regression(diagnostics = diagnostics,
                       output_dir = output_dir)


# test z_estimate
t <- gaia::z_estimate(use_default_coeff = FALSE,
                      climate_model = climate_model,
                      climate_scenario = climate_scenario,
                      crop_name = 'maize',
                      output_dir = output_dir)

# Step 7:
# test yield_shock_projection
t_yield_projection <- gaia::yield_shock_projection(use_default_coeff = FALSE,
                                                   climate_model = climate_model,
                                                   climate_scenario = climate_scenario,
                                                   base_year = base_year,
                                                   start_year = start_year,
                                                   end_year = end_year,
                                                   gcam_timestep = 5,
                                                   smooth_window = 20,
                                                   diagnostics = F,
                                                   output_dir = output_dir)


# test plot_map
gaia::plot_map(data = t_yield_projection,
               plot_years = 2090,
               output_dir = output_dir)

# test agprodchange_ref
gaia::agprodchange_ref(gcam_version = 'gcam7',
                       climate_scenario = climate_scenario)
# gaia::agprodchange_ref(gcamdata_dir = 'C:/WorkSpace/GCAM-Models/gcam-v6.0/input/gcamdata')


# Step 10:
# test gcam_agprodchange
t <- gaia::gcam_agprodchange(data = t_yield_projection,
                             climate_model = climate_model,
                             climate_scenario = climate_scenario,
                             member = member,
                             bias_adj = bias_adj,
                             cfe = cfe,
                             gcam_version = 'gcam7',
                             gcam_timestep = 5,
                             diagnostics = F,
                             output_dir = output_dir)

## for 1-year timestep GCAM test
t <- gaia::gcam_agprodchange(data = t_yield_projection,
                             climate_model = climate_model,
                             climate_scenario = climate_scenario,
                             member = member,
                             bias_adj = bias_adj,
                             cfe = cfe,
                             gcam_version = 'gcam7',
                             gcam_timestep = 1,
                             gcamdata_dir = 'C:/WorkSpace/github/gaia/inst/extras',
                             diagnostics = F,
                             output_dir = output_dir)


# Step all:
# Test all the steps including climate data weighting
start.time <- Sys.time()
gaia::yield_impact(pr_hist_ncdf = NULL,
                   tas_hist_ncdf = NULL,
                   pr_proj_ncdf = NULL,
                   tas_proj_ncdf = NULL,
                   timestep = timestep,
                   historical_periods = historical_periods,
                   climate_hist_dir = NULL,
                   climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaia/output/climate/canesm5',
                   climate_model = climate_model,
                   climate_scenario = climate_scenario,
                   member = member,
                   bias_adj = bias_adj,
                   cfe = cfe,
                   gcam_version = gcam_version,
                   use_default_coeff = TRUE,
                   base_year = base_year,
                   start_year = start_year,
                   end_year = end_year,
                   smooth_window = smooth_window,
                   co2_hist = NULL,
                   co2_proj = NULL,
                   diagnostics = TRUE,
                   output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_test')
end.time <- Sys.time()
time.taken <- round(end.time - start.time,2)
time.taken

# if there is climate NetCDF available

start.time <- Sys.time()
gaia::yield_impact(pr_hist_ncdf = pr_hist_ncdf,
                   tas_hist_ncdf = tas_hist_ncdf,
                   pr_proj_ncdf = pr_proj_ncdf,
                   tas_proj_ncdf = tas_proj_ncdf,
                   timestep = timestep,
                   historical_periods = c(1960:2001),
                   climate_hist_dir = NULL,
                   climate_impact_dir = NULL,
                   climate_model = climate_model,
                   climate_scenario = climate_scenario,
                   member = member,
                   bias_adj = bias_adj,
                   cfe = cfe,
                   gcam_version = gcam_version,
                   use_default_coeff = F,
                   base_year = base_year,
                   start_year = start_year,
                   end_year = end_year,
                   smooth_window = smooth_window,
                   co2_hist = NULL,
                   co2_proj = NULL,
                   diagnostics = TRUE,
                   output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test')
end.time <- Sys.time()
time.taken <- round(end.time - start.time,2)
time.taken

# if climate data is already created
# Test t
gaia::yield_impact(pr_hist_ncdf = NULL,
                   tas_hist_ncdf = NULL,
                   pr_proj_ncdf = NULL,
                   tas_proj_ncdf = NULL,
                   timestep = timestep,
                   historical_periods = seq(1951, 2001),
                   climate_hist_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/weighted_climate/country_climate_txt',
                   climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/weighted_climate/canesm5',
                   climate_model = climate_model,
                   climate_scenario = climate_scenario,
                   member = member,
                   bias_adj = bias_adj,
                   cfe = cfe,
                   gcam_version = gcam_version,
                   use_default_coeff = F,
                   base_year = base_year,
                   start_year = start_year,
                   end_year = end_year,
                   smooth_window = smooth_window,
                   co2_hist = NULL,
                   co2_proj = NULL,
                   diagnostics = TRUE,
                   output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test')
