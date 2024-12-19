library(dplyr);library(tibble)

if(T){


  timestep = 'monthly'
  climate_model = 'canesm5'
  climate_scenario = 'gcam-ref'
  member = 'r1i1p1f1'
  bias_adj = 'W5E5v2'
  cfe = 'no-cfe'
  gcam_version = 'gcam7'
  gcam_timestep = 1
  gcamdata_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_annual_timestep/gcamdata'
  use_default_coeff = TRUE
  climate_hist_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/climate/country_climate_txt'
  climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/climate/canesm5'

  historical_periods = seq(1951, 2001, 1)
  start_year = 2015
  end_year = 2100
  base_year = 2015
  smooth_window = 1
  co2_hist = NULL
  co2_proj = NULL
  diagnostics <- TRUE
  output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_annual_timestep'

}


t_yield_projection <- gaia::yield_shock_projection(use_default_coeff = use_default_coeff,
                                                   climate_model = climate_model,
                                                   climate_scenario = climate_scenario,
                                                   base_year = base_year,
                                                   start_year = start_year,
                                                   end_year = end_year,
                                                   gcam_timestep = gcam_timestep,
                                                   smooth_window = smooth_window,
                                                   diagnostics = diagnostics,
                                                   output_dir = output_dir)

t <- gaia::gcam_agprodchange(data = t_yield_projection,
                             climate_model = climate_model,
                             climate_scenario = climate_scenario,
                             member = member,
                             bias_adj = bias_adj,
                             cfe = cfe,
                             gcam_version = gcam_version,
                             gcam_timestep = gcam_timestep,
                             gcamdata_dir = gcamdata_dir,
                             diagnostics = T,
                             output_dir = output_dir)


# to run the entire workflow
gaia::yield_impact(pr_hist_ncdf = NULL,
                   tas_hist_ncdf = NULL,
                   pr_proj_ncdf = NULL,
                   tas_proj_ncdf = NULL,
                   timestep = timestep,
                   historical_periods = historical_periods,
                   climate_hist_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/weighted_climate/country_climate_txt',
                   climate_impact_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_joss_test/weighted_climate/canesm5',
                   climate_model = climate_model,
                   climate_scenario = climate_scenario,
                   member = member,
                   bias_adj = bias_adj,
                   cfe = cfe,
                   gcam_version = gcam_version,
                   gcam_timestep = gcam_timestep,
                   gcamdata_dir = gcamdata_dir,
                   use_default_coeff = F,
                   base_year = base_year,
                   start_year = start_year,
                   end_year = end_year,
                   smooth_window = smooth_window,
                   co2_hist = NULL,
                   co2_proj = NULL,
                   diagnostics = TRUE,
                   output_dir = 'C:/WorkSpace/github/test_scripts/gaia/output_annual_timestep')
