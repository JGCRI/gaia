library(dplyr)

# -------------------------------
# Prepare example data
# -------------------------------

# output directory
output_dir_i <- file.path(getwd(), 'output')

# setup variables
climate_model_i <- 'canesm5'
climate_scenario_i <- 'gcam-ref'
member_i = 'r1i1p1f1'
bias_adj_i = 'w5e5'

cfe_i = 'no-cfe'
gcam_version_i = 'gcam7'

base_year_i = 2015
start_year_i = 2015
end_year_i = 2100
smooth_window_i = 20

diagnostics_i <- F
use_default_coeff_i <- F


# -------------------------------
# Functions
# -------------------------------

# Step 1: weighted_climate

# Step 2: crop_calendar
run_crop_calendars <- function(output_dir = output_dir_i){

  output <- gaea::crop_calendars(output_dir = output_dir)

  return(output)
}

# Step 3: data_aggregation
run_data_aggregation <- function(data_dir = NULL,
                                 climate_model = climate_model_i,
                                 climate_scenario = climate_scenario_i,
                                 output_dir = output_dir_i){

  climate_hist_dir_i <- file.path(data_dir, 'canesm5_hist')
  climate_impact_dir_i <- file.path(data_dir, 'canesm5')

  output <- gaea::data_aggregation(climate_hist_dir = climate_hist_dir_i,
                                   climate_impact_dir = climate_impact_dir_i,
                                   climate_model = climate_model,
                                   climate_scenario = climate_scenario,
                                   output_dir = output_dir)

  return(output)
}


# Step 4: yield_regression
run_yield_regression <- function(diagnostics = diagnostics_i,
                                 output_dir = output_dir_i){

  gaea::yield_regression(diagnostics = diagnostics,
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

  output <- gaea::yield_shock_projection(use_default_coeff = use_default_coeff,
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

  output <- gaea::gcam_agprodchange(data = data,
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
