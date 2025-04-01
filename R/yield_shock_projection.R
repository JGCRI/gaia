#' yield_shock_projection
#'
#' Projects yield shocks for future climate scenarios using the fitted model and temperature, precipitation, and CO2 projections from the climate scenario.
#'
#' @param use_default_coeff Default = FALSE. Binary for using default regression coefficients. Set to TRUE will use the default coefficients instead of calculating coefficients from the historical climate data.
#' @param climate_model Default = NULL. String for climate model (e.g., 'CanESM5')
#' @param climate_scenario Default = NULL. String for climate scenario (e.g., 'ssp245')
#' @param base_year Default = 2015. Integer for the base year (for GCAM)
#' @param start_year Default = NULL. Integer for the  start year of the data
#' @param end_year Default = NULL. Integer for the end year of the data
#' @param gcam_timestep Default = 5. Integer for the time step of GCAM (Select either 1 or 5 years for GCAM use)
#' @param smooth_window Default = 20. Integer for smoothing window in years
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @returns A data frame of formatted smoothed annual crop yield shocks under climate impacts
#' @export

yield_shock_projection <- function(use_default_coeff = FALSE,
                                   climate_model = "gcm",
                                   climate_scenario = "rcp",
                                   base_year = 2015,
                                   start_year = NULL,
                                   end_year = NULL,
                                   gcam_timestep = 5,
                                   smooth_window = 20,
                                   diagnostics = TRUE,
                                   output_dir = file.path(getwd(), "output")) {
  message("Starting Step: yield_shock_projection")

  ## Create empty dataframe for binding other files
  d_bind <- data.frame(
    iso = character(),
    GCAM_region_name = character(),
    year = numeric(),
    yield_impact = numeric(),
    model = character(),
    rcp = character(),
    crop = character(),
    stringsAsFactors = FALSE
  )

  # get the selected crops from the regression outputs
  weather_yield_files <- list.files(file.path(output_dir, "data_processed"), 'weather_yield')
  crop_select <- gsub('.csv', '', gsub('weather_yield_', '', weather_yield_files))


  for (crop_i in crop_select) {
    print(paste(climate_model, climate_scenario, crop_i, sep = " "))

    # calculate yield impact for each crop and country
    d <- climate_impact(
      use_default_coeff = use_default_coeff,
      climate_model = climate_model,
      climate_scenario = climate_scenario,
      crop_name = crop_i,
      base_year = base_year,
      start_year = start_year,
      end_year = end_year,
      output_dir = output_dir
    )

    # plot projected yield impact
    if (diagnostics == TRUE) {
      plot_projection(
        data = d,
        climate_model = climate_model,
        climate_scenario = climate_scenario,
        crop_name = crop_i,
        base_year = base_year,
        output_dir = output_dir
      )
    }


    # smooth annual impacts using moving average and output certain time step
    d_smooth <- smooth_impacts(
      data = d,
      climate_model = climate_model,
      climate_scenario = climate_scenario,
      crop_name = crop_i,
      base_year = base_year,
      start_year = start_year,
      end_year = end_year,
      smooth_window = smooth_window,
      output_dir = output_dir
    )

    # bind crops
    d_bind <- rbind(d_bind, d_smooth)


    if (diagnostics == TRUE) {
      # plot smoothed projected yield impact
      plot_projection_smooth(
        data = d_smooth,
        climate_model = climate_model,
        climate_scenario = climate_scenario,
        crop_name = crop_i,
        base_year = base_year,
        output_dir = output_dir
      )

      # plot spatial map
      plot_map(
        data = d_smooth,
        plot_years = NULL,
        output_dir = output_dir
      )
    }
  }

  # format the smoothed yield to prepare for GCAM related process
  d_format <- format_projection(
    data = d_bind,
    base_year = base_year,
    gcam_timestep = gcam_timestep,
    output_dir = output_dir
  )

  return(d_format)
}
