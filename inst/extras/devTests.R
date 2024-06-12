# Testing scripts
library(gaea); library(dplyr);library(tibble)

# Test Script

output_dir <- 'C:/WorkSpace/github/test_scripts/gaea/output'
gaea::weighted_climate(pr_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       tas_file = NULL,
                       # tas_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc',
                       timestep = 'monthly',
                       climate_model = 'canesm5',
                       climate_scenario = 'gcam-ref',
                       time_periods = seq(2015, 2020, 1),
                       output_dir = output_dir)

pr_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/pr_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'
tas_files = 'C:/WorkSpace/GCIMS/GCIMS_Yield/climate_process/data/climate/tas_mon_basd_CanESM5_W5E5v2_GCAM_ref_2015-2100.nc'
timestep = 'monthly'
climate_model = 'canesm5'
climate_scenario = 'gcam-ref'
time_periods = seq(2015, 2020, 1)
start_year = 2015
end_year = 2100
base_year = 2015
diagnostics <- TRUE
output_dir = output_dir

crops <- tibble::tibble(
  crop_mirca = c('wheat', 'sorghum', 'maize', 'rice', 'soybean', 'sugarcane', 'sugarbeet', 'cotton', 'cassava', 'root_tuber', 'sunflower'),
  crop_sage = c('wheat', 'sorghum', 'maize', 'rice', 'soybeans', 'sugarcane', 'sugarbeets', 'cotton', 'cassava', 'potatoes', 'sunflower')
)


crop_cal <- gaea::crop_calendars(output_dir = output_dir)



# test data_aggregation
climate_hist_dir <- file.path(output_dir, 'climate', 'country_climate_txt')
climate_impact_dir <- file.path(output_dir, 'climate')

crop <- gaea::data_aggregation(climate_hist_dir = climate_hist_dir,
                               climate_impact_dir = climate_impact_dir,
                               climate_model = climate_model,
                               climate_scenario = climate_scenario,
                               output_dir = output_dir)


# test yield_regression
gaea::yield_regression(diagnostics = diagnostics,
                       output_dir = output_dir)


# test z_estimate
t <- gaea::z_estimate(climate_model,
                      climate_scenario,
                      crop_name = 'maize',
                      output_dir = output_dir)

# test yield_projections
t <- gaea::yield_projections(climate_model = climate_model,
                             climate_scenario = climate_scenario,
                             base_year = base_year,
                             start_year = start_year,
                             end_year = end_year,
                             smooth_window = 20,
                             diagnostics = F,
                             output_dir = output_dir)


# test plot_map
gaea::plot_map(data = t,
               plot_years = 2090,
               output_dir = output_dir)
