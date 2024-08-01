#' yield_impact
#'
#' integrate all the workflow together
#'
#' @param pr_hist_ncdf Default = NULL. list of paths for historical precipitation NetCDF files from ISIMIP
#' @param pr_proj_ncdf Default = NULL. list of paths for projected precipitation NetCDF files from ISIMIP
#' @param tas_hist_ncdf Default = NULL. list of paths for historical temperature NetCDF files from ISIMIP
#' @param tas_proj_ncdf Default = NULL. list of paths for projected temperature NetCDF files from ISIMIP
#' @param timestep Default = 'monthly'. string for input climate data time step (e.g., 'monthly', 'daily')
#' @param historical_periods Default = NULL. vector for years to subset from the historical climate data. If NULL, use the default climate data period
#' @param climate_hist_dir Default = NULL. string for path to the historical precipitation and temperature files by irrigation type and crop type. The climate files must follow the same structure as the output of the weighted_climate function. Provide path to this argument when pr_hist_ncdf and tas_hist_ncdf are NULL.
#' @param climate_impact_dir Default = NULL. string for path to the projected precipitation and temperature files by irrigation type and crop type. The climate files must follow the same structure as the output of the weighted_climate function. Provide path to this argument when pr_proj_ncdf and tas_proj_ncdf are NULL.
#' @param climate_model Default = 'gcm'. string for climate model name (e.g., 'CanESM5')
#' @param climate_scenario Default = 'rcp'. string for climate scenario name (e.g., 'ssp245')
#' @param member Default = 'member'. string for the ensemble member name
#' @param bias_adj Default = 'ba'. string for the dataset used for climate data bias adjustment
#' @param cfe Default = 'no-cfe'. string for whether the yield impact formula implimented CO2 fertilization effect
#' @param gcam_version Default = 'gcam7'. string for the GCAM version. Only support gcam6 and gcam7
#' @param use_default_coeff Default = FALSE. binary for using default regression coefficients. Set to TRUE will use the default coefficients instead of calculating coefficients from the historical climate data.
#' @param base_year Default = NULL. integer for the base year (for GCAM)
#' @param start_year Default = NULL. integer for the  start year of the projected data
#' @param end_year Default = NULL. integer for the end year of the projected data
#' @param smooth_window Default = 20. integer for smoothing window in years
#' @param co2_hist Default = NULL. data table for historical CO2 concentration in columns [year, co2_conc]. If NULL, use built-in CO2 emission data
#' @param co2_proj Default = NULL. data table for projected CO2 concentration in columns [year, co2_conc]. If NULL, use built-in CO2 emission data
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#'
#' @export

yield_impact <- function(pr_hist_ncdf = NULL,
                         pr_proj_ncdf = NULL,
                         tas_hist_ncdf = NULL,
                         tas_proj_ncdf = NULL,
                         timestep = 'monthly',
                         historical_periods = NULL,
                         climate_hist_dir = NULL,
                         climate_impact_dir = NULL,
                         climate_model = 'gcm',
                         climate_scenario = 'rcp',
                         member = 'member',
                         bias_adj = 'ba',
                         cfe = 'no-cfe',
                         gcam_version = 'gcam7',
                         use_default_coeff = FALSE,
                         base_year = NULL,
                         start_year = NULL,
                         end_year = NULL,
                         smooth_window = 20,
                         co2_hist = NULL,
                         co2_proj = NULL,
                         diagnostics = TRUE,
                         output_dir = file.path(getwd(), 'output'))
{

  # Step 1b: Process standard NetCDF files from ISIMIP to country level historical climate
  if(any(!is.null(pr_hist_ncdf), !is.null(tas_hist_ncdf))){

    gaea::weighted_climate(pr_ncdf = pr_hist_ncdf,
                           tas_ncdf = tas_hist_ncdf,
                           timestep = timestep,
                           climate_model = climate_model,
                           climate_scenario = 'historical',
                           time_periods = historical_periods,
                           output_dir = output_dir,
                           name_append = '_hist')

  }

  # Step 1b: Process standard NetCDF files from ISIMIP to country level projected climate
  if(any(!is.null(pr_proj_ncdf), !is.null(tas_proj_ncdf))){

    gaea::weighted_climate(pr_ncdf = pr_proj_ncdf,
                           tas_ncdf = tas_proj_ncdf,
                           timestep = timestep,
                           climate_model = climate_model,
                           climate_scenario = climate_scenario,
                           time_periods = seq(start_year, end_year, 1),
                           output_dir = output_dir,
                           name_append = NULL)

  }


  # Step 2: Generate planting months for each country
  gaea::crop_calendars(output_dir = output_dir)

  # Step 3: Process multiple models to analyze historical weather variables and crop yields
  if(all(is.null(climate_hist_dir),
         !is.null(pr_hist_ncdf),
         !is.null(tas_hist_ncdf))){
    climate_hist_dir <- file.path(output_dir, 'climate', paste0(climate_model, '_hist'))
  }

  if(all(is.null(climate_impact_dir),
         !is.null(pr_proj_ncdf),
         !is.null(tas_proj_ncdf))){
    climate_impact_dir <- file.path(output_dir, 'climate', climate_model)
  }


  gaea::data_aggregation(climate_hist_dir = climate_hist_dir,
                         climate_impact_dir = climate_impact_dir,
                         climate_model = climate_model,
                         climate_scenario = climate_scenario,
                         output_dir = output_dir)

  # Step 4: Yield regressions and create figures
  if(!use_default_coeff){
    gaea::yield_regression(diagnostics = diagnostics,
                           output_dir = output_dir)
  }


  # Step 5: Project yields for future climate scenarios using regression analysis
  df_yield_projection <- gaea::yield_projections(use_default_coeff = use_default_coeff,
                                                 climate_model = climate_model,
                                                 climate_scenario = climate_scenario,
                                                 base_year = base_year,
                                                 start_year = start_year,
                                                 end_year = end_year,
                                                 smooth_window = smooth_window,
                                                 diagnostics = diagnostics,
                                                 output_dir = output_dir)

  # Step 6:
  df_yield_impact_gcam <- gaea::gcam_agprodchange(data = df_yield_projection,
                                                  climate_model = climate_model,
                                                  climate_scenario = climate_scenario,
                                                  member = member,
                                                  bias_adj = bias_adj,
                                                  cfe = cfe,
                                                  gcam_version = gcam_version,
                                                  diagnostics = diagnostics,
                                                  output_dir = output_dir)

  return(df_yield_impact_gcam)
}
