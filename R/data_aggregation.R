#' data_aggregation
#'
#' Process multiple models to analyze historical weather variables and crop yields
#'
#' @param climate_hist_dir Default = NULL. string for path to the processed historical climate data folder
#' @param climate_impact_dir Default = NULL. string for path to the processed future climate data folder using weighted_climate function
#' @param climate_model Default = NULL. string for climate model (e.g., 'CanESM5')
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @importFrom magrittr %>%
#' @importFrom data.table :=
#' @importFrom utils glob2rx
#' @export

data_aggregation <- function(climate_hist_dir = NULL,
                             climate_impact_dir = NULL,
                             climate_model = 'gcm',
                             climate_scenario = 'rcp',
                             output_dir = file.path(getwd(), 'output'))
{

  co2_historical <- co2_projection <- NULL

  message('Starting Step: data_aggregation')

  # read crop calendar output from crop_calendars function
  crop_cal <- gaea::input_data(
    folder_path = file.path(output_dir, 'data_processed'),
    input_file = 'crop_calendar.csv'
  )

  # merge fao yield and fao irrigation equip data
  yield <- gaea::merge_data(fao_yield, fao_irr_equip, 'iso', 'year')


  # ----------------------------------------------------------------------------
  # Process historic crop data
  # ----------------------------------------------------------------------------

  # check the historical climate data folder
  if(is.null(climate_hist_dir)){
    stop('Please provide folder path to the historical climate data.')
  } else {
    gaea::path_check(climate_hist_dir)
  }

  # get file list
  list_precip_rfc <- list.files(
    path = climate_hist_dir,
    pattern = utils::glob2rx('*precip*rfc*'),
    recursive = TRUE, full.names = TRUE)

  list_temp_rfc <- list.files(
    path = climate_hist_dir,
    pattern = glob2rx('*tmean*rfc*'),
    recursive = TRUE, full.names = TRUE)

  crop_historic <- data.table::data.table()

  for(crop_i in mapping_mirca_sage$crop_mirca) {

    crop_id <- crop_mirca$crop_id[grepl(crop_i, crop_mirca$crop_name)]

    # filter out the file for the crop
    file_precip <- list_precip_rfc[grepl(crop_id, list_precip_rfc)]
    file_temp <-list_temp_rfc[grepl(crop_id, list_temp_rfc)]

    # aggregate weather data for crop_i
    d_climate <- gaea::weather_agg(file_precip = file_precip,
                                   file_temp = file_temp,
                                   crop_name = crop_i)

    # estimate growing season for each crop and country (SAGE db)
    d_crop <- gaea::crop_month(climate_data = d_climate,
                               crop_name = crop_i,
                               crop_calendar = crop_cal)

    # merge data
    d_crop <- gaea::data_merge(data = d_crop,
                               crop_name = crop_i,
                               yield = yield,
                               co2_hist = co2_historical,
                               gdp_hist = gdp,
                               output_dir = output_dir)

    crop_historic <- dplyr::bind_rows(crop_historic, d_crop)
  }


  # ----------------------------------------------------------------------------
  # Process Climate Scenario
  # ----------------------------------------------------------------------------

  if(is.null(climate_impact_dir)){
    climate_impact_dir <- file.path(output_dir, 'climate')
  } else {
    gaea::path_check(climate_impact_dir)
  }

  # get file list
  list_precip_rfc <- list.files(
    path = climate_impact_dir,
    pattern = glob2rx(paste0(climate_model, '_', climate_scenario, '*precip*rfc*')),
    recursive = TRUE, full.names = TRUE)

  list_temp_rfc <- list.files(
    path = climate_impact_dir,
    pattern = glob2rx(paste0(climate_model, '_', climate_scenario, '*tmean*rfc*')),
    recursive = TRUE, full.names = TRUE)

  crop_projection <- data.table::data.table()

  for(crop_i in mapping_mirca_sage$crop_mirca) {

    crop_id <- crop_mirca$crop_id[grepl(crop_i, crop_mirca$crop_name)]

    # filter out the file for the crop
    file_precip <- list_precip_rfc[grepl(crop_id, list_precip_rfc)]
    file_temp <-list_temp_rfc[grepl(crop_id, list_temp_rfc)]

    # aggregate weather data for crop_i
    d_climate <- gaea::weather_agg(file_precip = file_precip,
                                   file_temp = file_temp,
                                   crop_name = crop_i)

    # estimate growing season for each crop and country (SAGE db)
    d_crop <- gaea::crop_month(climate_data = d_climate,
                               crop_name = crop_i,
                               crop_calendar = crop_cal)

    # merge data
    d_crop <- gaea::data_trans(data = d_crop,
                               climate_model = climate_model,
                               climate_scenario = climate_scenario,
                               crop_name = crop_i,
                               co2_proj = co2_projection,
                               output_dir = output_dir)

    crop_projection <- dplyr::bind_rows(crop_projection, d_crop)

  }

  d <- list(crop_historic = crop_historic,
            crop_projection = crop_projection)

  return(d)
}


