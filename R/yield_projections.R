#' yield_projections
#'
#' Project yields for future climate scenarios using regression analysis
#' Using average growing season temperature and precipitation, max and min months
#'
#' @param climate_model Default = NULL. string for climate model (e.g., 'CanESM5')
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param base_year Default = NULL. integer for the base year (for GCAM)
#' @param start_year Default = NULL. integer for the  start year of the data
#' @param end_year Default = NULL. integer for the end year of the data
#' @param smooth_window Default = 20. integer for smoothing window in years
#' @param diagnostics Default = TRUE. Logical for performing diagnostic plot
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @export

yield_projections <- function(climate_model = 'gcm',
                              climate_scenario = 'rcp',
                              base_year = NULL,
                              start_year = NULL,
                              end_year = NULL,
                              smooth_window = 20,
                              diagnostics = TRUE,
                              output_dir = file.path(getwd(), 'output')){


  message('Starting Step: yield_projections')

  ## Create empty dataframe for binding other files
  d_bind <- data.frame(iso = character(),
                       GCAM_region_name = character(),
                       year = numeric(),
                       yield_impact = numeric(),
                       model = character(),
                       rcp = character(),
                       crop = character(),
                       stringsAsFactors = FALSE )


  for( crop_i in mapping_mirca_sage$crop_mirca ) {
    print( paste( climate_model, climate_scenario, crop_i, sep = " " ) )

    # calculate yield impact for each crop and country
    d <- gaea::climate_impact(climate_model = climate_model,
                              climate_scenario = climate_scenario,
                              crop_name = crop_i,
                              base_year = base_year,
                              start_year = start_year,
                              end_year = end_year,
                              output_dir = output_dir)

    # plot projected yield impact
    if(diagnostics == TRUE){

      gaea::plot_projection(data = d,
                            climate_model = climate_model,
                            climate_scenario = climate_scenario,
                            crop_name = crop_i,
                            base_year = base_year,
                            output_dir = output_dir)
    }


    # smooth annual impacts using moving average and output certain time step
    d <- gaea::smooth_impacts(data = d,
                              climate_model = climate_model,
                              climate_scenario = climate_scenario,
                              crop_name = crop_i,
                              base_year = base_year,
                              smooth_window = smooth_window,
                              output_dir = output_dir)

    # bind crops
    d_bind <- rbind( d_bind, d )


    if(diagnostics == TRUE){

      # plot smoothed projected yield impact
      gaea::plot_projection_smooth(data = d,
                                   climate_model = climate_model,
                                   climate_scenario = climate_scenario,
                                   crop_name = crop_i,
                                   base_year = base_year,
                                   output_dir = output_dir)

      # plot spatial map
      gaea::plot_map(data = d,
                     plot_years = NULL,
                     output_dir = output_dir)

    }

  }

  # format the smoothed yield
  d_format <- gaea::format_projection(data = d_bind,
                                      base_year = base_year,
                                      output_dir = output_dir)

  return(d_format)

}
