#' weighted_climate
#'
#' Process standard NetCDF files from ISIMIP to country level climate
#' based on crop harvested area from MIRCA2000
#'
#' @param pr_files Default = NULL. list of paths for precipitation
#' @param tas_files Default = NULL. list of paths for temperature
#' @param timestep Default = 'monthly'. string for input climate data time step (e.g., 'monthly', 'daily')
#' @param climate_model Default = NULL. string for climate model (e.g., 'CanESM5')
#' @param climate_scenario Default = NULL. string for climate scenario (e.g., 'ssp245')
#' @param time_periods Default = NULL. vector for years to input in the output
#' @param output_dir Default = file.path(getwd(), 'output'). String for output directory
#' @export


weighted_climate <- function(pr_files = NULL,
                             tas_files = NULL,
                             timestep = 'monthly',
                             climate_model = 'gcm',
                             climate_scenario = 'rcp',
                             time_periods = NULL,
                             output_dir = file.path(getwd(), 'output')){


  # ----------------------------------------------------------------------------
  # Initialization
  # ----------------------------------------------------------------------------

  NULL -> ncvar_get -> fao_code -> country_id -> country_name -> lon -> lat ->
    country_name.final -> year -> month -> value

  # create output folder
  save_dir <- file.path(output_dir, 'climate', climate_model)
  if(!dir.exists(save_dir)){ dir.create(save_dir, recursive = TRUE) }

  crop_names <- names(mirca_harvest_area)
  crop_names <- crop_names[!(crop_names %in% c('lon', 'lat'))]

  # check if pr_files is provided
  if(!is.null(pr_files)){
    pr_exists <- TRUE
  } else {
    pr_exists <- FALSE
    message('No precipitation files provided. Skipping.')
  }

  # check if tas_files is provided
  if(!is.null(tas_files)){
    tas_exists <- TRUE
  } else {
    tas_exists <- FALSE
    message('No temperature files provided. Skipping.')
  }

  # check if timestep is valid
  if(!timestep %in% c('daily', 'monthly')) {
    stop('Please provide a valid value for the "timestep" argument: choose either "daily" or "monthly".')
  }

  # check if climate_model is default or provided by user
  if(climate_model == 'gcm'){
    message('Using the default `climate_model` value: "gcm". Please specify the `climate_model` argument as needed.')
  }

  # check if climate_scenario is default or provided by user
  if(climate_scenario == 'rcp'){
    message('Using the default `climate_scenario` value: "rcp". Please specify `climate_scenario` argument as needed.')
  }


  # ----------------------------------------------------------------------------
  # Mapping
  # ----------------------------------------------------------------------------
  # get gridded GCAM country with lat lon and reference country id and name
  grid_country <- mapping_fao_glu %>%
    dplyr::left_join(mapping_country %>%
                       dplyr::select(fao_code, country_id, country_name) %>%
                       dplyr::filter(!country_name %in% c('Ashmore and Cartier Islands',
                                                       'Coral Sea Islands')),
                     by = c('fao_code'),
                     suffix = c('', '.final')) %>%
    dplyr::select(lon, lat, country_id, country_name = country_name.final) %>%
    dplyr::distinct()


  # ----------------------------------------------------------------------------
  # Calculate weighted each cropland area over total cropland area bounded by country
  # ----------------------------------------------------------------------------
  # merge mirca crop area with country area and calculate sum of the crop area within country
  crop_area_total <- grid_country %>%
    dplyr::left_join(mirca_harvest_area, by = c('lon', 'lat')) %>%
    dplyr::group_by(country_id, country_name) %>%
    dplyr::mutate(dplyr::across(dplyr::starts_with(c('irc', 'rfc')), sum)) %>%
    dplyr::ungroup() %>%
    dplyr::distinct()

  # calculate weighted crop area of total crop area in country
  crop_area_weight <- grid_country %>%
    dplyr::left_join(mirca_harvest_area, by = c('lon', 'lat')) %>%
    dplyr::left_join(crop_area_total, by = c('lon', 'lat', 'country_id', 'country_name'),
                     suffix = c('', '.total')) %>%
    dplyr::distinct()


  # ----------------------------------------------------------------------------
  # load climate data
  # ----------------------------------------------------------------------------
  # process precipitation
  # precipitation (input in mm/s, output in mm/month)
  pr <- tibble::tibble()
  if(pr_exists){

    all_periods <- c()

    # loop through all pr files
    for(pr_file in pr_files) {

      # check if pr file is valid
      gaea::path_check(file = pr_file, file_type = 'nc')

      # precipitation
      message(paste0('Processing: ', pr_file))

      # get time periods of the nc file
      nc_time <- gaea::get_nc_time(pr_file)

      if (!is.null(time_periods)){
        # check if the data periods is within the selected periods
        nc_time_subset <- nc_time[nc_time %in% time_periods]
      } else {
        nc_time_subset <- nc_time
      }


      # convert ncdf to table
      pr_temp <- nc_to_tbl(nc_file = pr_file,
                           var = 'pr',
                           time_periods = nc_time_subset,
                           timestep = timestep)

      # merge all periods
      pr <- dplyr::bind_rows(pr, pr_temp)
      all_periods <- c(all_periods, nc_time_subset)

    } # end of for(pr_file in pr_ncdf)

    # convert precipitation from mm/s to mm/month
    pr <- pr %>%
      tidyr::pivot_wider(names_from = date, values_from = value) %>%
      dplyr::mutate(dplyr::across(-c(lon, lat), ~. * 60 * 60 * 24 * 30))

    # get final start and end year
    pr_period <- paste0(min(all_periods), '_', max(all_periods))

  } # end of if(is.null(pr_files))


  # process temperature
  # temperature (input in K, output in C)
  tas <- tibble::tibble()

  if(tas_exists) {

    all_periods <- c()

    # loop through all tas files
    for(tas_file in tas_files) {

      # check if pr file is valid
      gaea::path_check(file = tas_file, file_type = 'nc')

      # precipitation
      message(paste0('Processing: ', tas_file))

      # get time periods of the nc file
      nc_time <- gaea::get_nc_time(tas_file)

      # check if the data periods is within the selected periods
      nc_time_subset <- nc_time[nc_time %in% time_periods]

      # convert ncdf to table
      tas_temp <- nc_to_tbl(nc_file = tas_file,
                            var = 'tas',
                            time_periods = nc_time_subset,
                            timestep = timestep)

      # merge all periods
      tas <- dplyr::bind_rows(tas, tas_temp)
      all_periods <- c(all_periods, nc_time_subset)

    } # end of for(i in nrow(tas_files))

    # convert temperature from K to C
    tas <- tas %>%
      tidyr::pivot_wider(names_from = date, values_from = value) %>%
      dplyr::mutate(dplyr::across(-c(lon, lat), ~. - 273.15))

    # get final start and end year
    tas_period <- paste0(min(all_periods), '_', max(all_periods))

  }


  # ----------------------------------------------------------------------------
  # Calculate weighted precipitation (mm/month) and temperature (C)
  # ----------------------------------------------------------------------------

  # Calculating crop harvest area weighted precipitation and temperature
  for(crop in crop_names){

    message(paste0('Processing ', crop))

    # Precipitation -------------------
    if(pr_exists & nrow(pr) > 0) {

      # calculate weighted monthly precipitation using cropland weights within country
      pr_weighted <- weight_by_crop_area(tbl = pr, crop = crop, crop_area_weight = crop_area_weight)

      # write output
      utils::write.table(
        pr_weighted,
        file = file.path(
          save_dir,
          paste0(paste(climate_model, climate_scenario, 'month_precip_country', crop, pr_period, sep = '_'), '.txt')),
        quote = FALSE, row.names = FALSE)

    } else {
      warning('No precipitation output is generated.')
    }

    # temperature -------------------
    if(tas_exists & nrow(tas) > 0) {

      # calculate weighted monthly precipitation using cropland weights within country
      tas_weighted <- weight_by_crop_area(tbl = tas, crop = crop, crop_area_weight = crop_area_weight)

      # write output
      utils::write.table(
        tas_weighted,
        file = file.path(
          save_dir,
          paste0(paste(climate_model, climate_scenario, 'month_tmean_country', crop, tas_period, sep = '_'), '.txt')),
        quote = FALSE, row.names = FALSE)

    } else {
      warning('No temperature output is generated.')
    }


  } # end of for(crop in names(gaea::mirca_harvest_area))

  message('The function weighted_climate is complete.')

} # end of function weighted_climate


#' nc_to_tbl
#'
#' Process standard NetCDF files and convert to tibble
#'
#' @param nc_file Default = NULL. string for paths for precipitation
#' @param var Default = NULL. string for climate variable
#' @param timestep Default = 'monthly'. string for input climate data time step (e.g., 'monthly', 'daily')
#' @noRd
nc_to_tbl <- function(nc_file = NULL, var = NULL, time_periods = NULL, timestep = 'monthly'){

  lon <- lat <- year <- month <- value <- NULL

  tbl <- helios::read_ncdf(ncdf = nc_file,
                           var = var,
                           model = 'cmip',
                           time_periods = time_periods)

  # pivot longer
  tbl <- reshape2::melt(tbl, id.vars = c('lon', 'lat'), variable.name = 'date', value.name = 'value')

  # calculate monthly mean for temperature
  if(timestep == 'daily') {

    tbl <- tbl %>%
      dplyr::mutate(date = as.Date(date),
                    year = lubridate::year(date),
                    month = lubridate::month(date)) %>%
      dplyr::group_by(lon, lat, year, month) %>%
      dplyr::summarise(value = mean(value)) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(date = as.Date(paste(year, month, '01', sep = '-'), format = '%Y-%m-%d')) %>%
      dplyr::select(-year, -month)

  }

  return(tbl)

}


#' weight_by_crop_area
#'
#' weight the table by crop area
#'
#' @param tbl Default = NULL. tibble for gridded monthly climate data, with columns like [lon, lat, 2010-01-01, 2010-02-01, ...]
#' @param crop Default = NULL. string for crop name (e.g., 'irr_crop01')
#' @noRd
weight_by_crop_area <- function(tbl = NULL, crop = NULL, crop_area_weight = NULL){

  lon <- lat <- country_id <- country_name <- value <- NULL

  # capture and quote the unevaluated crop names expressions
  crop_area <- dplyr::enquo(crop)

  crop_area_total <- paste0(crop, '.total')
  crop_area_total <- dplyr::enquo(crop_area_total)

  # calculate weighted monthly precipitation using cropland weights within country
  tbl_weighted <- crop_area_weight %>%
    dplyr::select(lon, lat, country_id, country_name, !!crop_area, !!crop_area_total) %>%
    dplyr::left_join(tbl, by = c('lon', 'lat')) %>%
    dplyr::mutate(crop_area_weight = get(!!crop_area) / get(!!crop_area_total)) %>%
    dplyr::mutate(dplyr::across(-c(lon, lat, country_id, country_name), ~. * crop_area_weight)) %>%
    dplyr::group_by(country_id, country_name) %>%
    dplyr::summarise(dplyr::across(-c(lon, lat), sum, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(dplyr::across(-c(country_id, country_name, !!crop_area, !!crop_area_total),
                                ~ dplyr::na_if(., 0)))

  # transpose to required format
  tbl_transpose <- data.frame(country_id = seq(1, 265, 1)) %>%
    dplyr::left_join(tbl_weighted, by = 'country_id') %>%
    dplyr::select(-country_name, -!!crop_area, -!!crop_area_total, -crop_area_weight) %>%
    dplyr::mutate(dplyr::across(-c(country_id), ~ tidyr::replace_na(.x, as.numeric(-9999))),
                  dplyr::across(-c(country_id), round, digits = 2)) %>%
    tidyr::pivot_longer(cols = !country_id, names_to = 'date') %>%
    dplyr::mutate(date = as.Date(date),
                  year = lubridate::year(date),
                  month = lubridate::month(date)) %>%
    dplyr::select(-date) %>%
    tidyr::pivot_wider(names_from = country_id, values_from = value)

  return(tbl_transpose)
}
