# Testing scripts
library(gaea); library(dplyr);library(tibble)

# Test Script

output_dir <- 'C:/WorkSpace/github/test_scripts/gaea/output_test'
gaea::weighted_climate(pr_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       tas_ncdf = NULL,
                       # tas_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       timestep = 'monthly',
                       climate_model = 'canesm5',
                       climate_scenario = 'gcam-ref',
                       time_periods = seq(2015, 2020, 1),
                       output_dir = output_dir,
                       name_append = NULL)

# for historical climate
gaea::weighted_climate(pr_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/CanESM5_r1i1p1f1_W5E5v2_historical_pr_global_monthly_1950_2014.nc',
                       tas_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/CanESM5_r1i1p1f1_W5E5v2_historical_tas_global_monthly_1950_2014.nc',
                       timestep = 'monthly',
                       climate_model = 'canesm5',
                       climate_scenario = 'historical',
                       time_periods = seq(1950, 2014, 1),
                       output_dir = 'C:/WorkSpace/github/test_scripts/gaea/output_test',
                       name_append = '_hist')

if(T){

  pr_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'
  tas_proj_ncdf = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'
  timestep = 'monthly'
  climate_model = 'canesm5'
  climate_scenario = 'gcam-ref'
  member = 'r1i1p1f1'
  bias_adj = 'W5E5v2'
  cfe = 'no-cfe'
  gcam_version = 'gcam7'
  use_default_coeff = TRUE
  climate_hist_dir = NULL
  climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaea/output/climate/canesm5'
  time_periods = seq(2015, 2020, 1)
  start_year = 2015
  end_year = 2100
  base_year = 2015
  smooth_window = 20
  co2_hist = NULL
  co2_proj = NULL
  diagnostics <- TRUE
  output_dir = 'C:/WorkSpace/github/test_scripts/gaea/output_test'

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
crop_cal <- gaea::crop_calendars(output_dir = output_dir)


# Step 5:
# test data_aggregation
climate_hist_dir <- file.path(output_dir, 'climate', 'country_climate_hist')
climate_impact_dir <- file.path(output_dir, 'climate')

crop <- gaea::data_aggregation(climate_hist_dir = climate_hist_dir,
                               climate_impact_dir = climate_impact_dir,
                               climate_model = climate_model,
                               climate_scenario = climate_scenario,
                               output_dir = output_dir)

# Step 6:
# test yield_regression
gaea::yield_regression(diagnostics = diagnostics,
                       output_dir = output_dir)


# test z_estimate
t <- gaea::z_estimate(use_default_coeff = FALSE,
                      climate_model = climate_model,
                      climate_scenario = climate_scenario,
                      crop_name = 'maize',
                      output_dir = output_dir)

# Step 7:
# test yield_projections
t_yield_projection <- gaea::yield_projections(use_default_coeff = FALSE,
                                              climate_model = climate_model,
                                              climate_scenario = climate_scenario,
                                              base_year = base_year,
                                              start_year = start_year,
                                              end_year = end_year,
                                              smooth_window = 20,
                                              diagnostics = T,
                                              output_dir = output_dir)


# test plot_map
gaea::plot_map(data = t_yield_projection,
               plot_years = 2090,
               output_dir = output_dir)

# test agprodchange_ref
gaea::agprodchange_ref(gcam_version = 'gcam7')
# gaea::agprodchange_ref(gcamdata_dir = 'C:/WorkSpace/GCAM-Models/gcam-v6.0/input/gcamdata')


# Step 10:
# test gcam_agprodchange
t <- gaea::gcam_agprodchange(data = t_yield_projection,
                             climate_model = climate_model,
                             climate_scenario = climate_scenario,
                             member = member,
                             bias_adj = bias_adj,
                             cfe = cfe,
                             gcam_version = 'gcam7',
                             diagnostics = T,
                             output_dir = output_dir)


# Step all:
# Test all the steps including climate data weighting
start.time <- Sys.time()
gaea::yield_impact(pr_hist_ncdf = NULL,
                   tas_hist_ncdf = NULL,
                   pr_proj_ncdf = NULL,
                   tas_proj_ncdf = NULL,
                   timestep = timestep,
                   historical_periods = time_periods,
                   climate_hist_dir = NULL,
                   climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaea/output/climate/canesm5',
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
                   output_dir = 'C:/WorkSpace/github/test_scripts/gaea/output_test')
end.time <- Sys.time()
time.taken <- round(end.time - start.time,2)
time.taken
