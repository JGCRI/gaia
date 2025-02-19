library(dplyr)
library(sf)

# -------------------------------
# Prepare example data
# -------------------------------

# output directory
output_dir_i <- file.path(getwd(), 'output')

# setup variables
climate_model_i <- 'canesm5'
climate_scenario_i <- 'ssp245'
member_i = 'r1i1p1f1'
bias_adj_i = 'w5e5'

cfe_i = 'no-cfe'
gcam_version_i = 'gcam7'

crop_select_i = c("barley", "groundnuts", "millet", "pulses", "rape_seed", "rye")

base_year_i = 2015
start_year_i = 2015
end_year_i = 2100
smooth_window_i = 20

diagnostics_i <- T
use_default_coeff_i <- F

# -------------------------------
# Test Data
# -------------------------------
set.seed(7)

# CO2
co2_hist_i <- data.table::data.table(
  year = 1959:2015,
  co2_conc = seq(300, 400, length.out = length(1959:2015)) + rnorm(length(1959:2015), mean = 0, sd = 5)
)

co2_proj_i <- data.table::data.table(
  year = 2015:2100,
  co2_conc = 400 + (2015:2100-2000)^1.3 + rnorm(length(2015:2100), mean = 0, sd = 5)
)

# -------------------------------
# Functions
# -------------------------------

# Step 1: weighted_climate
run_weighted_climate <- function(pr_ncdf = NULL,
                                 tas_ncdf = NULL,
                                 timestep = "monthly",
                                 climate_model = "gcm",
                                 climate_scenario = "rcp",
                                 time_periods = NULL,
                                 crop_names = NULL,
                                 output_dir = file.path(getwd(), "output", "weighted_climate_test"),
                                 name_append = NULL){

  gaia::weighted_climate(pr_ncdf = pr_ncdf,
                         tas_ncdf = tas_ncdf,
                         timestep = timestep,
                         climate_model = climate_model,
                         climate_scenario = climate_scenario,
                         time_periods = time_periods,
                         crop_names = crop_names,
                         output_dir = output_dir,
                         name_append = name_append)

}

# Step 2: crop_calendar
run_crop_calendars <- function(crop_calendar_file = NULL,
                               crop_select = crop_select_i,
                               output_dir = output_dir_i){

  output <- gaia::crop_calendars(crop_calendar_file = crop_calendar_file,
                                 crop_select = crop_select,
                                 output_dir = output_dir)

  return(output)
}

# Step 3: data_aggregation
run_data_aggregation <- function(data_dir = NULL,
                                 climate_model = climate_model_i,
                                 climate_scenario = climate_scenario_i,
                                 co2_hist = co2_hist_i,
                                 co2_proj = co2_proj_i,
                                 output_dir = output_dir_i){

  climate_hist_dir_i <- file.path(data_dir, 'climate_hist')
  climate_impact_dir_i <- file.path(data_dir, 'canesm5')

  output <- gaia::data_aggregation(climate_hist_dir = climate_hist_dir_i,
                                   climate_impact_dir = climate_impact_dir_i,
                                   climate_model = climate_model,
                                   climate_scenario = climate_scenario,
                                   co2_hist = co2_hist,
                                   co2_proj = co2_proj,
                                   output_dir = output_dir)

  return(output)
}


# Step 4: yield_regression
run_yield_regression <- function(diagnostics = diagnostics_i,
                                 output_dir = output_dir_i){

  gaia::yield_regression(diagnostics = diagnostics,
                         output_dir = output_dir)

}


# Step 5: yield_shock_projection

run_yield_shock_projection <- function(use_default_coeff = use_default_coeff_i,
                                       climate_model = climate_model_i,
                                       climate_scenario = climate_scenario_i,
                                       base_year = base_year_i,
                                       start_year = start_year_i,
                                       end_year = end_year_i,
                                       smooth_window = smooth_window_i,
                                       diagnostics = diagnostics_i,
                                       output_dir = output_dir_i
){

  output <- gaia::yield_shock_projection(use_default_coeff = use_default_coeff,
                                         climate_model = climate_model,
                                         climate_scenario = climate_scenario,
                                         base_year = base_year,
                                         start_year = start_year,
                                         end_year = end_year,
                                         smooth_window = smooth_window,
                                         diagnostics = diagnostics,
                                         output_dir = output_dir)

  return(output)

}

# Step 6: gcam_agprodchange

run_gcam_agprodchange <- function(data = NULL,
                                  climate_model = climate_model_i,
                                  climate_scenario = climate_scenario_i,
                                  member = member_i,
                                  bias_adj = bias_adj_i,
                                  cfe = cfe_i,
                                  gcam_version = gcam_version_i,
                                  diagnostics = diagnostics_i,
                                  output_dir = output_dir_i){

  output <- gaia::gcam_agprodchange(data = data,
                                    climate_model = climate_model,
                                    climate_scenario = climate_scenario,
                                    member = member,
                                    bias_adj = bias_adj,
                                    cfe = cfe,
                                    gcam_version = gcam_version,
                                    diagnostics = diagnostics,
                                    output_dir = output_dir)

  return(output)
}
