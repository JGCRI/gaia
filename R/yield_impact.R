#' yield_impact
#'
#' integrate all the workflow together
#'
#' @param pr_hist_ncdf Default = NULL. List of paths for historical precipitation NetCDF files from ISIMIP
#' @param pr_proj_ncdf Default = NULL. List of paths for projected precipitation NetCDF files from ISIMIP
#' @param tas_hist_ncdf Default = NULL. List of paths for historical temperature NetCDF files from ISIMIP
#' @param tas_proj_ncdf Default = NULL. List of paths for projected temperature NetCDF files from ISIMIP
#' @param timestep Default = 'monthly'. String for input climate data time step (e.g., 'monthly', 'daily')
#' @param historical_periods Default = NULL. Vector for years to subset from the historical climate data. If NULL, use the default climate data period
#' @param climate_hist_dir Default = NULL. String for path to the historical precipitation and temperature files by irrigation type and crop type. The climate files must follow the same structure as the output of the weighted_climate function. Provide path to this argument when pr_hist_ncdf and tas_hist_ncdf are NULL.
#' @param climate_impact_dir Default = NULL. String for path to the projected precipitation and temperature files by irrigation type and crop type. The climate files must follow the same structure as the output of the weighted_climate function. Provide path to this argument when pr_proj_ncdf and tas_proj_ncdf are NULL.
#' @param climate_model Default = 'gcm'. String for climate model name (e.g., 'CanESM5')
#' @param climate_scenario Default = 'rcp'. String for climate scenario name (e.g., 'ssp245')
#' @param member Default = 'member'. String for the ensemble member name
#' @param bias_adj Default = 'ba'. String for the dataset used for climate data bias adjustment
#' @param cfe Default = 'no-cfe'. String for whether the yield impact formula implemented CO2 fertilization effect
#' @param gcam_version Default = 'gcam7'. String for the GCAM version. Only support gcam6 and gcam7
#' @param gcam_timestep Default = 5. Integer for the time step of GCAM (Select either 1 or 5 years for GCAM use)
#' @param gcamdata_dir Default = NULL. String for directory to the gcamdata folder within the specific GCAM version. The gcamdata need to be run with drake to have the CSV outputs beforehand.
#' @param crop_calendar_file Default = NULL. String for the path of the crop calendar file. If crop_cal is provided, crop_select will be set to crops in crop calendar. User provided crop_calendar_file can include any crops MIRCA2000 crops: "wheat", "maize", "rice", "barley", "rye", "millet", "sorghum", "soybean", "sunflower", "root_tuber", "cassava", "sugarcane", "sugarbeet", "oil_palm", "rape_seed", "groundnuts", "pulses", "citrus", "date_palm", "grapes", "cotton", "cocoa", "coffee", "others_perennial", "fodder_grasses", "other_annual"
#' @param crop_select Default = NULL. Vector of strings for the selected crops from our database. If NULL, the default crops will be used in the crop calendar: c("cassava", "cotton", "maize", "rice", "root_tuber", "sorghum", "soybean", "sugarbeet", "sugarcane", "sunflower", "wheat"). The additional crops available for selection from our crop calendar database are: "barley", "groundnuts", "millet", "pulses", "rape_seed", "rye"
#' @param use_default_coeff Default = FALSE. Binary for using default regression coefficients. Set to TRUE will use the default coefficients instead of calculating coefficients from the historical climate data.
#' @param base_year Default = 2015. Integer for the base year (for GCAM)
#' @param start_year Default = NULL. Integer for the  start year of the projected data
#' @param end_year Default = NULL. Integer for the end year of the projected data
#' @param smooth_window Default = 20. Integer for smoothing window in years
#' @param co2_hist Default = NULL. Data table for historical CO2 concentration in columns [year, co2_conc]. If NULL, use built-in CO2 emission data
#' @param co2_proj Default = NULL. Data table for projected CO2 concentration in columns [year, co2_conc]. If NULL, use built-in CO2 emission data
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#'
#' @returns A data frame of formatted agricultural productivity change for GCAM
#' @export

yield_impact <- function(pr_hist_ncdf = NULL,
                         pr_proj_ncdf = NULL,
                         tas_hist_ncdf = NULL,
                         tas_proj_ncdf = NULL,
                         timestep = "monthly",
                         historical_periods = NULL,
                         climate_hist_dir = NULL,
                         climate_impact_dir = NULL,
                         climate_model = "gcm",
                         climate_scenario = "rcp",
                         member = "member",
                         bias_adj = "ba",
                         cfe = "no-cfe",
                         gcam_version = "gcam7",
                         gcam_timestep = 5,
                         gcamdata_dir = NULL,
                         crop_calendar_file = NULL,
                         crop_select = NULL,
                         use_default_coeff = FALSE,
                         base_year = 2015,
                         start_year = NULL,
                         end_year = NULL,
                         smooth_window = 20,
                         co2_hist = NULL,
                         co2_proj = NULL,
                         diagnostics = TRUE,
                         output_dir = file.path(getwd(), "output")) {
  # Step 1a: Process standard NetCDF files from ISIMIP to country level historical climate
  if (any(!is.null(pr_hist_ncdf), !is.null(tas_hist_ncdf), use_default_coeff == F)) {
    gaia::weighted_climate(
      pr_ncdf = pr_hist_ncdf,
      tas_ncdf = tas_hist_ncdf,
      timestep = timestep,
      climate_model = "climate",
      climate_scenario = "historical",
      time_periods = historical_periods,
      output_dir = output_dir,
      name_append = "_hist"
    )
  }

  # Step 1b: Process standard NetCDF files from ISIMIP to country level projected climate
  if (any(!is.null(pr_proj_ncdf), !is.null(tas_proj_ncdf))) {
    gaia::weighted_climate(
      pr_ncdf = pr_proj_ncdf,
      tas_ncdf = tas_proj_ncdf,
      timestep = timestep,
      climate_model = climate_model,
      climate_scenario = climate_scenario,
      time_periods = seq(start_year, end_year, 1),
      output_dir = output_dir,
      name_append = NULL
    )
  }


  # Step 2: Generate planting months for each country
  crop_cal <- gaia::crop_calendars(
    crop_calendar_file = crop_calendar_file,
    crop_select = crop_select,
    output_dir = output_dir)

  # update finalized selected crops
  crop_select <- names(crop_cal)[!names(crop_cal) %in% c('iso', 'plant', 'harvest')]

  # Step 3: Process multiple models to analyze historical weather variables and crop yields
  if (all(
    is.null(climate_hist_dir),
    !is.null(pr_hist_ncdf),
    !is.null(tas_hist_ncdf)
  )) {
    climate_hist_dir <- file.path(output_dir, "weighted_climate", "climate_hist")
  }

  if (all(
    is.null(climate_impact_dir),
    !is.null(pr_proj_ncdf),
    !is.null(tas_proj_ncdf)
  )) {
    climate_impact_dir <- file.path(output_dir, "weighted_climate", climate_model)
  }


  gaia::data_aggregation(
    climate_hist_dir = climate_hist_dir,
    climate_impact_dir = climate_impact_dir,
    climate_model = climate_model,
    climate_scenario = climate_scenario,
    co2_hist = co2_hist,
    co2_proj = co2_proj,
    output_dir = output_dir
  )

  # Step 4: Yield regressions and create figures
  if (!use_default_coeff) {
    gaia::yield_regression(
      diagnostics = diagnostics,
      output_dir = output_dir
    )
  }


  # Step 5: Project yields for future climate scenarios using regression analysis
  df_yield_projection <- gaia::yield_shock_projection(
    use_default_coeff = use_default_coeff,
    climate_model = climate_model,
    climate_scenario = climate_scenario,
    base_year = base_year,
    start_year = start_year,
    end_year = end_year,
    gcam_timestep = gcam_timestep,
    smooth_window = smooth_window,
    diagnostics = diagnostics,
    output_dir = output_dir
  )

  # Step 6:
  df_yield_impact_gcam <- gaia::gcam_agprodchange(
    data = df_yield_projection,
    climate_model = climate_model,
    climate_scenario = climate_scenario,
    member = member,
    bias_adj = bias_adj,
    cfe = cfe,
    gcam_version = gcam_version,
    gcam_timestep = gcam_timestep,
    gcamdata_dir = gcamdata_dir,
    diagnostics = diagnostics,
    output_dir = output_dir
  )

  return(df_yield_impact_gcam)
}
